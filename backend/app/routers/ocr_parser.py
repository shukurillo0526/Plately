"""
Plately — Receipt Scanner Router
===================================
Receives a receipt image and extracts structured ingredient data.

Single-stage pipeline (RTX 5070 Ti upgrade):
  gemma3:12b — multimodal model reads the receipt AND produces JSON in one pass.
  No more fragile moondream→qwen2.5 two-stage pipeline.

Fallback chain:
  1. Local single-stage pipeline (gemma3:12b vision → JSON)
  2. Cloud Gemini Vision
  3. Mock data
"""

import json
import logging
from fastapi import APIRouter, UploadFile, File, HTTPException, Request

from app.core.auth import CurrentUser
from app.core.security import validate_image_upload
from app.services.ocr_service import process_gemini_receipt_json
from app.services.ai_service import get_ai_service as get_ollama_service
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

logger = logging.getLogger("plately.ocr")

router = APIRouter()


LANG_MAP = {
    "uz": "Uzbek",
    "ko": "Korean",
    "ru": "Russian",
    "en": "English",
}

@router.post("/api/v1/receipt/scan")
@limiter.limit("10/minute")
async def scan_receipt(
    request: Request,
    current: CurrentUser,
    file: UploadFile = File(...),
    lang: str = "en",
):
    """
    Receives a receipt image and returns structured ingredient data.
    Single-stage pipeline: gemma3:12b reads receipt + structures JSON in one pass.
    """
    image_bytes = await validate_image_upload(file)
    language_name = LANG_MAP.get(lang.lower(), "English")
    
    # Construct prompts dynamically with target language
    parse_prompt = f"""You are looking at a grocery receipt image. Extract all food items from it.

For each food item return:
- item_name: English name of the product (translate if needed)
- item_name_translated: translate the item name to {language_name} (e.g. if the item is 'Bread', return 'Non' for Uzbek, 'Хлеб' for Russian, '빵' for Korean).
- quantity: numeric amount purchased
- unit: one of pcs, g, kg, ml, L, pack, bunch
- category: one of Produce, Vegetable, Fruit, Meat, Poultry, Seafood, Dairy, Milk, Cheese, Yogurt, Eggs, Bakery, Bread, Pantry, Canned, Frozen, Beverage, Juice, Snack, Condiment, Spices, Oil, Sauce, Grain
- price: total price for that line item

Also extract the store name and purchase date (YYYY-MM-DD format).
Skip non-food items (bags, discounts, tax, totals, card info).

CRITICAL ANTI-HALLUCINATION RULE: If the photo is blurry, unreadable, not a receipt, or does not clearly show food items, you MUST NOT hallucinate or repeat past store names. Return exactly:
{{"store": "No items detected", "date": null, "items": []}}

Return ONLY valid JSON:
{{"store": "Store Name", "date": "YYYY-MM-DD", "items": [{{"item_name": "Bread", "item_name_translated": "Non", "quantity": 1, "unit": "pcs", "category": "Bakery", "price": 2800}}]}}"""

    fallback_prompt = f"""Extract all food items from this grocery receipt image.
Return store name, date (YYYY-MM-DD), and each food item with its English name, its translated name in {language_name} as 'item_name_translated', quantity, unit, category, and price.
Skip non-food items.

CRITICAL: If the image is blurry, unreadable, not a receipt, or does not contain identifiable food items, do NOT hallucinate. Return:
{{"store": "Unknown", "date": null, "items": []}}

Return ONLY valid JSON:
{{"store": "...", "date": "YYYY-MM-DD", "items": [{{"item_name": "...", "item_name_translated": "...", "quantity": 1, "unit": "pcs", "category": "...", "price": 0}}]}}"""

    cloud_prompt = f"""Extract all food items from this grocery receipt image.

For each food item return:
- item_name: English name (translate if needed)
- item_name_translated: translate the item name to {language_name} (e.g. if the item is 'Bread', return 'Non' for Uzbek, 'Хлеб' for Russian, '빵' for Korean).
- quantity: numeric amount
- unit: one of pcs, g, kg, ml, L, pack, bunch
- category: one of Produce, Vegetable, Fruit, Meat, Poultry, Seafood, Dairy, Milk, Cheese, Yogurt, Eggs, Bakery, Bread, Pantry, Canned, Frozen, Beverage, Juice, Snack, Condiment, Spices, Oil, Sauce, Grain
- price: total price for that line item

Also extract store name and purchase date (YYYY-MM-DD).
Skip non-food items (bags, discounts, tax, totals).

CRITICAL: If the image is blurry, unreadable, not a receipt, or does not contain identifiable food items, do NOT hallucinate. Return:
{{"store": "Unknown", "date": null, "items": []}}

Return STRICT JSON ONLY, no markdown, no code fences:
{{"store": "Store Name", "date": "YYYY-MM-DD", "items": [{{"item_name": "...", "item_name_translated": "...", "quantity": 1.0, "unit": "pcs", "category": "...", "price": 0}}]}}
"""

    source = "error"
    parsed_data = None

    # ── Attempt 1: Local single-stage pipeline (gemma3:12b) ──────
    try:
        ollama = get_ollama_service()
        if await ollama.is_available():
            # Primary attempt: detailed prompt
            logger.info("[OCR] Analyzing receipt with multimodal model (primary)...")
            try:
                result = await ollama.analyze_image_json(
                    image_bytes=image_bytes,
                    prompt=parse_prompt,
                )
                if "error" not in result and result.get("items"):
                    parsed_data = result
                    source = "ollama-single-stage"
                    logger.info(f"[OCR] Success: {len(result['items'])} items extracted")
                else:
                    logger.warning(f"[OCR] Primary attempt returned no items: {result}")
            except Exception as e:
                logger.warning(f"[OCR] Primary attempt failed: {e}")

            # Fallback attempt with simpler prompt
            if parsed_data is None:
                logger.info("[OCR] Retrying with fallback prompt...")
                try:
                    result = await ollama.analyze_image_json(
                        image_bytes=image_bytes,
                        prompt=fallback_prompt,
                    )
                    if "error" not in result and result.get("items"):
                        parsed_data = result
                        source = "ollama-single-stage"
                        logger.info(f"[OCR] Fallback success: {len(result['items'])} items extracted")
                except Exception as e:
                    logger.warning(f"[OCR] Fallback attempt failed: {e}")

    except Exception as e:
        logger.warning(f"[OCR] Local pipeline failed: {e}")

    # ── Attempt 2: Cloud Gemini ─────────────────────────────────
    if parsed_data is None:
        try:
            from app.core.config import get_settings
            import os
            # Try env var directly first, then settings
            api_key = os.environ.get("GEMINI_API_KEY") or get_settings().GEMINI_API_KEY
            if api_key:
                import google.generativeai as genai
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel('gemini-2.5-flash')
                logger.info("[OCR] Calling Gemini Vision API...")
                response = model.generate_content(
                    [
                        cloud_prompt,
                        {"mime_type": file.content_type, "data": image_bytes},
                    ],
                    generation_config=genai.GenerationConfig(
                        temperature=0.1,
                        max_output_tokens=2048,
                    ),
                )
                raw_text = response.text.strip()
                logger.info(f"[OCR] Gemini raw response (first 200 chars): {raw_text[:200]}")
                if raw_text.startswith("```"):
                    raw_text = raw_text.split("\n", 1)[1]
                    if raw_text.endswith("```"):
                        raw_text = raw_text[:-3]
                parsed_data = json.loads(raw_text)
                source = "gemini"
                logger.info(f"[OCR] Gemini success: {len(parsed_data.get('items', []))} items")
            else:
                logger.warning("[OCR] No GEMINI_API_KEY found in env or settings — skipping Gemini")
        except Exception as e:
            logger.warning(f"[OCR] Gemini failed: {type(e).__name__}: {e}")

    # ── Verify that we actually parsed something ────────────────
    if parsed_data is None or not parsed_data.get("items"):
        return {
            "status": "empty",
            "source": source,
            "message": "No readable food items detected on the receipt.",
            "data": {
                "store": "No items detected",
                "date": None,
                "item_count": 0,
                "items": [],
            },
        }

    # Process through heuristic expiry engine
    processed = process_gemini_receipt_json(json.dumps(parsed_data))

    return {
        "status": "success",
        "source": source,
        "data": processed,
    }

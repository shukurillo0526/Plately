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
from fastapi import APIRouter, UploadFile, File, HTTPException

from app.services.ocr_service import process_gemini_receipt_json
from app.services.ollama_service import get_ollama_service

logger = logging.getLogger("plately.ocr")

router = APIRouter()

# ── Single-stage prompt (gemma3:12b reads + structures) ───────

RECEIPT_PARSE_PROMPT = """This is a photo of a grocery store receipt. Read ALL the text on this receipt and extract the structured data.

RULES:
1. Extract store name (translate Korean to English if needed, e.g. "진안식자재마트" → "Jinan Food Materials Mart")
2. Extract purchase date in YYYY-MM-DD format (e.g. "26-02-22" → "2026-02-22")
3. For EACH food product listed on the receipt:
   - item_name: Generic English name. Translate Korean → English:
     * 갓밀크/우유 → "Milk"
     * 당근 → "Carrot"
     * 삼겹살 → "Pork Belly"
     * 계란 → "Eggs"
     * 닭가슴살/Chicken breast → "Chicken Breast"
     * 치즈 → "Cheese"
     * 빵 → "Bread"
   - quantity: number from the receipt (quantity column, or extract from name like "1L", "500g", "2입")
   - unit: one of pcs, g, kg, ml, L, pack, bunch
   - category: one of Produce, Vegetable, Fruit, Meat, Poultry, Seafood, Dairy, Milk, Cheese, Yogurt, Eggs, Bakery, Bread, Pantry, Canned, Frozen, Beverage, Juice, Snack, Condiment, Spices, Oil, Sauce
   - price: the total price for that item (the last number on the item line)
4. SKIP non-food items: bags, discounts, tax lines, card info, totals, barcodes
5. Include ALL food items — do not skip any

IMPORTANT: Extract EVERY food item. If you see 4 items, return 4 items.

Return ONLY valid JSON, no other text:
{"store": "Store Name", "date": "2026-02-22", "items": [{"item_name": "Milk", "quantity": 1, "unit": "L", "category": "Milk", "price": 1980}, {"item_name": "Carrot", "quantity": 2, "unit": "pcs", "category": "Vegetable", "price": 1300}]}"""

# Fallback: simpler prompt
RECEIPT_PARSE_FALLBACK = """Read this grocery receipt image. List the store name, date, and every food product with its name (in English), quantity, unit, category, and price.

Return ONLY valid JSON:
{"store": "...", "date": "YYYY-MM-DD", "items": [{"item_name": "...", "quantity": 1, "unit": "pcs", "category": "...", "price": 0}]}"""

# ── Cloud Gemini (single-stage fallback) ──────────────────────

CLOUD_RECEIPT_PROMPT = """
You are an expert Korean grocery receipt parser for the Plately smart kitchen app.

RECEIPT FORMAT (Korean marts like 진안식자재마트, 이마트, 홈플러스, etc.):
- Store name is on the first line, often prefixed with (주) or (사)
- Date line: "판매일:YY-MM-DD HH:MM" → convert to "20YY-MM-DD"
- Item table header: "NO. 상품명 단가 수량 금액"
- Each item has TWO lines:
  Line 1: NO. [Korean product name] [size info like 1L, 500g]
  Line 2: [barcode number] [unit_price] [qty] [total_price] [tax marker like #]
- Items marked with # are tax-exempt food (면세물품) — these are always food.
- Total line: "합 계:" followed by the total amount
- Skip non-food rows (bags, discounts, tax summaries, card info, barcodes)

TRANSLATION RULES for Korean food names:
- "갓밀크 저지방 1L" → item_name: "Low Fat Milk", quantity: 1, unit: "L", category: "Milk"
- "세척당근(송국산) 2입/1팩" → item_name: "Washed Carrot", quantity: 2, unit: "pcs", category: "Vegetable"
- "삼겹살 600g" → item_name: "Pork Belly", quantity: 600, unit: "g", category: "Meat"
- "계란 30구" → item_name: "Eggs", quantity: 30, unit: "pcs", category: "Eggs"
- Extract volume/weight from the product name (e.g., "1L", "500ml", "200g")

Return STRICT JSON ONLY with NO markdown formatting, NO code fences:
{
  "store": "Store Name in English",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "item_name": "Generic English Name",
      "quantity": 1.0,
      "unit": "pcs/L/g/kg/ml/pack/bunch",
      "category": "Dairy/Vegetable/Meat/Fruit/Pantry/...",
      "price": 1980
    }
  ]
}
"""

# Mock response
MOCK_RESPONSE = {
    "store": "Jinan Food Materials Mart",
    "date": "2026-02-22",
    "items": [
        {"item_name": "Low Fat Milk", "quantity": 1.0, "unit": "L", "category": "Milk", "price": 1980},
        {"item_name": "Washed Carrot", "quantity": 2.0, "unit": "pcs", "category": "Vegetable", "price": 1300},
    ]
}


@router.post("/api/v1/receipt/scan")
async def scan_receipt(file: UploadFile = File(...)):
    """
    Receives a receipt image and returns structured ingredient data.
    Single-stage pipeline: gemma3:12b reads receipt + structures JSON in one pass.
    """
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")

    image_bytes = await file.read()
    source = "mock"
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
                    prompt=RECEIPT_PARSE_PROMPT,
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
                        prompt=RECEIPT_PARSE_FALLBACK,
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
            logger.info(f"[OCR] Gemini key present: {bool(api_key)}, length: {len(api_key) if api_key else 0}")
            if api_key:
                import google.generativeai as genai
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel('gemini-1.5-flash')
                logger.info("[OCR] Calling Gemini Vision API...")
                response = model.generate_content(
                    [
                        CLOUD_RECEIPT_PROMPT,
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

    # ── Attempt 3: Mock fallback ────────────────────────────────
    if parsed_data is None:
        logger.info("[OCR] Using mock fallback data")
        parsed_data = MOCK_RESPONSE
        source = "mock"

    # Process through heuristic expiry engine
    processed = process_gemini_receipt_json(json.dumps(parsed_data))

    return {
        "status": "success",
        "source": source,
        "data": processed,
    }


@router.get("/api/v1/receipt/debug")
async def scan_debug():
    """Debug endpoint to check Gemini configuration on Railway."""
    import os
    from app.core.config import get_settings
    settings = get_settings()
    env_key = os.environ.get("GEMINI_API_KEY", "")
    settings_key = settings.GEMINI_API_KEY

    result = {
        "env_key_present": bool(env_key),
        "env_key_length": len(env_key),
        "settings_key_present": bool(settings_key),
        "settings_key_length": len(settings_key),
    }

    # Quick test if the key actually works
    effective_key = env_key or settings_key
    if effective_key:
        try:
            import google.generativeai as genai
            genai.configure(api_key=effective_key)
            model = genai.GenerativeModel('gemini-1.5-flash')
            response = model.generate_content("Say hello in one word.")
            result["gemini_test"] = "success"
            result["gemini_response"] = response.text.strip()[:100]
        except Exception as e:
            result["gemini_test"] = "failed"
            result["gemini_error"] = f"{type(e).__name__}: {str(e)[:200]}"
    else:
        result["gemini_test"] = "skipped_no_key"

    return result


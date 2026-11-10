"""
Plately — Photo Ingredient Detection Router
==============================================
Receives a photo of loose ingredients and identifies them.

Single-stage pipeline (RTX 5070 Ti upgrade):
  gemma3:12b — multimodal model produces structured JSON directly from the image
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
from app.services.ai_service import get_ai_service as get_ollama_service
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

logger = logging.getLogger("plately.vision")

router = APIRouter()

# ── Single-stage vision prompt (gemma3:12b multimodal) ────────

VISION_DETECT_PROMPT = """Look at this image very carefully and identify EVERY food item you can see.

For each item, determine:
- item_name: short English name (e.g., "Banana", "Eggs", "Chicken Breast")
- quantity: exact count or weight visible (e.g., if 3 bananas → 3, if a dozen eggs → 12, if a carton of 12 eggs → 12)
- unit: one of: pcs, g, kg, oz, lb, ml, L, pack, bunch, dozen
- category: one of: Produce, Vegetable, Fruit, Meat, Poultry, Seafood, Dairy, Milk, Cheese, Yogurt, Eggs, Bakery, Bread, Pantry, Canned, Dried, Spices, Oil, Sauce, Condiment, Frozen, Beverage, Juice, Snack
- freshness: fresh, good, aging, or expired (default "fresh")
- confidence: 0.7 to 1.0

Count precisely. Do NOT make up items that are not in the image.

Return ONLY valid JSON with no other text:
{"items": [{"item_name": "Banana", "quantity": 3, "unit": "pcs", "category": "Fruit", "freshness": "fresh", "confidence": 0.95}]}"""

# Fallback: simpler prompt if primary gives weak results
VISION_DETECT_FALLBACK = """What food items are in this image? For each, give the name, quantity, unit (pcs/g/kg/pack), category, and freshness.

Return ONLY valid JSON:
{"items": [{"item_name": "...", "quantity": 1, "unit": "pcs", "category": "...", "freshness": "fresh", "confidence": 0.85}]}"""


# ── Cloud Gemini (single-stage fallback) ──────────────────────

CLOUD_VISION_PROMPT = """
You are an expert food ingredient identifier for the Plately smart kitchen app.

Look at this photo and identify every visible food ingredient. Count carefully.
For each item provide:
- item_name: A short, generic English name
- quantity: Exact count or weight you can see (count each individual piece)
- unit: One of: pcs, g, kg, oz, lb, ml, L, pack, bunch, dozen
- category: One of: Produce, Vegetable, Fruit, Meat, Poultry, Seafood,
  Dairy, Milk, Cheese, Yogurt, Eggs, Bakery, Bread, Pantry, Canned,
  Dried, Spices, Oil, Sauce, Condiment, Frozen, Beverage, Juice, Snack
- freshness: One of: fresh, good, aging, expired
- confidence: A float 0.0-1.0

Return STRICT JSON ONLY with NO markdown:
{"items": [{"item_name": "Eggs", "quantity": 12, "unit": "pcs", "category": "Eggs", "freshness": "fresh", "confidence": 0.95}]}
"""

MOCK_RESPONSE = {
    "items": [
        {"item_name": "Banana", "quantity": 3, "unit": "pcs", "category": "Fruit", "freshness": "good", "confidence": 0.92},
        {"item_name": "Red Bell Pepper", "quantity": 2, "unit": "pcs", "category": "Vegetable", "freshness": "fresh", "confidence": 0.88},
    ]
}


@router.post("/api/v1/vision/detect-ingredients")
@limiter.limit("10/minute")
async def detect_ingredients(request: Request, current: CurrentUser, file: UploadFile = File(...)):
    """
    Receives a photo of loose food ingredients and identifies them.
    Single-stage pipeline: gemma3:12b (multimodal) → JSON directly.
    """
    image_bytes = await validate_image_upload(file)
    source = "mock"
    parsed_data = None

    # ── Attempt 1: Local single-stage pipeline (gemma3:12b) ──────
    try:
        ollama = get_ollama_service()
        if await ollama.is_available():
            # Primary attempt: detailed prompt
            logger.info("[Vision] Analyzing image with multimodal model (primary)...")
            try:
                result = await ollama.analyze_image_json(
                    image_bytes=image_bytes,
                    prompt=VISION_DETECT_PROMPT,
                )
                if "error" not in result and result.get("items"):
                    parsed_data = result
                    source = "ollama-single-stage"
                    logger.info(f"[Vision] Success: {len(result['items'])} items detected")
                else:
                    logger.warning(f"[Vision] Primary attempt returned no items: {result}")
            except Exception as e:
                logger.warning(f"[Vision] Primary attempt failed: {e}")

            # Fallback attempt with simpler prompt
            if parsed_data is None:
                logger.info("[Vision] Retrying with fallback prompt...")
                try:
                    result = await ollama.analyze_image_json(
                        image_bytes=image_bytes,
                        prompt=VISION_DETECT_FALLBACK,
                    )
                    if "error" not in result and result.get("items"):
                        parsed_data = result
                        source = "ollama-single-stage"
                        logger.info(f"[Vision] Fallback success: {len(result['items'])} items detected")
                except Exception as e:
                    logger.warning(f"[Vision] Fallback attempt failed: {e}")

    except Exception as e:
        logger.warning(f"[Vision] Local pipeline failed: {e}")

    # ── Attempt 2: Cloud Gemini ─────────────────────────────────
    if parsed_data is None:
        try:
            from app.services.cloud_ai_service import get_cloud_ai_service
            cloud = get_cloud_ai_service()
            if cloud.is_configured:
                logger.info(f"[Vision] Local failed, trying cloud fallback ({cloud.provider})...")
                
                raw_text = await cloud.generate_text(
                    prompt=CLOUD_VISION_PROMPT,
                    temperature=0.1,
                    max_tokens=2048,
                    image_bytes=image_bytes,
                    mime_type=file.content_type,
                    format="json"
                )
                
                if raw_text.startswith("```"):
                    raw_text = raw_text.split("\n", 1)[1]
                    if raw_text.endswith("```"):
                        raw_text = raw_text[:-3]
                parsed_data = json.loads(raw_text)
                source = "cloud_fallback"
        except Exception as e:
            logger.warning(f"[Vision] Cloud fallback failed: {e}")

    # ── Attempt 3: Safe empty fallback (no hallucination) ────────
    if parsed_data is None:
        parsed_data = {"items": []}
        source = "empty"

    items = parsed_data.get("items", [])
    status = "success" if len(items) > 0 else "empty"

    return {
        "status": status,
        "source": source,
        "message": "No identifiable food ingredients detected in photo." if len(items) == 0 else "Success",
        "item_count": len(items),
        "data": parsed_data,
    }

"""
Plately — Smart Expiry Prediction Service
=============================================
AI-enhanced expiry prediction that goes beyond static category lookups.

Uses three signals:
1. Category-based default shelf life (baseline)
2. Storage location factor (fridge vs pantry vs freezer)
3. AI freshness assessment from photo (optional, adjusts expiry dynamically)

The service is called when:
- An item is first added to inventory (initial prediction)
- A freshness photo is analyzed (dynamic adjustment)
"""

import logging
from datetime import date, timedelta
from typing import Optional
from app.services.ai_service import get_ai_service as get_ollama_service

logger = logging.getLogger("plately.expiry")

# Category-based default shelf life (days)
# These are baseline values for refrigerated storage
CATEGORY_SHELF_LIFE = {
    "vegetable": 7,
    "fruit": 5,
    "dairy": 10,
    "meat": 3,
    "seafood": 2,
    "grain": 180,
    "spice": 365,
    "condiment": 90,
    "beverage": 30,
    "frozen": 180,
    "bakery": 4,
    "egg": 21,
    "oil": 180,
    "canned": 730,
    "snack": 60,
    "other": 14,
}

# Storage location multipliers
# Freezer dramatically extends life; pantry shortens for perishables
STORAGE_MULTIPLIER = {
    "fridge": 1.0,
    "freezer": 6.0,      # 6x longer in freezer
    "pantry": 0.5,        # Half life for perishables at room temp
    "counter": 0.3,       # Even shorter at room temp
}

# Categories that are NOT affected by storage location
# (already shelf-stable regardless)
SHELF_STABLE = {"grain", "spice", "condiment", "canned", "oil", "snack"}


def predict_expiry(
    category: str,
    purchase_date: Optional[date] = None,
    storage_location: str = "fridge",
    packaging: str = "opened",
) -> dict:
    """
    Predict expiry date based on category, storage, and packaging.
    
    Returns:
        {
            "expiry_date": "2026-05-01",
            "shelf_life_days": 7,
            "confidence": "high",
            "factors": ["category: vegetable (7d)", "storage: fridge (1.0x)"]
        }
    """
    purchase = purchase_date or date.today()
    base_days = CATEGORY_SHELF_LIFE.get(category, 14)
    factors = [f"category: {category} ({base_days}d base)"]

    # Apply storage multiplier (only for perishables)
    if category not in SHELF_STABLE:
        multiplier = STORAGE_MULTIPLIER.get(storage_location, 1.0)
        adjusted_days = int(base_days * multiplier)
        factors.append(f"storage: {storage_location} ({multiplier}x)")
    else:
        adjusted_days = base_days
        factors.append(f"storage: shelf-stable (no adjustment)")

    # Packaging factor
    if packaging == "sealed":
        adjusted_days = int(adjusted_days * 1.5)
        factors.append("packaging: sealed (+50%)")
    elif packaging == "opened":
        factors.append("packaging: opened (baseline)")

    expiry = purchase + timedelta(days=adjusted_days)

    return {
        "expiry_date": expiry.isoformat(),
        "shelf_life_days": adjusted_days,
        "confidence": "high" if category in CATEGORY_SHELF_LIFE else "medium",
        "factors": factors,
    }


async def assess_freshness_from_photo(
    image_bytes: bytes,
    ingredient_name: str,
    category: str = "other",
) -> dict:
    """
    Use vision AI to assess an ingredient's freshness from a photo.
    Returns a freshness score (0.0-1.0) and adjusted expiry recommendation.
    
    Freshness scale:
      1.0 = Perfectly fresh (just purchased)
      0.7 = Good (normal appearance)
      0.4 = Starting to age (minor blemishes, slight wilting)
      0.2 = Should use immediately (significant degradation)
      0.0 = Not safe to consume
    """
    ollama = get_ollama_service()
    if not await ollama.is_available():
        return {"error": "AI unavailable", "freshness_score": 0.7}

    prompt = f"""Analyze this photo of "{ingredient_name}" (category: {category}).

Rate its freshness on a scale from 0.0 to 1.0:
- 1.0 = Perfectly fresh
- 0.7 = Good condition
- 0.4 = Starting to age
- 0.2 = Use immediately
- 0.0 = Not safe

Return JSON only:
{{
  "freshness_score": 0.7,
  "visual_cues": ["firm texture", "vibrant color"],
  "recommendation": "Use within 3 days",
  "days_remaining_estimate": 3,
  "safe_to_eat": true
}}"""

    try:
        result = await ollama.analyze_image_json(image_bytes, prompt)

        score = float(result.get("freshness_score", 0.7))
        safe = result.get("safe_to_eat", True)

        # Calculate adjusted shelf life based on freshness
        base_days = CATEGORY_SHELF_LIFE.get(category, 14)
        adjusted_days = max(0, int(base_days * score))

        result["adjusted_expiry"] = (date.today() + timedelta(days=adjusted_days)).isoformat()
        result["adjusted_shelf_life_days"] = adjusted_days

        return result

    except Exception as e:
        logger.error(f"[Freshness] Analysis failed: {e}")
        return {
            "freshness_score": 0.7,
            "error": str(e),
            "recommendation": "Could not assess — use standard shelf life",
        }

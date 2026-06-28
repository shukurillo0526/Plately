import json
from datetime import datetime, timedelta
from typing import Dict, Optional

# ──────────────────────────────────────────────────────────────────────
# Heuristic Expiry Engine v2
# ──────────────────────────────────────────────────────────────────────
# Assigns shelf-life estimates based on ingredient category AND
# optionally sub-type. This is the fallback used when a receipt or
# manual entry does not include an explicit expiration date.

# Detailed heuristic table: category -> default days
# Sub-categories can override when provided
EXPIRY_HEURISTICS = {
    # Fresh Produce
    'Produce':   7,
    'Vegetable': 10,
    'Fruit':     7,
    'Leafy Greens': 5,
    'Herbs':     5,
    'Berries':   4,

    # Proteins
    'Meat':      3,
    'Poultry':   2,
    'Seafood':   2,
    'Eggs':      21,

    # Dairy
    'Dairy':     10,
    'Milk':      7,
    'Cheese':    21,
    'Yogurt':    14,
    'Butter':    30,

    # Bakery
    'Bakery':    5,
    'Bread':     5,

    # Pantry (long shelf life)
    'Pantry':    180,
    'Canned':    365,
    'Dried':     180,
    'Spices':    365,
    'Oil':       180,
    'Sauce':     90,
    'Condiment': 90,

    # Frozen
    'Frozen':    90,

    # Beverages
    'Beverage':  30,
    'Juice':     7,

    # Snacks
    'Snack':     60,
}

def calculate_expiry(
    category: str,
    purchase_date_str: Optional[str] = None,
    sub_category: Optional[str] = None,
) -> str:
    """
    Heuristic Engine for Expiry Dates.
    Assigns an expiration date based on the category (and optional
    sub-category) of the ingredient.

    Priority order:
      1. sub_category lookup
      2. category lookup
      3. fallback 7 days
    """
    if purchase_date_str:
        try:
            purchase_date = datetime.fromisoformat(purchase_date_str)
        except ValueError:
            purchase_date = datetime.now()
    else:
        purchase_date = datetime.now()

    # Check sub-category first, then category, then default
    days = (
        EXPIRY_HEURISTICS.get(sub_category, None)
        if sub_category
        else None
    )
    if days is None:
        days = EXPIRY_HEURISTICS.get(category, 7)

    expiry_date = purchase_date + timedelta(days=days)
    return expiry_date.isoformat()


def process_gemini_receipt_json(receipt_json_str: str) -> Dict:
    """
    Processes the raw JSON output from the Gemini Vision API.
    Injects the heuristic expiry dates for each parsed item.
    """
    try:
        data = json.loads(receipt_json_str)
    except json.JSONDecodeError:
        return {"error": "Invalid JSON from OCR engine"}

    store_name = data.get('store', 'Unknown Store')
    purchase_date = data.get('date')  # Might be None
    raw_items = data.get('items', [])

    processed_items = []

    for item in raw_items:
        cat = item.get('category', 'Unknown')
        sub_cat = item.get('sub_category')  # Optional sub-category from Gemini

        # If Gemini extracted an explicit expiry, keep it; otherwise use heuristic
        explicit_expiry = item.get('expiry_date')
        if explicit_expiry:
            expiry = explicit_expiry
        else:
            expiry = calculate_expiry(cat, purchase_date, sub_cat)

        processed_items.append({
            "raw_name": item.get('item_name', 'Unknown Item'),
            "canonical_name": item.get('item_name', 'Unknown Item'),
            "display_name_translated": item.get('item_name_translated'),
            "quantity": float(item.get('quantity', 1.0)),
            "unit": item.get('unit', 'pcs'),
            "category": cat,
            "sub_category": sub_cat,
            "price": item.get('price'),
            "expiry_date": expiry,
        })

    return {
        "store": store_name,
        "date": purchase_date,
        "item_count": len(processed_items),
        "items": processed_items,
    }

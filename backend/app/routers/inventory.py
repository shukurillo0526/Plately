"""
Plately — Inventory API Router
=================================
Handles ingredient upsert and inventory item creation.
Uses the service role key to bypass RLS restrictions.
"""

import logging
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from typing import Optional

from app.core.auth import CurrentUser, require_user_id, verify_inventory_ownership
from app.core.security import raise_internal_error, sanitize_search_query, validate_image_upload
from app.db.supabase_client import get_supabase
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

logger = logging.getLogger("plately.inventory")

router = APIRouter()


class AddItemRequest(BaseModel):
    user_id: str
    ingredient_name: str
    category: str = "Pantry"
    quantity: float = 1.0
    unit: str = "pcs"
    location: str = "Fridge"
    expiry_date: Optional[str] = None  # ISO 8601, defaults to 7 days
    ingredient_id: Optional[str] = None  # If known, skip search


@router.post("/api/v1/inventory/add-item")
async def add_inventory_item(req: AddItemRequest, current: CurrentUser):
    """
    Upsert an ingredient and add it to inventory.
    If the same ingredient already exists in the same location,
    increments quantity instead of creating a duplicate.
    Uses the service role key, so RLS is bypassed.
    """
    require_user_id(current, req.user_id)
    db = get_supabase()

    try:
        # 1. If ingredient_id is provided, skip search
        if req.ingredient_id:
            existing_by_id = (
                db.table("ingredients")
                .select("*")
                .eq("id", req.ingredient_id)
                .limit(1)
                .execute()
            )
            if existing_by_id.data and len(existing_by_id.data) > 0:
                ingredient = existing_by_id.data[0]
                ingredient_id = ingredient["id"]
            else:
                raise HTTPException(status_code=404, detail=f"Ingredient {req.ingredient_id} not found")
        else:
            # 1b. Find or create ingredient (fetch full metadata)
            existing = (
                db.table("ingredients")
                .select("*")
                .ilike("display_name_en", req.ingredient_name)
                .limit(1)
                .execute()
            )

            if existing.data and len(existing.data) > 0:
                ingredient = existing.data[0]
                ingredient_id = ingredient["id"]
            else:
                # Try canonical_name match as well
                canonical = req.ingredient_name.strip().lower().replace(" ", "_")
                canonical_match = (
                    db.table("ingredients")
                    .select("*")
                    .eq("canonical_name", canonical)
                    .limit(1)
                    .execute()
                )
                if canonical_match.data and len(canonical_match.data) > 0:
                    ingredient = canonical_match.data[0]
                    ingredient_id = ingredient["id"]
                else:
                    # Create new ingredient — tagged as user-contributed
                    inserted = (
                        db.table("ingredients")
                        .insert({
                            "canonical_name": canonical,
                            "display_name_en": req.ingredient_name.strip(),
                            "category": req.category.lower(),
                            "sub_category": "general",
                            "default_unit": req.unit,
                            "source": "user_contributed",
                            "verified": False,
                            "created_by": req.user_id or current.id,
                        })
                        .execute()
                    )
                    ingredient = inserted.data[0]
                    ingredient_id = ingredient["id"]
                    logger.info(f"[Inventory] Auto-created ingredient: {req.ingredient_name} (user_contributed)")

        # 2. Auto-compute expiry from ingredient shelf-life data
        location = req.location.lower()
        shelf_days = ingredient.get("sealed_shelf_life_days")
        if req.expiry_date:
            expiry = req.expiry_date
        elif shelf_days:
            expiry = (datetime.now() + timedelta(days=shelf_days)).strftime("%Y-%m-%d")
        else:
            # Category-level fallback
            cat_defaults = {
                "protein": 5, "seafood": 3, "vegetable": 14, "fruit": 10,
                "dairy": 30, "grain": 365, "baking": 365, "seasoning": 730,
                "condiment": 365, "oil": 365, "legume": 365, "nut": 180,
                "beverage": 30,
            }
            cat = (ingredient.get("category") or req.category or "").lower()
            fallback_days = cat_defaults.get(cat, 14)
            expiry = (datetime.now() + timedelta(days=fallback_days)).strftime("%Y-%m-%d")

        # Check if item already exists for this user+ingredient+location
        existing_inv = (
            db.table("inventory_items")
            .select("id, quantity")
            .eq("user_id", req.user_id)
            .eq("ingredient_id", ingredient_id)
            .eq("location", location)
            .limit(1)
            .execute()
        )

        if existing_inv.data and len(existing_inv.data) > 0:
            # Update quantity (add to existing)
            old_qty = existing_inv.data[0]["quantity"]
            new_qty = old_qty + req.quantity
            db.table("inventory_items").update({
                "quantity": new_qty,
                "manual_expiry_date": expiry,
            }).eq("id", existing_inv.data[0]["id"]).execute()

            logger.info(f"[Inventory] Updated {req.ingredient_name} qty: {old_qty} → {new_qty}")
            return {
                "status": "updated",
                "ingredient_id": ingredient_id,
                "category": ingredient.get("category"),
                "default_unit": ingredient.get("default_unit"),
                "shelf_life_days": shelf_days,
                "storage_zone": ingredient.get("storage_zone"),
                "calories_per_100g": ingredient.get("calories_per_100g"),
                "message": f"Updated {req.ingredient_name} quantity to {new_qty}",
            }
        else:
            # Insert new inventory item
            db.table("inventory_items").insert({
                "user_id": req.user_id,
                "ingredient_id": ingredient_id,
                "quantity": req.quantity,
                "unit": req.unit,
                "location": location,
                "manual_expiry_date": expiry,
            }).execute()

            logger.info(f"[Inventory] Added {req.ingredient_name} (id={ingredient_id})")
            return {
                "status": "success",
                "ingredient_id": ingredient_id,
                "category": ingredient.get("category"),
                "default_unit": ingredient.get("default_unit"),
                "shelf_life_days": shelf_days,
                "storage_zone": ingredient.get("storage_zone"),
                "calories_per_100g": ingredient.get("calories_per_100g"),
                "message": f"Added {req.ingredient_name} to shelf",
            }

    except Exception as e:
        raise_internal_error(logger, "[Inventory] Failed to add item", e)


@router.get("/api/v1/ingredients/search")
async def search_ingredients(q: str, current: CurrentUser, limit: int = 8):
    """
    Search ingredients by name across all supported languages.
    Searches: EN, KO, UZ (Latin), UZ (Cyrillic), RU, and canonical_name.
    Returns full metadata for auto-fill.
    """
    db = get_supabase()
    try:
        safe_q = sanitize_search_query(q)
        if not safe_q:
            return {"ingredients": []}
        # Search across all language name fields
        results = (
            db.table("ingredients")
            .select("*")
            .or_(
                f"display_name_en.ilike.%{safe_q}%,"
                f"display_name_ko.ilike.%{safe_q}%,"
                f"display_name_uz.ilike.%{safe_q}%,"
                f"display_name_uz_cyrl.ilike.%{safe_q}%,"
                f"display_name_ru.ilike.%{safe_q}%,"
                f"canonical_name.ilike.%{safe_q}%"
            )
            .limit(limit)
            .execute()
        )
        return {"ingredients": results.data}
    except Exception as e:
        raise_internal_error(logger, "[Ingredients] Search failed", e)


@router.get("/api/v1/ingredients/fuzzy")
async def fuzzy_search_ingredients(q: str, current: CurrentUser, limit: int = 5):
    """
    Fuzzy search ingredients using PostgreSQL pg_trgm similarity.
    Returns results ranked by best match across all language columns.
    Useful for typo-tolerant search in the 'add ingredient' flow.
    """
    db = get_supabase()
    try:
        safe_q = sanitize_search_query(q)
        if not safe_q:
            return {"ingredients": [], "exact_match": False}
        # Use the existing fuzzy_match_ingredient RPC for English,
        # then also do a multilingual ILIKE fallback
        fuzzy_results = db.rpc(
            "fuzzy_match_ingredient",
            {"search_name": safe_q, "min_similarity": 0.15, "max_results": limit}
        ).execute()

        if fuzzy_results.data and len(fuzzy_results.data) > 0:
            # Enrich with full ingredient data
            ids = [r["id"] for r in fuzzy_results.data]
            full_data = (
                db.table("ingredients")
                .select("*")
                .in_("id", ids)
                .execute()
            )
            # Merge similarity scores
            score_map = {r["id"]: r["similarity_score"] for r in fuzzy_results.data}
            for item in full_data.data:
                item["similarity_score"] = score_map.get(item["id"], 0)
            # Sort by similarity descending
            full_data.data.sort(key=lambda x: x.get("similarity_score", 0), reverse=True)
            return {"ingredients": full_data.data, "exact_match": False}
        else:
            return {"ingredients": [], "exact_match": False}
    except Exception as e:
        logger.error(f"[Ingredients] Fuzzy search failed: {e}")
        # Fallback to basic ILIKE search
        try:
            safe_q = sanitize_search_query(q)
            if not safe_q:
                return {"ingredients": [], "exact_match": False}
            results = (
                db.table("ingredients")
                .select("*")
                .or_(
                    f"display_name_en.ilike.%{safe_q}%,"
                    f"canonical_name.ilike.%{safe_q}%"
                )
                .limit(limit)
                .execute()
            )
            return {"ingredients": results.data, "exact_match": False}
        except Exception as e2:
            raise_internal_error(logger, "[Ingredients] Fallback search failed", e2)


class ResolveIngredientRequest(BaseModel):
    name: str
    category: str = "other"
    user_id: Optional[str] = None


@router.post("/api/v1/ingredients/resolve")
async def resolve_ingredient(req: ResolveIngredientRequest, current: CurrentUser):
    """
    Smart ingredient resolver: fuzzy-match first, auto-create if no match.

    Flow:
    1. Exact match on display_name_en → return immediately
    2. Exact match on canonical_name → return immediately
    3. Fuzzy match via pg_trgm → return top match if similarity > 0.5
    4. No match → create as user_contributed ingredient

    Returns: ingredient data + resolution method (exact/fuzzy/created)
    """
    db = get_supabase()
    if req.user_id:
        require_user_id(current, req.user_id)
    name = req.name.strip()
    canonical = name.lower().replace(" ", "_")

    try:
        # Step 1: Exact match on display_name_en
        exact = (
            db.table("ingredients")
            .select("*")
            .ilike("display_name_en", name)
            .limit(1)
            .execute()
        )
        if exact.data and len(exact.data) > 0:
            return {"ingredient": exact.data[0], "resolution": "exact", "created": False}

        # Step 2: Exact match on canonical_name
        canonical_match = (
            db.table("ingredients")
            .select("*")
            .eq("canonical_name", canonical)
            .limit(1)
            .execute()
        )
        if canonical_match.data and len(canonical_match.data) > 0:
            return {"ingredient": canonical_match.data[0], "resolution": "canonical", "created": False}

        # Step 3: Fuzzy match
        try:
            fuzzy = db.rpc(
                "fuzzy_match_ingredient",
                {"search_name": name, "min_similarity": 0.5, "max_results": 1}
            ).execute()
            if fuzzy.data and len(fuzzy.data) > 0:
                match_id = fuzzy.data[0]["id"]
                full = db.table("ingredients").select("*").eq("id", match_id).limit(1).execute()
                if full.data:
                    return {
                        "ingredient": full.data[0],
                        "resolution": "fuzzy",
                        "similarity": fuzzy.data[0]["similarity_score"],
                        "created": False,
                    }
        except Exception:
            pass  # pg_trgm not available, fall through to create

        # Step 4: Create as user-contributed
        inserted = (
            db.table("ingredients")
            .insert({
                "canonical_name": canonical,
                "display_name_en": name,
                "category": req.category.lower(),
                "sub_category": "general",
                "default_unit": "piece",
                "source": "user_contributed",
                "verified": False,
                "created_by": req.user_id or current.id,
            })
            .execute()
        )
        logger.info(f"[Ingredients] Auto-created '{name}' as user_contributed")
        return {"ingredient": inserted.data[0], "resolution": "created", "created": True}

    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, "[Ingredients] Resolve failed", e)


class UpdateItemRequest(BaseModel):
    quantity: Optional[float] = None
    unit: Optional[str] = None
    item_state: Optional[str] = None
    location: Optional[str] = None
    notes: Optional[str] = None


@router.patch("/api/v1/inventory/{item_id}")
async def update_inventory_item(item_id: str, req: UpdateItemRequest, current: CurrentUser):
    """Update an inventory item's properties."""
    db = get_supabase()
    verify_inventory_ownership(db, item_id, current.id)

    try:
        update_data = {}
        if req.quantity is not None:
            update_data["quantity"] = req.quantity
        if req.unit is not None:
            update_data["unit"] = req.unit
        if req.item_state is not None:
            update_data["item_state"] = req.item_state
        if req.location is not None:
            update_data["location"] = req.location
        if req.notes is not None:
            update_data["notes"] = req.notes

        if not update_data:
            return {"status": "no_changes"}

        db.table("inventory_items").update(update_data).eq("id", item_id).eq("user_id", current.id).execute()

        logger.info(f"[Inventory] Updated item {item_id}")
        return {"status": "success"}

    except Exception as e:
        raise_internal_error(logger, "[Inventory] Update failed", e)


@router.delete("/api/v1/inventory/{item_id}")
async def delete_inventory_item(item_id: str, current: CurrentUser):
    """Delete an inventory item."""
    db = get_supabase()
    verify_inventory_ownership(db, item_id, current.id)

    try:
        db.table("inventory_items").delete().eq("id", item_id).eq("user_id", current.id).execute()
        logger.info(f"[Inventory] Deleted item {item_id}")
        return {"status": "success"}

    except Exception as e:
        raise_internal_error(logger, "[Inventory] Delete failed", e)


class ConsumeItemRequest(BaseModel):
    inventory_id: str
    quantity_to_consume: float


@router.post("/api/v1/inventory/consume")
async def consume_inventory_item(req: ConsumeItemRequest, current: CurrentUser):
    """
    Consume (decrement) an inventory item's quantity.
    Uses the consume_inventory_item RPC which auto-deletes at 0.
    """
    db = get_supabase()
    verify_inventory_ownership(db, req.inventory_id, current.id)

    try:
        db.rpc(
            "consume_inventory_item",
            {
                "p_inventory_id": req.inventory_id,
                "p_qty_to_consume": req.quantity_to_consume,
                "p_user_id": current.id,
            },
        ).execute()

        logger.info(
            f"[Inventory] Consumed {req.quantity_to_consume} from {req.inventory_id}"
        )
        return {"status": "success"}

    except Exception as e:
        raise_internal_error(logger, "[Inventory] Consume failed", e)


# ── Batch Consume for Cooking ────────────────────────────────────

class ConsumeRecipeRequest(BaseModel):
    user_id: str
    recipe_id: str
    servings_cooked: float  # actual servings user cooked
    skipped_ingredient_ids: list[str] = []  # ingredients user unchecked

@router.post("/api/v1/inventory/consume-recipe")
async def consume_recipe_ingredients(req: ConsumeRecipeRequest, current: CurrentUser):
    """
    Batch-deduct recipe ingredients from inventory after cooking.
    Scales quantities by (servings_cooked / recipe_default_servings).
    Skips ingredients not in user's inventory or explicitly unchecked.
    """
    require_user_id(current, req.user_id)
    db = get_supabase()

    try:
        # 1. Get recipe default servings
        recipe = (
            db.table("recipes")
            .select("servings")
            .eq("id", req.recipe_id)
            .maybe_single()
            .execute()
        )
        default_servings = (recipe.data or {}).get("servings", 2) or 2
        scale = req.servings_cooked / default_servings

        # 2. Get recipe ingredients
        ings = (
            db.table("recipe_ingredients")
            .select("ingredient_id, quantity, unit, ingredients(display_name_en)")
            .eq("recipe_id", req.recipe_id)
            .execute()
        )

        # 3. Get user's inventory (ingredient_id → inventory row)
        inv = (
            db.table("inventory_items")
            .select("id, ingredient_id, quantity, unit")
            .eq("user_id", req.user_id)
            .gt("quantity", 0)
            .execute()
        )
        inv_map = {}
        for row in (inv.data or []):
            inv_map[row["ingredient_id"]] = row

        consumed = []
        skipped = []

        for ing in (ings.data or []):
            iid = ing["ingredient_id"]
            ing_name = (ing.get("ingredients") or {}).get("display_name_en", "Unknown")

            # Skip if user unchecked this ingredient
            if iid in req.skipped_ingredient_ids:
                skipped.append({"ingredient_id": iid, "name": ing_name, "reason": "user_skipped"})
                continue

            # Skip if not in inventory
            if iid not in inv_map:
                skipped.append({"ingredient_id": iid, "name": ing_name, "reason": "not_in_inventory"})
                continue

            recipe_qty = float(ing.get("quantity", 0)) * scale
            if recipe_qty <= 0:
                continue

            inv_item = inv_map[iid]

            # Deduct (cap at available quantity)
            actual_deduct = min(recipe_qty, inv_item["quantity"])

            try:
                db.rpc(
                    "consume_inventory_item",
                    {
                        "p_inventory_id": inv_item["id"],
                        "p_qty_to_consume": actual_deduct,
                    },
                ).execute()

                consumed.append({
                    "ingredient_id": iid,
                    "name": ing_name,
                    "deducted": actual_deduct,
                    "unit": inv_item.get("unit", ing.get("unit", "")),
                })
            except Exception as e:
                logger.warning(f"[Inventory] Failed to consume {ing_name}: {e}")
                skipped.append({"ingredient_id": iid, "name": ing_name, "reason": f"error: {e}"})

        logger.info(
            f"[Inventory] Recipe {req.recipe_id} consumed: "
            f"{len(consumed)} deducted, {len(skipped)} skipped"
        )
        return {
            "status": "success",
            "consumed": consumed,
            "skipped": skipped,
            "total_deducted": len(consumed),
        }

    except Exception as e:
        raise_internal_error(logger, "[Inventory] Consume recipe failed", e)


# ── Smart Expiry Prediction ──────────────────────────────────────


class PredictExpiryRequest(BaseModel):
    category: str
    purchase_date: Optional[str] = None  # ISO date
    storage_location: str = "fridge"
    packaging: str = "opened"  # "opened" or "sealed"


@router.post("/api/v1/inventory/predict-expiry")
async def predict_expiry_endpoint(req: PredictExpiryRequest, current: CurrentUser):
    """
    Predict expiry date using category, storage location, and packaging.
    
    Uses smart defaults based on food science data:
    - Category-based shelf life (e.g., meat=3d, dairy=10d)
    - Storage multiplier (freezer=6x, pantry=0.5x)
    - Packaging factor (sealed=+50%)
    """
    from app.services.expiry_prediction import predict_expiry
    from datetime import date

    purchase = None
    if req.purchase_date:
        purchase = date.fromisoformat(req.purchase_date)

    result = predict_expiry(
        category=req.category.lower(),
        purchase_date=purchase,
        storage_location=req.storage_location.lower(),
        packaging=req.packaging.lower(),
    )
    return {"status": "success", "data": result}


# ── Visual Freshness Detection ───────────────────────────────────

from fastapi import File, UploadFile, Form

@router.post("/api/v1/inventory/assess-freshness")
async def assess_freshness(
    current: CurrentUser,
    image: UploadFile = File(...),
    ingredient_name: str = Form(...),
    category: str = Form("other"),
):
    """
    Analyze a photo of an ingredient to assess its freshness.
    
    Uses vision AI to detect visual cues (brown spots, wilting,
    color changes) and return a freshness score (0.0-1.0)
    with an adjusted expiry recommendation.
    
    Returns:
        freshness_score, visual_cues, recommendation,
        days_remaining_estimate, adjusted_expiry
    """
    from app.services.expiry_prediction import assess_freshness_from_photo

    image_bytes = await validate_image_upload(image)

    result = await assess_freshness_from_photo(
        image_bytes=image_bytes,
        ingredient_name=ingredient_name,
        category=category.lower(),
    )

    if "error" in result and "AI unavailable" in str(result.get("error", "")):
        raise HTTPException(status_code=503, detail="AI service unavailable")

    return {"status": "success", "data": result}

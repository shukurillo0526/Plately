"""
Plately — Flavor Profile Auto-Learning Service
=================================================
Automatically updates the user's flavor profile based on their
cooking history. When a user cooks a recipe, the system extracts
the recipe's flavor axes (sweet, salty, sour, bitter, umami, spicy)
and blends them into the user's profile using exponential moving average.

This creates a feedback loop:
  cook recipe → update flavor profile → better recommendations → cook again
"""

import logging
from datetime import date
from app.db.supabase_client import get_supabase

logger = logging.getLogger("plately.flavor_learning")

# EMA decay factor: 0.15 means new cook shifts profile by 15%
# Higher = more reactive to recent cooks, lower = more stable
EMA_ALPHA = 0.15

# Default neutral profile for new users
NEUTRAL_PROFILE = {
    "sweet": 0.5,
    "salty": 0.5,
    "sour": 0.5,
    "bitter": 0.5,
    "umami": 0.5,
    "spicy": 0.5,
}

FLAVOR_AXES = ["sweet", "salty", "sour", "bitter", "umami", "spicy"]


async def update_flavor_profile_on_cook(user_id: str, recipe_id: str) -> dict:
    """
    Called after a user marks a recipe as "cooked".
    Updates their flavor profile using exponential moving average
    blended with the recipe's flavor vector.
    
    Returns the updated profile or empty dict on failure.
    """
    db = await get_supabase()
    
    try:
        # 1. Get the recipe's flavor vector
        recipe_flavor = await (
            db.table("recipes")
            .select("flavor_sweet, flavor_salty, flavor_sour, flavor_bitter, flavor_umami, flavor_spicy")
            .eq("id", recipe_id)
            .maybe_single()
            .execute()
        )
        
        if not recipe_flavor.data:
            logger.warning(f"[FlavorLearn] Recipe {recipe_id} not found")
            return {}
        
        recipe_vec = {
            "sweet": float(recipe_flavor.data.get("flavor_sweet", 0.5) or 0.5),
            "salty": float(recipe_flavor.data.get("flavor_salty", 0.5) or 0.5),
            "sour": float(recipe_flavor.data.get("flavor_sour", 0.5) or 0.5),
            "bitter": float(recipe_flavor.data.get("flavor_bitter", 0.5) or 0.5),
            "umami": float(recipe_flavor.data.get("flavor_umami", 0.5) or 0.5),
            "spicy": float(recipe_flavor.data.get("flavor_spicy", 0.5) or 0.5),
        }
        
        # 2. Get the user's current flavor profile
        profile = await (
            db.table("user_flavor_profile")
            .select("sweet, salty, sour, bitter, umami, spicy")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        
        if profile.data:
            current = {
                axis: float(profile.data.get(axis, 0.5) or 0.5)
                for axis in FLAVOR_AXES
            }
        else:
            current = NEUTRAL_PROFILE.copy()
        
        # 3. Apply EMA: new_value = alpha * recipe_value + (1 - alpha) * current_value
        updated = {}
        for axis in FLAVOR_AXES:
            updated[axis] = round(
                EMA_ALPHA * recipe_vec[axis] + (1 - EMA_ALPHA) * current[axis],
                4,
            )
        
        # 4. Upsert the updated profile
        await db.table("user_flavor_profile").upsert(
            {
                "user_id": user_id,
                **updated,
                "updated_at": date.today().isoformat(),
            },
            on_conflict="user_id",
        ).execute()
        
        logger.info(f"[FlavorLearn] Updated profile for {user_id}: {updated}")
        return updated
        
    except Exception as e:
        logger.error(f"[FlavorLearn] Update failed for {user_id}: {e}")
        return {}


async def record_cook_event(user_id: str, recipe_id: str) -> dict:
    """
    Full pipeline: record the cook in history + update flavor profile.
    Called from the frontend when user taps "I cooked this".
    """
    db = await get_supabase()
    
    try:
        # Record in cooking history
        await db.table("user_recipe_history").insert({
            "user_id": user_id,
            "recipe_id": recipe_id,
            "cooked_at": date.today().isoformat(),
        }).execute()
    except Exception as e:
        logger.warning(f"[FlavorLearn] History insert failed: {e}")
    
    # Update flavor profile (best-effort, don't fail the whole call)
    updated_profile = await update_flavor_profile_on_cook(user_id, recipe_id)
    
    return {
        "status": "success",
        "updated_profile": updated_profile,
    }

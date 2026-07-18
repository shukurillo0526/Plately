"""
Plately — Meal Prep Router
============================
AI-powered bulk cooking meal prep plan generation, management,
and tracking. Generates multi-day meal prep plans optimized for
batch cooking with shared base components.
"""

import json
import httpx
import logging
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from typing import Optional, List

from app.core.auth import CurrentUser, require_user_id
from app.core.security import raise_internal_error
from app.db.supabase_client import get_supabase
from app.services.ai_service import get_ai_service as get_ollama_service
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

logger = logging.getLogger("plately.meal_prep")

router = APIRouter()


# ── Request Models ───────────────────────────────────────────────

class GenerateMealPrepRequest(BaseModel):
    user_id: str
    days: int = 5
    meals_per_day: int = 3
    target_calories_per_meal: Optional[int] = 500
    target_protein_g: Optional[float] = 30
    target_carbs_g: Optional[float] = 40
    target_fat_g: Optional[float] = 15
    cuisine: Optional[str] = None
    available_ingredients: List[str] = []
    shelf_only: bool = False
    locale: Optional[str] = "en"


class StartPlanRequest(BaseModel):
    pass


class CompletePlanRequest(BaseModel):
    actual_prep_time_minutes: int


class RecipeCookedRequest(BaseModel):
    portions_cooked: int


# ── Endpoints ────────────────────────────────────────────────────

@router.post("/api/v1/meal-prep/generate")
@limiter.limit("5/minute")
async def generate_meal_prep(request: Request, req: GenerateMealPrepRequest, current: CurrentUser):
    """
    AI-generate a multi-day meal prep plan with recipes optimized
    for batch cooking. Returns recipes, shopping list, and timeline.
    """
    require_user_id(current, req.user_id)
    ollama = get_ollama_service()
    db = await get_supabase()

    total_recipes = req.days * req.meals_per_day
    # Cap at reasonable limits
    if total_recipes > 21:
        raise HTTPException(status_code=400, detail="Maximum 21 meals per plan (7 days × 3 meals)")

    cuisine_hint = f"Cuisine preference: {req.cuisine}. " if req.cuisine else ""
    shelf_constraint = ""
    if req.shelf_only and req.available_ingredients:
        shelf_constraint = (
            "\nIMPORTANT: Prioritize using ONLY these available ingredients: "
            f"{', '.join(req.available_ingredients)}. "
            "You may add common pantry staples (salt, pepper, oil, water, basic spices)."
        )

    ingredients_hint = ""
    if req.available_ingredients:
        ingredients_hint = f"\nAvailable ingredients: {', '.join(req.available_ingredients)}"

    batch_count = min(req.days + 2, 7)
    prompt = f"""Create a {req.days}-day batch cooking meal prep plan with {req.meals_per_day} meals per day (yielding enough total portions to cover {total_recipes} individual meals).
{cuisine_hint}
Target macros per serving:
- Calories: ~{req.target_calories_per_meal or 500} kcal
- Protein: ~{req.target_protein_g or 30}g
- Carbs: ~{req.target_carbs_g or 40}g
- Fat: ~{req.target_fat_g or 15}g
{ingredients_hint}{shelf_constraint}

CRITICAL RULES:
1. Optimize for BATCH COOKING: generate exactly {batch_count} high-yield batch prep recipes where each recipe yields 3 to 5 portions. Together, these {batch_count} batch recipes cover all {total_recipes} meals for the week.
2. Recipes should share base components (same rice, same protein, same roasted vegetables) to minimize total prep work.
3. Include variety across the batch dishes (e.g. 2-3 main proteins, 2 sides/grains, 1 breakfast/snack base).
4. All recipes must be practical to store in fridge (3-4 days) or freezer (up to 30 days).
5. Order recipes by cooking efficiency (cook base components first).
6. Keep steps clear and concise (3-5 steps per recipe) so the batch cooking workflow is fast and easy to follow.

Return JSON only:
{{
  "title": "5-Day High Protein Meal Prep",
  "estimated_total_prep_minutes": 120,
  "recipes": [
    {{
      "title": "Recipe Name",
      "description": "Short description",
      "cuisine": "Korean",
      "prep_time_minutes": 10,
      "cook_time_minutes": 20,
      "servings": 4,
      "calories_per_serving": 500,
      "protein_g": 35,
      "carbs_g": 40,
      "fat_g": 15,
      "storage_tip": "Keeps 4 days in fridge, 30 days frozen",
      "ingredients": [{{"name": "chicken breast", "quantity": 500, "unit": "g"}}],
      "steps": [{{"step_number": 1, "text": "...", "duration_minutes": 5}}]
    }}
  ],
  "shopping_list": [
    {{"name": "chicken breast", "total_quantity": 1500, "unit": "g", "category": "protein"}}
  ],
  "cooking_timeline": "Start with rice and chicken simultaneously. While those cook, prep vegetables..."
}}"""

    system = (
        "You are a professional meal prep chef and nutritionist. "
        "Create practical, delicious meal prep plans optimized for batch cooking. "
        "Recipes should share base components to save time. "
        "Return only valid JSON."
    )

    try:
        result = await ollama.generate_text_json(
            prompt, system_prompt=system, model="gemini-2.5-flash", max_tokens=8192
        )

        if "error" in result:
            logger.warning(f"[MealPrep] First attempt returned error ({result.get('error')}). Retrying with strict format prompt...")
            strict_prompt = prompt + "\n\nCRITICAL: Return ONLY clean JSON without markdown blocks, without trailing commas, and without comments."
            result = await ollama.generate_text_json(
                strict_prompt, system_prompt=system, model="gemini-2.5-flash", max_tokens=8192
            )

        if "error" in result:
            raw_preview = result.get("raw_response", "")[:120].strip()
            msg = f"AI formatting error: {result['error']} ({raw_preview})" if raw_preview else f"AI error: {result['error']}"
            return {
                "status": "partial",
                "message": msg,
                "data": result,
            }

        # Extract plan data
        plan_title = result.get("title", f"{req.days}-Day Meal Prep Plan")
        recipes = result.get("recipes", [])
        shopping_list = result.get("shopping_list", [])
        cooking_timeline = result.get("cooking_timeline", "")
        total_prep_minutes = result.get("estimated_total_prep_minutes", 0)

        # Save plan to database
        plan_insert = await db.table("meal_prep_plans").insert({
            "user_id": req.user_id,
            "title": plan_title,
            "days": req.days,
            "meals_per_day": req.meals_per_day,
            "target_calories_per_meal": req.target_calories_per_meal,
            "target_protein_g": req.target_protein_g,
            "target_carbs_g": req.target_carbs_g,
            "target_fat_g": req.target_fat_g,
            "cuisine_preference": req.cuisine,
            "total_prep_time_minutes": total_prep_minutes,
            "status": "planned",
        }).execute()

        plan_id = plan_insert.data[0]["id"]

        # Save individual recipes
        for i, recipe in enumerate(recipes):
            await db.table("prep_plan_recipes").insert({
                "plan_id": plan_id,
                "recipe_data": json.dumps(recipe) if isinstance(recipe, dict) else recipe,
                "portions_target": recipe.get("servings", 4) if isinstance(recipe, dict) else 4,
                "cook_order": i,
                "status": "pending",
            }).execute()

        return {
            "status": "success",
            "data": {
                "plan_id": plan_id,
                "title": plan_title,
                "days": req.days,
                "meals_per_day": req.meals_per_day,
                "estimated_total_prep_minutes": total_prep_minutes,
                "recipes": recipes,
                "shopping_list": shopping_list,
                "cooking_timeline": cooking_timeline,
            },
        }

    except HTTPException:
        raise
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 429:
            raise HTTPException(status_code=429, detail="AI quota or rate-limit reached. Please try again in a few moments.")
        raise_internal_error(logger, "[MealPrep] HTTP status error from AI provider", e)
    except Exception as e:
        raise_internal_error(logger, "[MealPrep] Failed to generate meal prep plan", e)


@router.get("/api/v1/meal-prep/plans")
async def list_meal_prep_plans(current: CurrentUser):
    """List the current user's meal prep plans, newest first."""
    db = await get_supabase()
    try:
        result = await (
            db.table("meal_prep_plans")
            .select("*")
            .eq("user_id", current.id)
            .order("created_at", desc=True)
            .limit(20)
            .execute()
        )
        return {"status": "success", "data": result.data or []}
    except Exception as e:
        raise_internal_error(logger, "[MealPrep] Failed to list plans", e)


@router.get("/api/v1/meal-prep/{plan_id}")
async def get_meal_prep_plan(plan_id: str, current: CurrentUser):
    """Get a single meal prep plan with all its recipes."""
    db = await get_supabase()
    try:
        # Fetch plan
        plan = await (
            db.table("meal_prep_plans")
            .select("*")
            .eq("id", plan_id)
            .eq("user_id", current.id)
            .maybe_single()
            .execute()
        )
        if not plan.data:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Fetch recipes
        recipes = await (
            db.table("prep_plan_recipes")
            .select("*")
            .eq("plan_id", plan_id)
            .order("cook_order")
            .execute()
        )

        # Parse recipe_data from JSON string to dict
        recipe_list = []
        for r in (recipes.data or []):
            recipe_entry = dict(r)
            if isinstance(recipe_entry.get("recipe_data"), str):
                try:
                    recipe_entry["recipe_data"] = json.loads(recipe_entry["recipe_data"])
                except json.JSONDecodeError:
                    pass
            recipe_list.append(recipe_entry)

        plan_data = plan.data
        plan_data["recipes"] = recipe_list

        return {"status": "success", "data": plan_data}
    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, f"[MealPrep] Failed to get plan {plan_id}", e)


@router.post("/api/v1/meal-prep/{plan_id}/start")
async def start_meal_prep(plan_id: str, current: CurrentUser):
    """Mark a meal prep plan as in_progress."""
    db = await get_supabase()
    try:
        # Verify ownership
        plan = await (
            db.table("meal_prep_plans")
            .select("id, user_id, status")
            .eq("id", plan_id)
            .eq("user_id", current.id)
            .maybe_single()
            .execute()
        )
        if not plan.data:
            raise HTTPException(status_code=404, detail="Plan not found")
        if plan.data["status"] not in ("planned", "abandoned"):
            raise HTTPException(status_code=400, detail=f"Plan is already {plan.data['status']}")

        await db.table("meal_prep_plans").update({
            "status": "in_progress",
            "started_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", plan_id).execute()

        return {"status": "success", "message": "Prep session started"}
    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, f"[MealPrep] Failed to start plan {plan_id}", e)


@router.post("/api/v1/meal-prep/{plan_id}/complete")
async def complete_meal_prep(plan_id: str, req: CompletePlanRequest, current: CurrentUser):
    """
    Mark a meal prep plan as completed. Updates gamification stats:
    total_prep_sessions, total_prepped_meals, total_prep_minutes, prep streak.
    """
    db = await get_supabase()
    try:
        # Verify ownership and status
        plan = await (
            db.table("meal_prep_plans")
            .select("id, user_id, status")
            .eq("id", plan_id)
            .eq("user_id", current.id)
            .maybe_single()
            .execute()
        )
        if not plan.data:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Count cooked recipes
        recipes = await (
            db.table("prep_plan_recipes")
            .select("status, portions_cooked")
            .eq("plan_id", plan_id)
            .execute()
        )
        cooked_count = sum(1 for r in (recipes.data or []) if r["status"] == "cooked")
        total_portions = sum(r.get("portions_cooked", 0) for r in (recipes.data or []))

        # Update plan
        await db.table("meal_prep_plans").update({
            "status": "completed",
            "actual_prep_time_minutes": req.actual_prep_time_minutes,
            "completed_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", plan_id).execute()

        # Update gamification stats
        try:
            today = datetime.now(timezone.utc).date().isoformat()
            stats = await (
                db.table("gamification_stats")
                .select("total_prep_sessions, total_prepped_meals, total_prep_minutes, "
                        "current_prep_streak, best_prep_streak, last_prep_date")
                .eq("user_id", current.id)
                .maybe_single()
                .execute()
            )
            if stats.data:
                s = stats.data
                new_sessions = (s.get("total_prep_sessions") or 0) + 1
                new_meals = (s.get("total_prepped_meals") or 0) + total_portions
                new_minutes = (s.get("total_prep_minutes") or 0) + req.actual_prep_time_minutes

                # Streak logic: if last prep was yesterday or today, increment; else reset
                last_prep = s.get("last_prep_date")
                current_streak = s.get("current_prep_streak") or 0
                if last_prep:
                    from datetime import date, timedelta
                    last = date.fromisoformat(str(last_prep))
                    diff = (date.fromisoformat(today) - last).days
                    if diff <= 7:  # Within a week counts as maintaining streak
                        current_streak += 1
                    else:
                        current_streak = 1
                else:
                    current_streak = 1

                best_streak = max(s.get("best_prep_streak") or 0, current_streak)

                await db.table("gamification_stats").update({
                    "total_prep_sessions": new_sessions,
                    "total_prepped_meals": new_meals,
                    "total_prep_minutes": new_minutes,
                    "current_prep_streak": current_streak,
                    "best_prep_streak": best_streak,
                    "last_prep_date": today,
                }).eq("user_id", current.id).execute()
        except Exception as gam_err:
            logger.warning("Failed to update gamification stats: %s", gam_err)

        return {
            "status": "success",
            "data": {
                "recipes_cooked": cooked_count,
                "total_portions": total_portions,
                "actual_prep_time_minutes": req.actual_prep_time_minutes,
            },
        }
    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, f"[MealPrep] Failed to complete plan {plan_id}", e)


@router.post("/api/v1/meal-prep/{plan_id}/recipe/{recipe_index}/cooked")
async def mark_recipe_cooked(
    plan_id: str, recipe_index: int, req: RecipeCookedRequest, current: CurrentUser
):
    """Mark an individual recipe in a prep plan as cooked."""
    db = await get_supabase()
    try:
        # Verify plan ownership
        plan = await (
            db.table("meal_prep_plans")
            .select("id, user_id")
            .eq("id", plan_id)
            .eq("user_id", current.id)
            .maybe_single()
            .execute()
        )
        if not plan.data:
            raise HTTPException(status_code=404, detail="Plan not found")

        # Find the recipe by cook_order
        recipe = await (
            db.table("prep_plan_recipes")
            .select("id, status")
            .eq("plan_id", plan_id)
            .eq("cook_order", recipe_index)
            .maybe_single()
            .execute()
        )
        if not recipe.data:
            raise HTTPException(status_code=404, detail=f"Recipe at index {recipe_index} not found")

        await db.table("prep_plan_recipes").update({
            "status": "cooked",
            "portions_cooked": req.portions_cooked,
        }).eq("id", recipe.data["id"]).execute()

        return {"status": "success", "message": f"Recipe {recipe_index} marked as cooked"}
    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(
            logger, f"[MealPrep] Failed to mark recipe {recipe_index} cooked in plan {plan_id}", e
        )

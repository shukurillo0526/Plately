"""
Plately — Calorie Analysis Router
====================================
Analyzes food images to estimate calories and macros.
Uses local LLM (Ollama) for food identification + ingredient DB for calorie data.
"""

import json
import logging
import base64
from datetime import datetime
from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import Optional, List

from app.core.auth import CurrentUser, require_user_id
from app.core.security import raise_internal_error, validate_image_upload, sanitize_search_query
from app.db.supabase_client import get_supabase
from app.services.ollama_service import get_ollama_service

logger = logging.getLogger("plately.calories")

router = APIRouter()


@router.post("/api/v1/calories/analyze-image")
async def analyze_image_calories(current: CurrentUser, file: UploadFile = File(...)):
    """
    Analyze a food photo for calorie content.
    Estimates the total portion size, weight, calories, and macros for the entire meal shown in the photo.
    """
    image_bytes = await validate_image_upload(file)

    ollama = get_ollama_service()

    prompt = (
        "Analyze the food visible in this image as a single prepared meal plate.\n"
        "1. Identify the main cooked dish/meal name.\n"
        "2. Look at the physical portion size and volume of food on the plate/bowl (e.g., standard plate, double portion, small cup) and estimate the total serving weight in grams.\n"
        "3. Estimate the total calories, protein (g), carbs (g), and fat (g) for the ENTIRE plate/serving visible in the photo.\n"
        "4. List the individual components identified on the plate (e.g. chicken thigh, side rice, roasted veggies) with their name, estimated serving weight, and estimated calories.\n\n"
        "Format the output strictly as a JSON object with these keys:\n"
        "{\n"
        "  \"status\": \"success\",\n"
        "  \"meal_name\": \"Name of the meal\",\n"
        "  \"estimated_weight_g\": 450,\n"
        "  \"total_estimated_calories\": 720,\n"
        "  \"protein_g\": 35,\n"
        "  \"carbs_g\": 85,\n"
        "  \"fat_g\": 26,\n"
        "  \"items\": [\n"
        "    {\n"
        "      \"name\": \"Component name\",\n"
        "      \"estimated_serving_g\": 400,\n"
        "      \"estimated_calories\": 650,\n"
        "      \"protein_g\": 32,\n"
        "      \"carbs_g\": 78,\n"
        "      \"fat_g\": 23\n"
        "    }\n"
        "  ]\n"
        "}\n"
        "CRITICAL ANTI-HALLUCINATION RULE: If the photo is blurry, unreadable, or does not clearly show food, return exactly:\n"
        "{\"status\": \"no_food_detected\", \"items\": [], \"total_estimated_calories\": 0}\n"
        "Return ONLY this JSON object. Do not include markdown formatting or backticks around the JSON."
    )

    try:
        result = await ollama.analyze_image_json(image_bytes, prompt)
        if not result or "total_estimated_calories" not in result or result.get("status") == "no_food_detected":
            return {"status": "no_food_detected", "items": [], "total_estimated_calories": 0}
        
        result["status"] = "success"
        # Ensure all required fields exist
        result.setdefault("meal_name", "Scanned Meal")
        result.setdefault("estimated_weight_g", 300)
        result.setdefault("total_estimated_calories", 0)
        result.setdefault("protein_g", 0)
        result.setdefault("carbs_g", 0)
        result.setdefault("fat_g", 0)
        result.setdefault("items", [])
        
        # Add source tag to components
        for item in result["items"]:
            item["source"] = "ai_estimate"

        return result
    except Exception as e:
        logger.error(f"[Calories] Plate vision analysis failed: {e}")
        return {"status": "no_food_detected", "items": [], "total_estimated_calories": 0}



class CalorieAnalyzeRequest(BaseModel):
    """Analyze food items for calorie content."""
    food_items: List[str]  # list of food names detected from image or typed


class NutritionLogRequest(BaseModel):
    """Log a meal's nutrition."""
    user_id: str
    meal_type: str = "snack"  # breakfast, lunch, dinner, snack
    food_items: List[dict]   # [{name, quantity_g, calories, protein_g, carbs_g, fat_g}]
    notes: Optional[str] = None


@router.post("/api/v1/calories/analyze")
async def analyze_calories(req: CalorieAnalyzeRequest, current: CurrentUser):
    """
    Estimate calories and macros for a list of food items.
    First checks ingredient DB for calories_per_100g, then falls back to AI.
    """
    db = get_supabase()
    results = []
    unknown_items = []

    for item_name in req.food_items:
        # Try DB lookup first
        safe_name = sanitize_search_query(item_name)
        match = (
            db.table("ingredients")
            .select("display_name_en, calories_per_100g, default_unit, category")
            .ilike("display_name_en", f"%{safe_name}%")
            .limit(1)
            .execute()
        )

        if match.data and len(match.data) > 0 and match.data[0].get("calories_per_100g"):
            ing = match.data[0]
            cal = ing["calories_per_100g"]
            results.append({
                "name": ing["display_name_en"],
                "source": "database",
                "calories_per_100g": cal,
                "estimated_serving_g": _estimate_serving(ing.get("category", "")),
                "estimated_calories": round(cal * _estimate_serving(ing.get("category", "")) / 100),
                "category": ing.get("category"),
            })
        else:
            unknown_items.append(item_name)

    # For items not in DB, use AI to estimate
    if unknown_items:
        ollama = get_ollama_service()
        prompt = f"""Estimate the nutrition for these food items: {', '.join(unknown_items)}.

For each item, provide:
- Typical serving size in grams
- Calories per 100g
- Estimated calories for one serving
- Macros per serving (protein_g, carbs_g, fat_g)

Return JSON only:
{{"items": [{{"name": "...", "serving_g": 150, "calories_per_100g": 200, "estimated_calories": 300, "protein_g": 10, "carbs_g": 30, "fat_g": 15}}]}}"""

        system = "You are a certified nutritionist. Provide accurate calorie estimates. Return only valid JSON."
        ai_result = await ollama.generate_text_json(prompt, system_prompt=system)

        if "items" in ai_result:
            for item in ai_result["items"]:
                item["source"] = "ai_estimate"
                results.append(item)

    # Calculate totals
    total_calories = sum(r.get("estimated_calories", 0) for r in results)

    return {
        "status": "success",
        "items": results,
        "total_estimated_calories": total_calories,
        "item_count": len(results),
    }


@router.post("/api/v1/calories/log")
async def log_nutrition(req: NutritionLogRequest, current: CurrentUser):
    """Log a meal to the user's daily nutrition tracker."""
    require_user_id(current, req.user_id)
    db = get_supabase()

    try:
        total_cal = sum(item.get("calories", 0) for item in req.food_items)
        total_protein = sum(item.get("protein_g", 0) for item in req.food_items)
        total_carbs = sum(item.get("carbs_g", 0) for item in req.food_items)
        total_fat = sum(item.get("fat_g", 0) for item in req.food_items)

        db.table("nutrition_logs").insert({
            "user_id": req.user_id,
            "meal_type": req.meal_type,
            "food_items": json.dumps(req.food_items),
            "total_calories": total_cal,
            "total_protein_g": total_protein,
            "total_carbs_g": total_carbs,
            "total_fat_g": total_fat,
            "notes": req.notes,
            "logged_at": datetime.now().isoformat(),
        }).execute()

        return {"status": "success", "total_calories": total_cal}

    except Exception as e:
        raise_internal_error(logger, "[Calories] Log failed", e)


@router.get("/api/v1/calories/daily/{user_id}")
async def get_daily_nutrition(user_id: str, current: CurrentUser, date: Optional[str] = None):
    """Get a user's nutrition summary for a specific date."""
    require_user_id(current, user_id)
    db = get_supabase()

    target_date = date or datetime.now().strftime("%Y-%m-%d")

    try:
        logs = (
            db.table("nutrition_logs")
            .select("*")
            .eq("user_id", user_id)
            .gte("logged_at", f"{target_date}T00:00:00")
            .lte("logged_at", f"{target_date}T23:59:59")
            .order("logged_at")
            .execute()
        )

        total_cal = sum(log.get("total_calories", 0) for log in logs.data)
        total_protein = sum(log.get("total_protein_g", 0) for log in logs.data)
        total_carbs = sum(log.get("total_carbs_g", 0) for log in logs.data)
        total_fat = sum(log.get("total_fat_g", 0) for log in logs.data)

        return {
            "date": target_date,
            "meals": logs.data,
            "totals": {
                "calories": total_cal,
                "protein_g": total_protein,
                "carbs_g": total_carbs,
                "fat_g": total_fat,
            },
            "goal": 2000,  # default daily goal, can be user-specific later
        }

    except Exception as e:
        raise_internal_error(logger, "[Calories] Daily fetch failed", e)


def _estimate_serving(category: str) -> int:
    """Estimate a typical serving size in grams based on category."""
    cat = category.lower()
    serving_map = {
        "vegetable": 150, "fruit": 130, "protein": 150, "meat": 150,
        "seafood": 120, "dairy": 200, "grain": 80, "baking": 30,
        "seasoning": 5, "condiment": 15, "oil": 15, "legume": 100,
        "nut": 30, "beverage": 250, "snack": 50,
    }
    return serving_map.get(cat, 100)


# Unit → grams conversion for common cooking measurements
UNIT_TO_GRAMS = {
    "g": 1, "gram": 1, "grams": 1,
    "kg": 1000, "kilogram": 1000,
    "ml": 1, "milliliter": 1,
    "l": 1000, "liter": 1000,
    "tbsp": 15, "tablespoon": 15,
    "tsp": 5, "teaspoon": 5,
    "cup": 240, "cups": 240,
    "large": 60, "medium": 45, "small": 30,
    "slice": 30, "slices": 30,
    "piece": 50, "pieces": 50, "pcs": 50, "pc": 50,
    "clove": 5, "cloves": 5,
    "pinch": 0.5, "dash": 0.6,
    "oz": 28, "ounce": 28,
    "lb": 454, "pound": 454,
    "bunch": 100, "head": 300, "stalk": 60,
    "can": 400,
}

def _unit_to_grams(quantity: float, unit: str, category: str = "") -> float:
    """Convert a quantity+unit to grams for calorie computation."""
    unit_lower = unit.lower().strip()
    if unit_lower in UNIT_TO_GRAMS:
        return quantity * UNIT_TO_GRAMS[unit_lower]
    # Fallback: use category-based serving estimate
    return quantity * _estimate_serving(category)


@router.get("/api/v1/calories/recipe/{recipe_id}")
async def get_recipe_calories(recipe_id: str, current: CurrentUser, servings: Optional[int] = None):
    """
    Compute total and per-serving calories + macros for a recipe.
    Uses per-ingredient calories_per_100g from the ingredients table.
    Falls back to AI estimate for ingredients missing calorie data.
    
    Returns: per-ingredient breakdown + totals + per-serving values.
    """
    db = get_supabase()

    try:
        # 1. Get recipe default servings
        recipe = (
            db.table("recipes")
            .select("servings, title")
            .eq("id", recipe_id)
            .maybe_single()
            .execute()
        )
        recipe_data = recipe.data or {}
        default_servings = recipe_data.get("servings", 2) or 2
        requested_servings = servings or default_servings
        scale = requested_servings / default_servings

        # 2. Get recipe ingredients with calorie data
        ings = (
            db.table("recipe_ingredients")
            .select(
                "ingredient_id, quantity, unit, "
                "ingredients(display_name_en, calories_per_100g, category)"
            )
            .eq("recipe_id", recipe_id)
            .execute()
        )

        items = []
        total_cal = 0
        total_protein = 0
        total_carbs = 0
        total_fat = 0
        unknown_items = []

        for ing in (ings.data or []):
            ing_data = ing.get("ingredients") or {}
            name = ing_data.get("display_name_en", "Unknown")
            cal_per_100g = ing_data.get("calories_per_100g")
            category = ing_data.get("category", "")
            qty = float(ing.get("quantity", 0)) * scale
            unit = ing.get("unit", "")

            if cal_per_100g and cal_per_100g > 0:
                grams = _unit_to_grams(qty, unit, category)
                item_cal = round(cal_per_100g * grams / 100)
                items.append({
                    "name": name,
                    "quantity": round(qty, 2),
                    "unit": unit,
                    "grams": round(grams, 1),
                    "calories_per_100g": cal_per_100g,
                    "calories": item_cal,
                    "source": "database",
                })
                total_cal += item_cal
            else:
                unknown_items.append({
                    "name": name,
                    "quantity": qty,
                    "unit": unit,
                    "ingredient_id": ing.get("ingredient_id"),
                })

        # 3. AI fallback for unknown items
        if unknown_items:
            try:
                ollama = get_ollama_service()
                item_list = ", ".join(
                    f"{u['quantity']} {u['unit']} {u['name']}" for u in unknown_items
                )
                prompt = f"""Estimate calories for these recipe ingredients: {item_list}.
Return JSON only:
{{"items": [{{"name": "...", "calories": 120, "protein_g": 5, "carbs_g": 15, "fat_g": 3}}]}}"""
                system = "Certified nutritionist. Return only valid JSON."
                ai_result = await ollama.generate_text_json(
                    prompt, system_prompt=system, model="gemini-2.5-flash-lite"
                )
                for ai_item in ai_result.get("items", []):
                    cal = ai_item.get("calories", 0)
                    items.append({
                        "name": ai_item.get("name", "Unknown"),
                        "calories": cal,
                        "protein_g": ai_item.get("protein_g", 0),
                        "carbs_g": ai_item.get("carbs_g", 0),
                        "fat_g": ai_item.get("fat_g", 0),
                        "source": "ai_estimate",
                    })
                    total_cal += cal
                    total_protein += ai_item.get("protein_g", 0)
                    total_carbs += ai_item.get("carbs_g", 0)
                    total_fat += ai_item.get("fat_g", 0)
            except Exception as e:
                logger.warning(f"[Calories] AI fallback failed: {e}")

        per_serving = round(total_cal / requested_servings) if requested_servings > 0 else 0

        return {
            "status": "success",
            "recipe_id": recipe_id,
            "title": recipe_data.get("title", ""),
            "servings": requested_servings,
            "items": items,
            "totals": {
                "calories": total_cal,
                "per_serving": per_serving,
                "protein_g": total_protein,
                "carbs_g": total_carbs,
                "fat_g": total_fat,
            },
        }

    except Exception as e:
        raise_internal_error(logger, "[Calories] Recipe calorie computation failed", e)


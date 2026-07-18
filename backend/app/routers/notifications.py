"""
Plately — Expiry Notification Router
========================================
Checks for ingredients expiring within N days and generates
notification payloads. Can be called by a cron job or manually.

Endpoints:
  GET /api/v1/notifications/expiring/{user_id}
      → Returns items expiring within 2 days with recipe suggestions

  POST /api/v1/notifications/send-alerts
      → Batch check all users and return notification payloads
"""

import logging
from datetime import date, timedelta
from fastapi import APIRouter, HTTPException

from app.core.auth import CurrentUser, require_user_id
from app.core.security import raise_internal_error
from app.db.supabase_client import get_supabase

logger = logging.getLogger("plately.notifications")

router = APIRouter(tags=["Notifications"])


@router.get("/api/v1/notifications/expiring/{user_id}")
async def get_expiring_items(user_id: str, current: CurrentUser, days: int = 2):
    """
    Get items expiring within N days for a user.
    
    Returns a list of expiring items with urgency levels:
    - 🔴 critical: expires today
    - 🟡 warning: expires tomorrow
    - 🟢 upcoming: expires in 2+ days
    """
    require_user_id(current, user_id)
    try:
        supabase = await get_supabase()
        today = date.today()
        cutoff = today + timedelta(days=days)

        response = await supabase.from_("inventory").select(
            "id, quantity, unit, expiry_date, location, ingredients(name, category, emoji)"
        ).eq(
            "user_id", user_id
        ).lte(
            "expiry_date", cutoff.isoformat()
        ).gte(
            "expiry_date", today.isoformat()
        ).gt(
            "quantity", 0
        ).order(
            "expiry_date", desc=False
        ).execute()

        items = response.data or []

        # Classify urgency
        notifications = []
        for item in items:
            expiry = date.fromisoformat(item["expiry_date"])
            days_left = (expiry - today).days

            if days_left == 0:
                urgency = "critical"
                emoji = "🔴"
                message = f"{item['ingredients']['name']} expires TODAY!"
            elif days_left == 1:
                urgency = "warning"
                emoji = "🟡"
                message = f"{item['ingredients']['name']} expires tomorrow"
            else:
                urgency = "upcoming"
                emoji = "🟢"
                message = f"{item['ingredients']['name']} expires in {days_left} days"

            notifications.append({
                "inventory_id": item["id"],
                "ingredient_name": item["ingredients"]["name"],
                "category": item["ingredients"].get("category", "other"),
                "emoji": item["ingredients"].get("emoji", "🍽️"),
                "quantity": item["quantity"],
                "unit": item["unit"],
                "expiry_date": item["expiry_date"],
                "days_left": days_left,
                "urgency": urgency,
                "message": f"{emoji} {message}",
            })

        # Generate a summary notification
        critical_count = sum(1 for n in notifications if n["urgency"] == "critical")
        warning_count = sum(1 for n in notifications if n["urgency"] == "warning")

        summary = None
        if critical_count > 0:
            items_str = ", ".join(
                n["ingredient_name"] for n in notifications if n["urgency"] == "critical"
            )
            summary = {
                "title": f"🔴 {critical_count} item{'s' if critical_count > 1 else ''} expiring today!",
                "body": f"Use up: {items_str}. Tap for recipe ideas!",
                "priority": "high",
            }
        elif warning_count > 0:
            items_str = ", ".join(
                n["ingredient_name"] for n in notifications if n["urgency"] == "warning"
            )
            summary = {
                "title": f"🟡 {warning_count} item{'s' if warning_count > 1 else ''} expiring tomorrow",
                "body": f"Plan to use: {items_str}",
                "priority": "normal",
            }

        return {
            "status": "success",
            "data": {
                "items": notifications,
                "total": len(notifications),
                "critical": critical_count,
                "warning": warning_count,
                "summary": summary,
            },
        }

    except Exception as e:
        raise_internal_error(logger, "[Notifications] Failed to check expiring items", e)


@router.get("/api/v1/notifications/prep-status/{user_id}")
async def get_prep_status(user_id: str, current: CurrentUser):
    """
    Get meal prep stock levels and upcoming expiry warnings.
    Groups cooked leftover items by recipe and returns alerts for:
    - Running low: ≤2 portions remaining
    - Expiring soon: ≤2 days until recommended consumption limit
    """
    require_user_id(current, user_id)
    try:
        supabase = await get_supabase()
        today = date.today()

        # Fetch all cooked leftover items for this user
        response = await (
            supabase.from_("inventory_items")
            .select("id, parent_recipe_id, parent_recipe_title, portions_count, "
                    "computed_expiry, location, container_label, "
                    "calories_per_portion, protein_per_portion, carbs_per_portion, fat_per_portion")
            .eq("user_id", user_id)
            .eq("is_cooked_leftover", True)
            .gt("portions_count", 0)
            .execute()
        )

        items = response.data or []
        if not items:
            return {
                "status": "success",
                "data": {"recipes": [], "alerts": [], "total_portions": 0},
            }

        # Group by recipe
        by_recipe = {}
        for item in items:
            title = item.get("parent_recipe_title") or "Unknown Meal"
            if title not in by_recipe:
                by_recipe[title] = {
                    "recipe_title": title,
                    "recipe_id": item.get("parent_recipe_id"),
                    "portions_remaining": 0,
                    "oldest_expiry": None,
                    "storage_zone": item.get("location", "fridge"),
                    "container_labels": [],
                    "calories_per_portion": item.get("calories_per_portion"),
                }
            entry = by_recipe[title]
            entry["portions_remaining"] += item.get("portions_count", 0)

            label = item.get("container_label")
            if label and label not in entry["container_labels"]:
                entry["container_labels"].append(label)

            expiry = item.get("computed_expiry")
            if expiry:
                expiry_date = date.fromisoformat(str(expiry)[:10])
                if entry["oldest_expiry"] is None or expiry_date < entry["oldest_expiry"]:
                    entry["oldest_expiry"] = expiry_date

        # Build alerts
        alerts = []
        recipes_out = []
        total_portions = 0

        for title, data in by_recipe.items():
            portions = data["portions_remaining"]
            total_portions += portions
            days_left = None
            if data["oldest_expiry"]:
                days_left = (data["oldest_expiry"] - today).days
                data["oldest_expiry"] = data["oldest_expiry"].isoformat()
            else:
                data["oldest_expiry"] = None

            data["days_left"] = days_left
            recipes_out.append(data)

            # Low stock alert
            if portions <= 2:
                alerts.append({
                    "type": "running_low",
                    "recipe_title": title,
                    "portions_remaining": portions,
                    "message": f"Your prep meals are running low: {portions} serving{'s' if portions != 1 else ''} of {title} left.",
                    "priority": "normal",
                })

            # Expiring soon alert
            if days_left is not None and days_left <= 2:
                container_text = f" ({', '.join(data['container_labels'])})" if data['container_labels'] else ""
                alerts.append({
                    "type": "expiring_soon",
                    "recipe_title": title,
                    "days_left": days_left,
                    "message": f"{title}{container_text} will hit recommended storage limit in {days_left} day{'s' if days_left != 1 else ''}.",
                    "priority": "high" if days_left <= 1 else "normal",
                })

        return {
            "status": "success",
            "data": {
                "recipes": recipes_out,
                "alerts": alerts,
                "total_portions": total_portions,
            },
        }

    except Exception as e:
        raise_internal_error(logger, "[Notifications] Failed to check prep status", e)


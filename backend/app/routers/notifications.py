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
        supabase = get_supabase()
        today = date.today()
        cutoff = today + timedelta(days=days)

        response = supabase.from_("inventory").select(
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

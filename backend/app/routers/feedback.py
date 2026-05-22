"""
Plately — Recipe Feedback Router
====================================
Handles recipe feedback submissions (thumbs up/down, feature ratings,
reports) and aggregated sentiment queries.

Endpoints:
  POST /api/v1/feedback/submit
      → Submit or update recipe feedback

  GET  /api/v1/feedback/recipe/{recipe_id}/sentiment
      → Aggregated thumbs up/down counts with optional user vote
"""

import logging
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.db.supabase_client import get_supabase

logger = logging.getLogger("plately.feedback")

router = APIRouter(tags=["Feedback"])

# ── Allowed feedback types ───────────────────────────────────────
ALLOWED_FEEDBACK_TYPES = {
    "recipe_sentiment",
    "translation",
    "content",
    "photo",
    "feature_rating",
}


# ── Request / Response Models ────────────────────────────────────
class FeedbackSubmission(BaseModel):
    recipe_id: str
    user_id: str
    feedback_type: str
    rating: int = Field(..., description="1 = thumbs up / positive, -1 = thumbs down / negative, or a numeric score")
    comment: Optional[str] = None
    locale: str = "en"
    meta_data: Optional[dict] = None


# ── POST  /api/v1/feedback/submit ────────────────────────────────
@router.post("/api/v1/feedback/submit")
async def submit_feedback(body: FeedbackSubmission):
    """
    Submit recipe feedback.

    For ``recipe_sentiment`` feedback, existing sentiment from the same
    user on the same recipe is updated (upsert) instead of creating a
    duplicate row.  All other feedback types are inserted as new rows.
    """
    # 1. Validate feedback_type
    if body.feedback_type not in ALLOWED_FEEDBACK_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid feedback_type '{body.feedback_type}'. "
                   f"Must be one of: {', '.join(sorted(ALLOWED_FEEDBACK_TYPES))}",
        )

    try:
        supabase = get_supabase()

        row = {
            "recipe_id": body.recipe_id,
            "user_id": body.user_id,
            "feedback_type": body.feedback_type,
            "rating": body.rating,
            "comment": body.comment,
            "locale": body.locale,
            "meta_data": body.meta_data or {},
        }

        # 2. Upsert logic for recipe_sentiment
        if body.feedback_type == "recipe_sentiment":
            existing = (
                supabase.from_("recipe_feedback")
                .select("id")
                .eq("recipe_id", body.recipe_id)
                .eq("user_id", body.user_id)
                .eq("feedback_type", "recipe_sentiment")
                .execute()
            )

            if existing.data:
                # Update existing sentiment row
                feedback_id = existing.data[0]["id"]
                supabase.from_("recipe_feedback").update({
                    "rating": body.rating,
                    "comment": body.comment,
                    "locale": body.locale,
                    "meta_data": body.meta_data or {},
                }).eq("id", feedback_id).execute()

                logger.info(
                    "[Feedback] Updated sentiment %s for recipe %s by user %s",
                    feedback_id, body.recipe_id, body.user_id,
                )
                return {
                    "status": "success",
                    "data": {"feedback_id": feedback_id},
                }

        # 3. Insert new feedback row
        response = (
            supabase.from_("recipe_feedback")
            .insert(row)
            .execute()
        )

        feedback_id = response.data[0]["id"]
        logger.info(
            "[Feedback] Inserted %s feedback %s for recipe %s",
            body.feedback_type, feedback_id, body.recipe_id,
        )

        return {
            "status": "success",
            "data": {"feedback_id": feedback_id},
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("[Feedback] Failed to submit feedback: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


# ── GET  /api/v1/feedback/recipe/{recipe_id}/sentiment ───────────
@router.get("/api/v1/feedback/recipe/{recipe_id}/sentiment")
async def get_recipe_sentiment(recipe_id: str, user_id: Optional[str] = None):
    """
    Return aggregated thumbs-up / thumbs-down counts for a recipe.

    If ``user_id`` is provided, the response also includes the user's
    existing vote (``1``, ``-1``, or ``null`` if they haven't voted).
    """
    try:
        supabase = get_supabase()

        # Fetch all sentiment rows for this recipe
        response = (
            supabase.from_("recipe_feedback")
            .select("rating, user_id")
            .eq("recipe_id", recipe_id)
            .eq("feedback_type", "recipe_sentiment")
            .execute()
        )

        rows = response.data or []

        likes = sum(1 for r in rows if r["rating"] == 1)
        dislikes = sum(1 for r in rows if r["rating"] == -1)

        # Determine the requesting user's vote (if any)
        user_vote = None
        if user_id:
            for r in rows:
                if r["user_id"] == user_id:
                    user_vote = r["rating"]
                    break

        return {
            "status": "success",
            "data": {
                "likes": likes,
                "dislikes": dislikes,
                "user_vote": user_vote,
            },
        }

    except Exception as e:
        logger.error("[Feedback] Failed to get sentiment for recipe %s: %s", recipe_id, e)
        raise HTTPException(status_code=500, detail=str(e))

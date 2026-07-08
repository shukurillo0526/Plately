"""
Plately — Server-Side Recipe Recommendation Router
=====================================================
Provides a single endpoint that returns pre-scored, pre-tiered recipes.
Replaces the client-side scoring logic in cook_screen.dart with a
server-computed response, dramatically reducing data transfer and
ensuring consistent scoring across all platforms.
"""

import logging
from fastapi import APIRouter, HTTPException, Query
from typing import Optional

from app.core.auth import CurrentUser, require_user_id
from app.core.security import raise_internal_error
from app.services.recommendation_engine import RecommendationEngine

logger = logging.getLogger("plately.recommendations")

router = APIRouter()


@router.get("/api/v1/recommendations/{user_id}")
async def get_recommendations(
    user_id: str,
    current: CurrentUser,
    max_per_tier: int = Query(default=10, ge=1, le=50),
    include_tier5: bool = Query(default=True),
    cuisine_filter: Optional[str] = Query(default=None),
):
    """
    Get personalized recipe recommendations for a user.
    
    Returns recipes organized into 5 tiers with 6-signal composite scores:
    - Tier 1: Perfect Match + Comfort (100% ingredients, cooked before)
    - Tier 2: Perfect Match + Discovery (100% ingredients, never cooked)
    - Tier 3: Almost + Comfort (missing 1-3, cooked before)
    - Tier 4: Almost + Discovery (missing 1-3, never cooked)
    - Tier 5: Explore (semantic search by flavor profile)
    
    Each recipe includes: relevance_score, match_percentage, missing_ingredients,
    expiry_urgency, flavor_affinity, and is_comfort flags.
    """
    require_user_id(current, user_id)
    try:
        engine = RecommendationEngine()
        result = await engine.generate(
            user_id=user_id,
            max_per_tier=max_per_tier,
            include_tier5=include_tier5,
        )
        
        # Convert to serializable format
        tiers_data = {}
        for tier_num, recipes in result.tiers.items():
            tier_recipes = []
            for r in recipes:
                recipe_dict = {
                    "recipe_id": r.recipe_id,
                    "title": r.title,
                    "tier": r.tier.value,
                    "relevance_score": r.relevance_score,
                    "match_percentage": r.match_percentage,
                    "missing_ingredients": r.missing_ingredients,
                    "expiry_urgency": r.expiry_urgency,
                    "flavor_affinity": r.flavor_affinity,
                    "is_comfort": r.is_comfort,
                    "image_url": r.image_url,
                    "cuisine": r.cuisine,
                    "prep_time_minutes": r.prep_time_minutes,
                }
                
                # Apply cuisine filter if specified
                if cuisine_filter and recipe_dict.get("cuisine"):
                    if cuisine_filter.lower() not in recipe_dict["cuisine"].lower():
                        continue
                
                tier_recipes.append(recipe_dict)
            
            tiers_data[str(tier_num)] = tier_recipes
        
        urgent_data = [
            {
                "ingredient_name": u.ingredient_name,
                "days_remaining": u.days_remaining,
                "quantity": u.quantity,
                "unit": u.unit,
            }
            for u in result.urgent_items
        ]
        
        return {
            "status": "success",
            "data": {
                "user_id": result.user_id,
                "generated_at": result.generated_at,
                "tiers": tiers_data,
                "urgent_items": urgent_data,
                "total_recipes": result.total_recipes,
            }
        }
        
    except Exception as e:
        raise_internal_error(logger, f"[Recommendations] Failed for user {user_id}", e)

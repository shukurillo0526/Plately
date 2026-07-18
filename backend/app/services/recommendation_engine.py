"""
Plately — 5-Tier Recommendation Engine
=========================================
The heart of the application. Classifies recipes into 5 tiers
and scores them using the composite Relevance Score.

Tier 1: 100% Inventory Match + Comfort Food (cooked before)
Tier 2: 100% Inventory Match + Discovery (never cooked)
Tier 3: Missing 1-3 items  + Comfort Food
Tier 4: Missing 1-3 items  + Discovery
Tier 5: Semantic search by user flavor profile (pgvector)
"""

from datetime import date, datetime, timedelta
import logging
from app.db.supabase_client import get_supabase
from app.models.recommendation import (
    Tier,
    ScoredRecipe,
    UrgentItem,
    RecommendationResponse,
)
from app.services.scoring import (
    compute_expiry_urgency,
    compute_flavor_affinity,
    compute_relevance_score,
)

logger = logging.getLogger("plately.recommendation")

# --- NOTE: Tier classification now uses safe Supabase ORM queries ---
# The old raw SQL with string interpolation has been removed to prevent
# SQL injection attacks. See _execute_tier_query() below.

# --- SQL: Get user inventory expiry map ---
INVENTORY_EXPIRY_QUERY = """
SELECT ingredient_id, computed_expiry
FROM inventory_items
WHERE user_id = '{user_id}'
  AND computed_expiry >= CURRENT_DATE
  AND quantity > 0
"""

# --- SQL: Get urgent items (expiring in 2 days) ---
URGENT_ITEMS_QUERY = """
SELECT
    ing.display_name_en AS ingredient_name,
    inv.computed_expiry,
    inv.quantity,
    inv.unit,
    (inv.computed_expiry - CURRENT_DATE) AS days_remaining
FROM inventory_items inv
JOIN ingredients ing ON ing.id = inv.ingredient_id
WHERE inv.user_id = '{user_id}'
  AND inv.computed_expiry <= CURRENT_DATE + INTERVAL '2 days'
  AND inv.computed_expiry >= CURRENT_DATE
  AND inv.quantity > 0
ORDER BY inv.computed_expiry ASC
"""

# --- SQL: Get user flavor profile ---
FLAVOR_PROFILE_QUERY = """
SELECT sweet, salty, sour, bitter, umami, spicy
FROM user_flavor_profile
WHERE user_id = '{user_id}'
"""

# --- SQL: Get recipe ingredient IDs (for expiry scoring) ---
RECIPE_INGREDIENTS_QUERY = """
SELECT ingredient_id::TEXT
FROM recipe_ingredients
WHERE recipe_id = '{recipe_id}'
  AND is_optional = FALSE
"""


class RecommendationEngine:
    """
    Orchestrates the full 5-Tier recommendation pipeline.

    Usage (as a FastAPI dependency):
        @router.post("/recommend")
        async def recommend(engine: RecommendationEngine = Depends()):
            return await engine.generate(user_id="...")
    """

    def __init__(self):
        pass

    async def generate(
        self,
        user_id: str,
        max_per_tier: int = 10,
        include_tier5: bool = True,
    ) -> RecommendationResponse:
        """Run the full 5-Tier pipeline with 6-signal scoring."""

        # 1. Load user context
        flavor_profile = await self._get_flavor_profile(user_id)
        inventory_expiry = await self._get_inventory_expiry_map(user_id)
        urgent_items = await self._get_urgent_items(user_id)
        
        # 1b. Load recency data (last-cooked dates per recipe)
        recency_map = await self._get_recency_map(user_id)
        
        # 1c. Load user skill level (default: 2 = intermediate)
        user_skill = await self._get_user_skill_level(user_id)

        # 2. Extract base tier logic (the 5 categories)
        tier_results = await self._execute_tier_query(user_id)

        # 3. Score each recipe with 6-signal composite
        tiers: dict[int, list[ScoredRecipe]] = {1: [], 2: [], 3: [], 4: [], 5: []}

        for row in tier_results:
            tier_num = row.get("tier")
            if tier_num is None:
                continue

            recipe_id = str(row["recipe_id"])

            # Get recipe ingredient IDs for expiry scoring
            recipe_ing_ids = await self._get_recipe_ingredient_ids(recipe_id)

            # Compute sub-scores
            expiry_urg = compute_expiry_urgency(recipe_ing_ids, inventory_expiry)
            flavor_aff = compute_flavor_affinity(
                row.get("flavor_vectors") or {},
                flavor_profile,
            )
            
            # Enhanced: pass all 6 signals to scoring function
            relevance = compute_relevance_score(
                expiry_urgency=expiry_urg,
                flavor_affinity=flavor_aff,
                is_comfort=row["is_comfort"],
                match_percentage=float(row["match_pct"]),
                recipe_difficulty=row.get("difficulty", 1) or 1,
                user_skill_level=user_skill,
                last_cooked_date=recency_map.get(recipe_id),
            )

            scored = ScoredRecipe(
                recipe_id=recipe_id,
                title=row["title"],
                tier=Tier(tier_num),
                relevance_score=relevance,
                match_percentage=float(row["match_pct"]),
                missing_ingredients=row.get("missing_names") or [],
                expiry_urgency=expiry_urg,
                flavor_affinity=flavor_aff,
                is_comfort=row["is_comfort"],
                image_url=row.get("image_url"),
                cuisine=row.get("cuisine"),
                prep_time_minutes=row.get("prep_time_minutes"),
            )
            tiers[tier_num].append(scored)

        # 4. Sort each tier by relevance score (descending) and cap
        for tier_num in tiers:
            tiers[tier_num] = sorted(
                tiers[tier_num], key=lambda r: r.relevance_score, reverse=True
            )[:max_per_tier]

        # 5. Tier 5: Semantic search (if enabled and Tiers 1-4 are sparse)
        if include_tier5:
            total_1_to_4 = sum(len(v) for k, v in tiers.items() if k <= 4)
            if total_1_to_4 < 5:
                tiers[5] = await self._tier5_search(flavor_profile, max_per_tier)

        total = sum(len(v) for v in tiers.values())

        return RecommendationResponse(
            user_id=user_id,
            generated_at=datetime.utcnow().isoformat(),
            tiers=tiers,
            urgent_items=urgent_items,
            total_recipes=total,
        )

    # --- Private helpers ---

    async def _execute_tier_query(self, user_id: str) -> list[dict]:
        """Execute tier classification using safe parameterized RPC.
        
        Uses the get_recommended_recipes RPC with bind parameters instead
        of raw SQL string interpolation (prevents SQL injection).
        Falls back to safe ORM-based queries if RPC is unavailable.
        """
        import re
        # Validate user_id is a valid UUID to prevent any injection
        if not re.match(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', user_id, re.IGNORECASE):
            logger.warning(f"[Recommendation] Invalid user_id format: {user_id}")
            return []
        
        try:
            # Try parameterized RPC first (safe)
            result = await (await get_supabase()).rpc(
                "get_tier_recommendations",
                {"p_user_id": user_id}
            ).execute()
            if result.data:
                return result.data
        except Exception as e:
            logger.warning(f"[Recommendation] RPC unavailable, using ORM fallback: {e}")
        
        # Safe ORM fallback — uses Supabase query builder (no raw SQL)
        try:
            # 1. Get user's valid inventory
            inv_result = await (
                (await get_supabase()).table("inventory_items")
                .select("ingredient_id")
                .eq("user_id", user_id)
                .gte("computed_expiry", date.today().isoformat())
                .gt("quantity", 0)
                .execute()
            )
            owned_ids = {r["ingredient_id"] for r in (inv_result.data or [])}
            
            # 2. Get user cooking history
            hist_result = await (
                (await get_supabase()).table("user_recipe_history")
                .select("recipe_id")
                .eq("user_id", user_id)
                .execute()
            )
            cooked_ids = {r["recipe_id"] for r in (hist_result.data or [])}
            
            # 3. Get all recipes with ingredients
            recipes_result = await (
                (await get_supabase()).table("recipes")
                .select("id, title, cuisine, prep_time_minutes, image_url, flavor_vectors, recipe_ingredients(ingredient_id, is_optional, ingredients(display_name_en))")
                .limit(200)
                .execute()
            )
            
            rows = []
            for recipe in (recipes_result.data or []):
                ri_list = recipe.get("recipe_ingredients") or []
                required = [r for r in ri_list if not r.get("is_optional", False)]
                total = len(required)
                if total == 0:
                    continue
                
                matched = sum(1 for r in required if r["ingredient_id"] in owned_ids)
                missing = total - matched
                match_pct = round(matched / total, 2)
                
                if missing > 3:
                    continue  # Skip recipes missing too many ingredients
                
                missing_names = [
                    (r.get("ingredients") or {}).get("display_name_en", "unknown")
                    for r in required if r["ingredient_id"] not in owned_ids
                ]
                
                is_comfort = recipe["id"] in cooked_ids
                
                # Assign tier
                if match_pct == 1.0 and is_comfort:
                    tier = 1
                elif match_pct == 1.0:
                    tier = 2
                elif 1 <= missing <= 3 and is_comfort:
                    tier = 3
                elif 1 <= missing <= 3:
                    tier = 4
                else:
                    continue
                
                rows.append({
                    "recipe_id": recipe["id"],
                    "title": recipe["title"],
                    "cuisine": recipe.get("cuisine"),
                    "prep_time_minutes": recipe.get("prep_time_minutes"),
                    "image_url": recipe.get("image_url"),
                    "flavor_vectors": recipe.get("flavor_vectors"),
                    "match_pct": match_pct,
                    "missing_count": missing,
                    "missing_names": missing_names,
                    "is_comfort": is_comfort,
                    "tier": tier,
                })
            
            rows.sort(key=lambda r: (r["tier"], -r["match_pct"]))
            return rows
            
        except Exception as e:
            logger.error(f"[Recommendation] ORM fallback failed: {e}")
            return []

    async def _get_recipe_ingredient_ids(self, recipe_id: str) -> list[str]:
        """Get required ingredient IDs for a specific recipe."""
        result = await (
            (await get_supabase()).table("recipe_ingredients")
            .select("ingredient_id")
            .eq("recipe_id", recipe_id)
            .eq("is_optional", False)
            .execute()
        )
        return [row["ingredient_id"] for row in (result.data or [])]

    async def _get_inventory_expiry_map(self, user_id: str) -> dict[str, date]:
        """Build a {ingredient_id: expiry_date} map for the user's inventory."""
        result = await (
            (await get_supabase()).table("inventory_items")
            .select("ingredient_id, computed_expiry")
            .eq("user_id", user_id)
            .gte("computed_expiry", date.today().isoformat())
            .gt("quantity", 0)
            .execute()
        )
        expiry_map: dict[str, date] = {}
        for row in result.data or []:
            ing_id = row["ingredient_id"]
            exp = date.fromisoformat(row["computed_expiry"])
            # Keep the soonest expiry if multiple entries exist
            if ing_id not in expiry_map or exp < expiry_map[ing_id]:
                expiry_map[ing_id] = exp
        return expiry_map

    async def _get_urgent_items(self, user_id: str) -> list[UrgentItem]:
        """Get items expiring within 2 days.
        
        Fixed: Previously used .lte(today) which only returned items
        expiring exactly today. Now correctly uses today + 2 days.
        Fixed: Eliminated N+1 query by joining ingredients table.
        """
        two_days_ahead = (date.today() + timedelta(days=2)).isoformat()
        result = await (
            (await get_supabase()).table("inventory_items")
            .select("ingredient_id, computed_expiry, quantity, unit, ingredients(display_name_en)")
            .eq("user_id", user_id)
            .gte("computed_expiry", date.today().isoformat())
            .lte("computed_expiry", two_days_ahead)
            .gt("quantity", 0)
            .order("computed_expiry", desc=False)
            .execute()
        )
        items: list[UrgentItem] = []
        for row in result.data or []:
            ing_data = row.get("ingredients") or {}
            days_rem = (date.fromisoformat(row["computed_expiry"]) - date.today()).days
            items.append(
                UrgentItem(
                    ingredient_name=ing_data.get("display_name_en", "Unknown"),
                    days_remaining=days_rem,
                    quantity=float(row["quantity"]),
                    unit=row["unit"],
                )
            )
        return items

    async def _get_flavor_profile(self, user_id: str) -> dict[str, float]:
        """Get user's learned flavor profile, or return neutral defaults."""
        result = await (
            (await get_supabase()).table("user_flavor_profile")
            .select("sweet, salty, sour, bitter, umami, spicy")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        if result.data:
            return {
                "sweet": float(result.data["sweet"]),
                "salty": float(result.data["salty"]),
                "sour": float(result.data["sour"]),
                "bitter": float(result.data["bitter"]),
                "umami": float(result.data["umami"]),
                "spicy": float(result.data["spicy"]),
            }
        # Neutral profile for new users
        return {"sweet": 0.5, "salty": 0.5, "sour": 0.5, "bitter": 0.5, "umami": 0.5, "spicy": 0.5}

    async def _get_recency_map(self, user_id: str) -> dict[str, date]:
        """Get last-cooked dates per recipe for the recency penalty signal.
        
        Returns {recipe_id: last_cooked_date} mapping. Only fetches recipes
        cooked in the last 30 days (older ones get no penalty anyway).
        """
        thirty_days_ago = (date.today() - timedelta(days=30)).isoformat()
        try:
            result = await (
                (await get_supabase()).table("user_recipe_history")
                .select("recipe_id, cooked_at")
                .eq("user_id", user_id)
                .gte("cooked_at", thirty_days_ago)
                .order("cooked_at", desc=True)
                .execute()
            )
            recency: dict[str, date] = {}
            for row in result.data or []:
                rid = str(row["recipe_id"])
                if rid not in recency:  # Keep the most recent cook date
                    cooked_str = row["cooked_at"]
                    # Handle both date-only and datetime strings
                    recency[rid] = date.fromisoformat(cooked_str[:10])
            return recency
        except Exception as e:
            logger.warning(f"[Recommendation] Recency map fetch failed: {e}")
            return {}

    async def _get_user_skill_level(self, user_id: str) -> int:
        """Get user's cooking skill level (1-5, default 2).
        
        Reads from user_flavor_profile.skill_level if the column exists,
        otherwise falls back to estimating from cooking history count.
        """
        try:
            # Try explicit skill_level column first
            result = await (
                (await get_supabase()).table("user_flavor_profile")
                .select("skill_level")
                .eq("user_id", user_id)
                .maybe_single()
                .execute()
            )
            if result.data and result.data.get("skill_level") is not None:
                return int(result.data["skill_level"])
        except Exception:
            pass  # Column may not exist yet
        
        # Fallback: estimate from cooking history count
        try:
            result = await (
                (await get_supabase()).table("user_recipe_history")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .execute()
            )
            cook_count = result.count or 0
            if cook_count >= 50:
                return 4  # Experienced
            elif cook_count >= 20:
                return 3  # Intermediate
            elif cook_count >= 5:
                return 2  # Beginner+
            else:
                return 1  # Novice
        except Exception as e:
            logger.warning(f"[Recommendation] Skill level fetch failed: {e}")
            return 2  # Safe default

    async def _tier5_search(
        self, flavor_profile: dict[str, float], limit: int
    ) -> list[ScoredRecipe]:
        """Tier 5: Semantic search using pgvector flavor similarity."""
        query_vector = [
            flavor_profile.get(axis, 0.5)
            for axis in ["sweet", "salty", "sour", "bitter", "umami", "spicy"]
        ]
        result = await (await get_supabase()).rpc(
            "search_recipes_by_flavor",
            {"query_embedding": query_vector, "dietary_filter": [], "match_count": limit},
        ).execute()

        recipes: list[ScoredRecipe] = []
        for row in result.data or []:
            recipes.append(
                ScoredRecipe(
                    recipe_id=str(row["recipe_id"]),
                    title=row["title"],
                    tier=Tier.GLOBAL_SEARCH,
                    relevance_score=round(float(row.get("similarity", 0.5)), 3),
                    match_percentage=0.0,
                    flavor_affinity=round(float(row.get("similarity", 0.5)), 3),
                    is_comfort=False,
                )
            )
        return recipes

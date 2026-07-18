-- ============================================================
-- Plately — Recipe Recommendation Engine RPC
-- ============================================================
-- Weighted matching system:
-- 40% Inventory Match (user owns the ingredient)
-- 30% User Preference (static 0.5 placeholder for pgvector)
-- 30% Expiry Urgency (bonus for recipes using ingredients expiring within 3 days)
--
-- Fixed: references `ingredients` table (not `master_ingredients`)
-- Fixed: uses `computed_expiry` column (not `expiry_date`)
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_recommended_recipes(
    p_user_id UUID,
    p_limit   INT DEFAULT 20
)
RETURNS TABLE (
    recipe_id   UUID,
    title       TEXT,
    match_score NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH UserInventory AS (
        SELECT
            i.ingredient_id,
            ing.category,
            i.computed_expiry
        FROM public.inventory_items i
        JOIN public.ingredients ing ON i.ingredient_id = ing.id
        WHERE i.user_id = p_user_id AND i.quantity > 0
    ),
    RecipeScores AS (
        SELECT
            r.id,
            r.title,
            -- Inventory Match Score: what fraction of recipe ingredients does the user own?
            (
                SELECT COALESCE(
                    COUNT(ri.ingredient_id)::NUMERIC /
                    NULLIF((SELECT COUNT(*) FROM public.recipe_ingredients ri2 WHERE ri2.recipe_id = r.id), 0),
                    0
                )
                FROM public.recipe_ingredients ri
                WHERE ri.recipe_id = r.id
                  AND ri.ingredient_id IN (SELECT ui.ingredient_id FROM UserInventory ui)
            ) AS inventory_match,
            -- Expiry Urgency Score: what fraction uses ingredients expiring within 3 days?
            (
                SELECT COALESCE(
                    COUNT(ri.ingredient_id)::NUMERIC /
                    NULLIF((SELECT COUNT(*) FROM public.recipe_ingredients ri3 WHERE ri3.recipe_id = r.id), 0),
                    0
                )
                FROM public.recipe_ingredients ri
                JOIN UserInventory ui ON ri.ingredient_id = ui.ingredient_id
                WHERE ri.recipe_id = r.id
                  AND ui.computed_expiry <= CURRENT_DATE + INTERVAL '3 days'
            ) AS expiry_urgency
        FROM public.recipes r
    )
    SELECT
        rs.id AS recipe_id,
        rs.title,
        -- Weighted Final Score
        ROUND(
            (rs.inventory_match * 0.40) +
            (0.50 * 0.30) +  -- Preference placeholder
            (rs.expiry_urgency * 0.30)
        , 2) AS match_score
    FROM RecipeScores rs
    ORDER BY match_score DESC
    LIMIT p_limit;
END;
$$;

-- Migration 022: Backend Hardening for Concurrency and Optimization

-- 1. Create jobs table for asynchronous background processing
CREATE TABLE IF NOT EXISTS public.async_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed
    payload JSONB DEFAULT '{}'::jsonb,
    result JSONB,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

ALTER TABLE public.async_jobs ENABLE ROW LEVEL SECURITY;

-- Only service role can access jobs.
CREATE POLICY "Service Role Full Access" ON public.async_jobs
    USING (auth.role() = 'service_role');


-- Index for worker polling
CREATE INDEX IF NOT EXISTS idx_async_jobs_status ON public.async_jobs(status, created_at);

-- 2. Constraints to prevent bad data
ALTER TABLE public.inventory_items 
ADD CONSTRAINT check_positive_quantity CHECK (quantity >= 0);

-- 3. Atomic RPCs for shared resources
-- Inventory Consumption: prevents race conditions where multiple requests try to consume the last portion simultaneously
CREATE OR REPLACE FUNCTION consume_inventory_portion(p_item_id UUID, p_amount FLOAT)
RETURNS TABLE (new_quantity FLOAT, is_empty BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_quantity FLOAT;
BEGIN
    -- Select FOR UPDATE locks the row, ensuring no other transaction can read/modify it simultaneously
    SELECT quantity INTO v_current_quantity 
    FROM public.inventory_items 
    WHERE id = p_item_id 
    FOR UPDATE;

    IF v_current_quantity < p_amount THEN
        RAISE EXCEPTION 'Not enough quantity available';
    END IF;

    -- Update atomically
    UPDATE public.inventory_items
    SET quantity = quantity - p_amount
    WHERE id = p_item_id;

    -- Auto-delete if empty
    IF v_current_quantity - p_amount <= 0 THEN
        DELETE FROM public.inventory_items WHERE id = p_item_id;
        RETURN QUERY SELECT 0::FLOAT, TRUE;
    ELSE
        RETURN QUERY SELECT (v_current_quantity - p_amount), FALSE;
    END IF;
END;
$$;

-- 4. Batch RPC for consuming recipe ingredients atomically
CREATE OR REPLACE FUNCTION consume_recipe_ingredients_batch(
    p_user_id UUID,
    p_recipe_id UUID,
    p_scale FLOAT,
    p_skipped_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_skipped JSONB := '[]'::jsonb;
    v_consumed JSONB := '[]'::jsonb;
    r RECORD;
    v_inv RECORD;
    v_actual_deduct FLOAT;
BEGIN
    -- Loop through recipe ingredients
    FOR r IN 
        SELECT ri.ingredient_id, ri.quantity, i.display_name_en as name
        FROM public.recipe_ingredients ri
        JOIN public.ingredients i ON i.id = ri.ingredient_id
        WHERE ri.recipe_id = p_recipe_id
    LOOP
        IF r.ingredient_id = ANY(p_skipped_ids) THEN
            v_skipped := v_skipped || jsonb_build_object('ingredient_id', r.ingredient_id, 'name', r.name, 'reason', 'user_skipped');
            CONTINUE;
        END IF;

        -- Find inventory item for update
        SELECT id, quantity INTO v_inv
        FROM public.inventory_items
        WHERE user_id = p_user_id AND ingredient_id = r.ingredient_id AND quantity > 0
        LIMIT 1
        FOR UPDATE;

        IF NOT FOUND THEN
            v_skipped := v_skipped || jsonb_build_object('ingredient_id', r.ingredient_id, 'name', r.name, 'reason', 'not_in_inventory');
            CONTINUE;
        END IF;

        v_actual_deduct := LEAST(r.quantity * p_scale, v_inv.quantity);
        IF v_actual_deduct > 0 THEN
            PERFORM consume_inventory_portion(v_inv.id, v_actual_deduct::INT);
            v_consumed := v_consumed || jsonb_build_object('ingredient_id', r.ingredient_id, 'name', r.name, 'deducted', v_actual_deduct);
        END IF;
    END LOOP;

    RETURN jsonb_build_object('consumed', v_consumed, 'skipped', v_skipped);
END;
$$;

-- 5. Leaderboard View to fix N+1 queries
CREATE OR REPLACE VIEW public.v_squad_leaderboard AS
SELECT 
    sm.squad_id,
    u.id as user_id,
    u.display_name as name,
    u.avatar_url,
    gs.xp_points as total_xp,
    gs.level,
    gs.current_cooking_streak,
    gs.items_saved
FROM public.squad_members sm
JOIN public.users u ON sm.user_id = u.id
JOIN public.gamification_stats gs ON gs.user_id = u.id;

-- 6. Indexes for N+1 Queries and Optimizations
CREATE INDEX IF NOT EXISTS idx_gamification_user_xp ON public.gamification_stats(user_id, xp_points);
CREATE INDEX IF NOT EXISTS idx_analytics_events_name_time ON public.analytics_events(event_name, created_at);
CREATE INDEX IF NOT EXISTS idx_inventory_expiry ON public.inventory_items(user_id, computed_expiry);

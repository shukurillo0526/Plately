-- Migration 020: Bulk Cooking & Leftover Storage RPC Enhancement
-- =============================================================
-- Updates process_meal_prep to accept p_container_label and p_storage_zone,
-- properly inserting container_label, location ('fridge'|'freezer'),
-- and dynamically setting computed_expiry based on storage zone.

CREATE OR REPLACE FUNCTION public.process_meal_prep(
    p_user_id           UUID,
    p_recipe_id         UUID,
    p_recipe_title      TEXT,
    p_portions_cooked   INT,
    p_portions_eaten    INT,
    p_ingredients       JSONB,       -- [{ingredient_id, quantity_per_portion, unit}]
    p_cal_per_portion   REAL,
    p_protein_per_portion REAL,
    p_carbs_per_portion REAL,
    p_fat_per_portion   REAL,
    p_leftover_ingredient_id UUID DEFAULT NULL,
    p_container_label   TEXT DEFAULT NULL,
    p_storage_zone      TEXT DEFAULT 'fridge'
) RETURNS JSONB AS $$
DECLARE
    ing JSONB;
    total_needed NUMERIC;
    inv_row RECORD;
    portions_remaining INT;
    leftover_id UUID;
    zone_location TEXT;
    expiry_interval INTERVAL;
BEGIN
    -- STEP 1: Deduct raw ingredients
    IF p_ingredients IS NOT NULL AND jsonb_array_length(p_ingredients) > 0 THEN
        FOR ing IN SELECT * FROM jsonb_array_elements(p_ingredients)
        LOOP
            total_needed := (ing->>'quantity_per_portion')::NUMERIC * p_portions_cooked;
            
            -- Find user's inventory for this ingredient, ordered by expiry
            FOR inv_row IN
                SELECT id, quantity FROM public.inventory_items
                WHERE user_id = p_user_id
                  AND ingredient_id = (ing->>'ingredient_id')::UUID
                  AND is_cooked_leftover = FALSE
                ORDER BY computed_expiry ASC NULLS LAST
            LOOP
                IF total_needed <= 0 THEN EXIT; END IF;
                
                IF inv_row.quantity <= total_needed THEN
                    total_needed := total_needed - inv_row.quantity;
                    DELETE FROM public.inventory_items WHERE id = inv_row.id;
                ELSE
                    UPDATE public.inventory_items 
                    SET quantity = quantity - total_needed, 
                        updated_at = NOW()
                    WHERE id = inv_row.id;
                    total_needed := 0;
                END IF;
            END LOOP;
        END LOOP;
    END IF;

    -- STEP 2: Log consumed macros (if portions eaten now > 0)
    IF p_portions_eaten > 0 THEN
        INSERT INTO public.nutrition_logs (
            user_id, meal_type, food_items, 
            total_calories, total_protein_g, total_carbs_g, total_fat_g, 
            notes
        ) VALUES (
            p_user_id,
            'cooked',
            jsonb_build_array(jsonb_build_object(
                'name', p_recipe_title,
                'portions', p_portions_eaten,
                'calories_per_portion', p_cal_per_portion
            )),
            (p_cal_per_portion * p_portions_eaten)::INT,
            p_protein_per_portion * p_portions_eaten,
            p_carbs_per_portion * p_portions_eaten,
            p_fat_per_portion * p_portions_eaten,
            format('Cooked %s portions of %s, ate %s', p_portions_cooked, p_recipe_title, p_portions_eaten)
        );
    END IF;

    -- Determine storage zone and expiry
    IF LOWER(COALESCE(p_storage_zone, 'fridge')) = 'freezer' THEN
        zone_location := 'freezer';
        expiry_interval := INTERVAL '30 days';
    ELSE
        zone_location := 'fridge';
        expiry_interval := INTERVAL '4 days';
    END IF;

    -- STEP 3: Create cooked leftover item (if portions remaining > 0)
    portions_remaining := p_portions_cooked - p_portions_eaten;
    IF portions_remaining > 0 THEN
        INSERT INTO public.inventory_items (
            user_id, ingredient_id, quantity, unit, item_state, location, source,
            is_cooked_leftover, parent_recipe_id, parent_recipe_title,
            portions_count, calories_per_portion, protein_per_portion,
            carbs_per_portion, fat_per_portion, date_cooked, computed_expiry,
            container_label
        ) VALUES (
            p_user_id,
            COALESCE(p_leftover_ingredient_id, (SELECT id FROM public.ingredients WHERE canonical_name = 'cooked_meal' LIMIT 1), gen_random_uuid()),
            portions_remaining,
            'portion',
            'sealed',
            zone_location,
            'cooked',
            TRUE,
            p_recipe_id,
            p_recipe_title,
            portions_remaining,
            p_cal_per_portion,
            p_protein_per_portion,
            p_carbs_per_portion,
            p_fat_per_portion,
            NOW(),
            NOW() + expiry_interval,
            p_container_label
        ) RETURNING id INTO leftover_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'portions_eaten', p_portions_eaten,
        'portions_stored', portions_remaining,
        'leftover_id', leftover_id,
        'calories_logged', (p_cal_per_portion * p_portions_eaten)::INT,
        'container_label', p_container_label,
        'storage_zone', zone_location
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Description: Schema additions and RPC functions for Cook & Store Leftovers workflow

-- 1. Extend inventory_items table for leftover items
ALTER TABLE public.inventory_items
    ADD COLUMN IF NOT EXISTS is_cooked_leftover  BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS parent_recipe_id    UUID REFERENCES public.recipes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS parent_recipe_title TEXT,
    ADD COLUMN IF NOT EXISTS portions_count      INT DEFAULT 1,
    ADD COLUMN IF NOT EXISTS calories_per_portion REAL,
    ADD COLUMN IF NOT EXISTS protein_per_portion  REAL,
    ADD COLUMN IF NOT EXISTS carbs_per_portion    REAL,
    ADD COLUMN IF NOT EXISTS fat_per_portion      REAL,
    ADD COLUMN IF NOT EXISTS date_cooked         TIMESTAMPTZ;

-- 2. Seed cooked_meal dictionary item if not exists
INSERT INTO public.ingredients (canonical_name, display_name_en, display_name_uz, display_name_ru, display_name_ko, category, default_unit, sealed_shelf_life_days)
VALUES ('cooked_meal', 'Cooked Meal', 'Pishirilgan taom', 'Готовое блюдо', '조리된 음식', 'prepared', 'portion', 4)
ON CONFLICT (canonical_name) DO NOTHING;

-- 3. Atomic process_meal_prep transaction
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
    p_leftover_ingredient_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    ing JSONB;
    total_needed NUMERIC;
    inv_row RECORD;
    portions_remaining INT;
    leftover_id UUID;
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

    -- STEP 3: Create cooked leftover item (if portions remaining > 0)
    portions_remaining := p_portions_cooked - p_portions_eaten;
    IF portions_remaining > 0 THEN
        INSERT INTO public.inventory_items (
            user_id, ingredient_id, quantity, unit, item_state, location, source,
            is_cooked_leftover, parent_recipe_id, parent_recipe_title,
            portions_count, calories_per_portion, protein_per_portion,
            carbs_per_portion, fat_per_portion, date_cooked, computed_expiry
        ) VALUES (
            p_user_id,
            COALESCE(p_leftover_ingredient_id, (SELECT id FROM public.ingredients WHERE canonical_name = 'cooked_meal' LIMIT 1), gen_random_uuid()),
            portions_remaining,
            'portion',
            'sealed',
            'fridge',
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
            NOW() + INTERVAL '4 days'
        ) RETURNING id INTO leftover_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'portions_eaten', p_portions_eaten,
        'portions_stored', portions_remaining,
        'leftover_id', leftover_id,
        'calories_logged', (p_cal_per_portion * p_portions_eaten)::INT
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Atomic eat_leftover_portion transaction
CREATE OR REPLACE FUNCTION public.eat_leftover_portion(
    p_user_id      UUID,
    p_inventory_id UUID
) RETURNS JSONB AS $$
DECLARE
    item RECORD;
BEGIN
    SELECT * INTO item FROM public.inventory_items
    WHERE id = p_inventory_id AND user_id = p_user_id AND is_cooked_leftover = TRUE;

    IF NOT FOUND OR item.portions_count <= 0 THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Leftover not found or empty');
    END IF;

    -- Log 1 portion of macros to the diary
    INSERT INTO public.nutrition_logs (
        user_id, meal_type, food_items, 
        total_calories, total_protein_g, total_carbs_g, total_fat_g, 
        notes
    ) VALUES (
        p_user_id, 
        'leftover',
        jsonb_build_array(jsonb_build_object(
            'name', COALESCE(item.parent_recipe_title, 'Leftover Meal'), 
            'portions', 1
        )),
        COALESCE(item.calories_per_portion, 0)::INT,
        COALESCE(item.protein_per_portion, 0),
        COALESCE(item.carbs_per_portion, 0),
        COALESCE(item.fat_per_portion, 0),
        format('Ate 1 portion of %s leftover', COALESCE(item.parent_recipe_title, 'meal'))
    );

    -- Decrement count or delete if it was the last portion
    IF item.portions_count = 1 THEN
        DELETE FROM public.inventory_items WHERE id = p_inventory_id;
    ELSE
        UPDATE public.inventory_items
        SET portions_count = portions_count - 1,
            quantity = quantity - 1,
            updated_at = NOW()
        WHERE id = p_inventory_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'portions_remaining', GREATEST(item.portions_count - 1, 0),
        'calories_logged', COALESCE(item.calories_per_portion, 0)::INT
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Enhanced consume_inventory_item RPC for raw ingredient macro logging
DROP FUNCTION IF EXISTS public.consume_inventory_item(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION public.consume_inventory_item(
    p_inventory_id UUID,
    p_qty_to_consume NUMERIC
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_ingredient_id UUID;
    v_unit TEXT;
    v_name TEXT;
    v_avg_weight NUMERIC;
    v_cal_100g INT;
    v_prot_100g NUMERIC;
    v_fat_100g NUMERIC;
    v_carbs_100g NUMERIC;
    v_weight_g NUMERIC;
    v_total_calories INT;
    v_total_protein REAL;
    v_total_carbs REAL;
    v_total_fat REAL;
BEGIN
    -- 1. Fetch item details
    SELECT user_id, ingredient_id, unit INTO v_user_id, v_ingredient_id, v_unit
    FROM public.inventory_items WHERE id = p_inventory_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- 2. Fetch ingredient details
    SELECT display_name_en, avg_weight_grams, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g
    INTO v_name, v_avg_weight, v_cal_100g, v_prot_100g, v_fat_100g, v_carbs_100g
    FROM public.ingredients WHERE id = v_ingredient_id;

    -- 3. Calculate weight consumed in grams
    IF LOWER(v_unit) = 'g' THEN
        v_weight_g := p_qty_to_consume;
    ELSIF LOWER(v_unit) = 'kg' THEN
        v_weight_g := p_qty_to_consume * 1000.0;
    ELSIF LOWER(v_unit) = 'ml' OR LOWER(v_unit) = 'l' THEN
        -- Assume density ~ 1 for liquids
        IF LOWER(v_unit) = 'l' THEN
            v_weight_g := p_qty_to_consume * 1000.0;
        ELSE
            v_weight_g := p_qty_to_consume;
        END IF;
    ELSE
        -- Default to piece/pcs using avg_weight_grams
        v_weight_g := p_qty_to_consume * COALESCE(v_avg_weight, 100.0);
    END IF;

    -- 4. Calculate total macros if nutrition columns are present
    IF v_cal_100g IS NOT NULL OR v_prot_100g IS NOT NULL OR v_carbs_100g IS NOT NULL OR v_fat_100g IS NOT NULL THEN
        v_total_calories := ROUND(COALESCE(v_cal_100g, 0) / 100.0 * v_weight_g);
        v_total_protein  := COALESCE(v_prot_100g, 0) / 100.0 * v_weight_g;
        v_total_carbs    := COALESCE(v_carbs_100g, 0) / 100.0 * v_weight_g;
        v_total_fat      := COALESCE(v_fat_100g, 0) / 100.0 * v_weight_g;

        -- Only log if calories or macros are greater than zero
        IF v_total_calories > 0 OR v_total_protein > 0 OR v_total_carbs > 0 OR v_total_fat > 0 THEN
            INSERT INTO public.nutrition_logs (user_id, meal_type, food_items, total_calories, total_protein_g, total_carbs_g, total_fat_g, notes)
            VALUES (
                v_user_id,
                'snack',
                jsonb_build_array(jsonb_build_object(
                    'name', v_name,
                    'quantity', p_qty_to_consume,
                    'unit', v_unit,
                    'weight_g', v_weight_g
                )),
                v_total_calories,
                v_total_protein,
                v_total_carbs,
                v_total_fat,
                format('Ate raw %s %s of %s (%s grams)', p_qty_to_consume, v_unit, v_name, ROUND(v_weight_g, 1))
            );
        END IF;
    END IF;

    -- 5. Decrement the quantity securely (prevents negative values)
    UPDATE public.inventory_items
    SET quantity = GREATEST(0, quantity - p_qty_to_consume),
        updated_at = NOW()
    WHERE id = p_inventory_id;
    
    -- 6. Cleanup: Delete immediately if quantity hit 0
    DELETE FROM public.inventory_items 
    WHERE id = p_inventory_id AND quantity <= 0;
END;
$$;

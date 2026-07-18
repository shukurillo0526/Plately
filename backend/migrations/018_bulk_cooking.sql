-- Migration 018: Bulk Cooking Support
-- =====================================
-- Adds meal prep planning tables, container tracking on inventory items,
-- and prep session stats on gamification_stats.

-- 1. New table: meal_prep_plans
CREATE TABLE IF NOT EXISTS meal_prep_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  days INT NOT NULL DEFAULT 5,
  meals_per_day INT NOT NULL DEFAULT 3,
  target_calories_per_meal INT,
  target_protein_g REAL,
  target_carbs_g REAL,
  target_fat_g REAL,
  cuisine_preference TEXT,
  status TEXT NOT NULL DEFAULT 'planned',   -- planned | in_progress | completed | abandoned
  total_prep_time_minutes INT,
  actual_prep_time_minutes INT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE meal_prep_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own plans" ON meal_prep_plans;
CREATE POLICY "Users manage own plans" ON meal_prep_plans
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_meal_prep_plans_user
  ON meal_prep_plans(user_id, created_at DESC);


-- 2. New table: prep_plan_recipes
CREATE TABLE IF NOT EXISTS prep_plan_recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES meal_prep_plans(id) ON DELETE CASCADE,
  recipe_id UUID REFERENCES recipes(id),
  recipe_data JSONB NOT NULL,
  portions_target INT NOT NULL DEFAULT 4,
  portions_cooked INT DEFAULT 0,
  cook_order INT NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',    -- pending | cooking | cooked | skipped
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE prep_plan_recipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own plan recipes" ON prep_plan_recipes;
CREATE POLICY "Users manage own plan recipes" ON prep_plan_recipes
  FOR ALL USING (
    plan_id IN (SELECT id FROM meal_prep_plans WHERE user_id = auth.uid())
  );

CREATE INDEX IF NOT EXISTS idx_prep_plan_recipes_plan
  ON prep_plan_recipes(plan_id, cook_order);


-- 3. New columns on inventory_items for container tracking
ALTER TABLE inventory_items
  ADD COLUMN IF NOT EXISTS container_label TEXT,
  ADD COLUMN IF NOT EXISTS prep_plan_id UUID REFERENCES meal_prep_plans(id);


-- 4. New columns on gamification_stats for prep tracking
ALTER TABLE gamification_stats
  ADD COLUMN IF NOT EXISTS total_prep_sessions INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_prepped_meals INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_prep_minutes INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS prepped_meals_consumed INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS current_prep_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS best_prep_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_prep_date DATE;

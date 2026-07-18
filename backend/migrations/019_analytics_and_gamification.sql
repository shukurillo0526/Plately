-- 019_analytics_and_gamification.sql
-- Analytics Events and Gamification Tables

-- 1. Analytics Events Table
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    properties JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own events and read their own events
CREATE POLICY "analytics_owner" ON public.analytics_events
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 2. User Badges Table
CREATE TABLE IF NOT EXISTS public.user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    badge_id TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (user_id, badge_id)
);

-- Enable RLS
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- Allow users to see their own badges
CREATE POLICY "badges_owner" ON public.user_badges
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 3. Update gamification_stats table
ALTER TABLE public.gamification_stats
  ADD COLUMN IF NOT EXISTS current_cooking_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS best_cooking_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_cooking_date DATE,
  
  ADD COLUMN IF NOT EXISTS current_waste_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS best_waste_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_waste_save_date DATE,
  
  ADD COLUMN IF NOT EXISTS current_health_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS best_health_streak INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_health_log_date DATE;

-- Note: current_prep_streak, best_prep_streak, and last_prep_date 
-- were already added in 018_bulk_cooking.sql

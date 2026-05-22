-- Migration: 015_recipe_feedback_system.sql
-- Description: Creates the recipe_feedback table for tracking translation, recipe content, photo, and feature feedback, with thumbs up/down and feature ratings.

CREATE TABLE IF NOT EXISTS public.recipe_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE,
    user_id UUID,
    feedback_type TEXT NOT NULL, -- 'translation', 'content', 'photo', 'feature_rating', 'recipe_sentiment'
    rating NUMERIC,             -- 1-5 score for features, or 1 (up) / -1 (down) for recipe sentiment
    comment TEXT,
    locale TEXT NOT NULL,
    meta_data JSONB,            -- logs device configuration, step index, image url, etc.
    status TEXT DEFAULT 'pending', -- 'pending', 'auto_fixed', 'reviewed', 'ignored'
    action_taken TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.recipe_feedback ENABLE ROW LEVEL SECURITY;

-- Allow anonymous and authenticated insertions
CREATE POLICY "Allow anon insert feedback" ON public.recipe_feedback
    FOR INSERT WITH CHECK (true);

-- Allow authenticated reads or admin reads
CREATE POLICY "Allow select feedback" ON public.recipe_feedback
    FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════════════
-- Migration: 017_fix_supabase_rls_advisories.sql
-- Description: Resolves Supabase Security Advisor CRITICAL warnings
--              by enabling Row Level Security (RLS) on public tables.
-- ═══════════════════════════════════════════════════════════════════

-- 1. Fix CRITICAL: RLS Disabled on public.video_feeds
-- Enable RLS so arbitrary callers with anon key cannot INSERT/UPDATE/DELETE videos
ALTER TABLE public.video_feeds ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow public read active video_feeds" ON public.video_feeds;

-- Allow read-only access for active videos
CREATE POLICY "Allow public read active video_feeds"
  ON public.video_feeds
  FOR SELECT
  USING (is_active = true);

-- Note: INSERT / UPDATE / DELETE are denied by default under RLS
-- unless using the service_role key (which bypasses RLS safely from backend).


-- 2. Note on public.spatial_ref_sys (PostGIS metadata table):
-- In Supabase, spatial_ref_sys is owned by the internal supabase_admin superuser.
-- Attempting 'ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;' returns
-- ERROR 42501 (must be owner of table spatial_ref_sys).
-- This is a known Supabase platform false positive; you can safely dismiss/ignore
-- the spatial_ref_sys advisory in the Supabase Security Advisor dashboard.

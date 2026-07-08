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


-- 2. Fix CRITICAL: RLS Disabled on public.spatial_ref_sys (PostGIS metadata)
-- Enable RLS on spatial_ref_sys to clear the Supabase Security Advisor warning
ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read spatial_ref_sys" ON public.spatial_ref_sys;

CREATE POLICY "Allow public read spatial_ref_sys"
  ON public.spatial_ref_sys
  FOR SELECT
  USING (true);

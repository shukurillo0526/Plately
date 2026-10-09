-- Migration 022: Public Branches and App Explore Content Integration
-- ===================================================================
-- Allows public read access to active branches, website configs, and
-- enables seamless content publishing from Workshop into Plately App Explore.

-- 1. Ensure template column exists on restaurant_website_configs
ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS template JSONB;

-- 2. Ensure public read policy on branches (active only)
DROP POLICY IF EXISTS "Public can view active branches" ON branches;
CREATE POLICY "Public can view active branches" ON branches
FOR SELECT USING (is_active = true);

-- 3. Ensure public read policy on restaurant_website_configs
DROP POLICY IF EXISTS "Public can view website configs" ON restaurant_website_configs;
CREATE POLICY "Public can view website configs" ON restaurant_website_configs
FOR SELECT USING (is_published = true OR true);

-- 4. Ensure public read policies for video_feeds and posts
DROP POLICY IF EXISTS "Public can view active video feeds" ON video_feeds;
CREATE POLICY "Public can view active video feeds" ON video_feeds
FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Public can view public posts" ON posts;
CREATE POLICY "Public can view public posts" ON posts
FOR SELECT USING (visibility = 'public');

-- 5. Ensure public read policy on stories (non-expired)
DROP POLICY IF EXISTS "Public can view active stories" ON stories;
CREATE POLICY "Public can view active stories" ON stories
FOR SELECT USING (expires_at > now());

-- 6. Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_posts_restaurant_id ON posts(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_video_feeds_restaurant_id ON video_feeds(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_branches_restaurant_active ON branches(restaurant_id, is_active);

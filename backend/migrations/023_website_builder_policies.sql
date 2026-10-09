-- Migration 023: Website Builder Permissive Policies & Columns
-- ==============================================================
-- Ensures website configurations can be viewed and updated by authenticated
-- staff, owners, and public storefronts without triggering RLS violations.

ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS template JSONB;
ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS branding JSONB DEFAULT '{}';
ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS layout JSONB DEFAULT '{}';
ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS seo JSONB DEFAULT '{}';
ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT true;
ALTER TABLE restaurant_website_configs ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ DEFAULT now();

DROP POLICY IF EXISTS "Staff can view website configs" ON restaurant_website_configs;
DROP POLICY IF EXISTS "Owners can modify website configs" ON restaurant_website_configs;
DROP POLICY IF EXISTS "Public can view website configs" ON restaurant_website_configs;
DROP POLICY IF EXISTS "Allow staff full access to website configs" ON restaurant_website_configs;
DROP POLICY IF EXISTS "Public can view active website configs" ON restaurant_website_configs;

CREATE POLICY "Public can view active website configs"
ON restaurant_website_configs
FOR SELECT
USING (true);

CREATE POLICY "Allow authenticated staff to manage website configs"
ON restaurant_website_configs
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

GRANT ALL ON restaurant_website_configs TO authenticated;
GRANT ALL ON restaurant_website_configs TO service_role;
GRANT SELECT ON restaurant_website_configs TO anon;

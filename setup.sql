-- ============================================
-- Utopia Dashboard: Run this in Supabase SQL Editor
-- Database: Utopia Internal (ippkrnjcmntcmrryfybr)
-- ============================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS dashboard_projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'live', 'abandoned')),
  type TEXT NOT NULL DEFAULT 'others' CHECK (type IN ('internal_software', 'saas_software', 'landing_page', 'others')),
  live_url TEXT,
  thumbnail_url TEXT,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS with full open access (no auth needed)
ALTER TABLE dashboard_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all access" ON dashboard_projects
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 3. Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_dashboard_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_dashboard_updated_at
  BEFORE UPDATE ON dashboard_projects
  FOR EACH ROW
  EXECUTE FUNCTION update_dashboard_updated_at();

-- 4. Seed with existing projects
INSERT INTO dashboard_projects (name, description, status, type, live_url, created_by) VALUES
  ('BankMatch', 'AI-powered bank reconciliation for Malaysian SMEs. OCR scan payment slips and auto-match transactions.', 'live', 'saas_software', 'https://recon-x-eight.vercel.app', 'CY'),
  ('AutoViral', 'AI social media content generator and scheduler. Create viral posts across platforms.', 'live', 'saas_software', 'https://autopost-web-amber.vercel.app', 'CY'),
  ('AutoRank', 'Automated SEO ranking tracker and optimizer for Google Business Profiles.', 'live', 'saas_software', 'https://autorank-ivory.vercel.app', 'CY'),
  ('RecurPay', 'Recurring payment and subscription management platform for Malaysian businesses.', 'live', 'saas_software', 'https://repay-phi.vercel.app', 'CY'),
  ('GBP Tracker', 'Google Business Profile performance tracker. Monitor rankings and reviews.', 'live', 'internal_software', 'https://utopia-gbp-tracker.vercel.app', 'CY'),
  ('Recruit', 'Internal recruitment and hiring pipeline management tool.', 'live', 'internal_software', 'https://utopia-recruit.vercel.app', 'CY'),
  ('Utopia Group', 'Corporate landing page for Utopia Ventures — AI implementation for Malaysian businesses.', 'live', 'landing_page', 'https://utopia-group.vercel.app', 'CY'),
  ('Khind RTO', 'Return-to-office admin portal for Khind.', 'in_progress', 'internal_software', NULL, 'CY'),
  ('Utopia Landing Engine', 'High-converting landing page redesign system and framework.', 'live', 'internal_software', NULL, 'CY'),
  ('Utopia Marketing Engine', 'Automated marketing content generation tool.', 'live', 'internal_software', NULL, 'CY'),
  ('Brain Viewer', 'BRAIN.md visualization and browsing tool.', 'live', 'internal_software', NULL, 'CY'),
  ('Reno.my', 'Home services marketplace landing page for Malaysia.', 'in_progress', 'landing_page', NULL, 'CY'),
  ('Claude Skill Hub', 'Directory and manager for custom Claude Code skills.', 'live', 'internal_software', NULL, 'CY'),
  ('Utopia Brain', 'Self-improving project intelligence and knowledge base system.', 'live', 'others', NULL, 'CY');
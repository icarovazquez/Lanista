-- Migration 082: Feature flags + coach waitlist
-- Adds app_config table (remote feature flags) and coach_waitlist table.
-- coach_access_enabled starts false — coach signup is waitlisted until flipped.

-- ── app_config ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_config (
  id                    INTEGER PRIMARY KEY DEFAULT 1,         -- single-row table
  coach_access_enabled  BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT single_row CHECK (id = 1)
);

-- Seed the single config row
INSERT INTO app_config (id, coach_access_enabled)
VALUES (1, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Public read-only access (no auth required — app reads this before login)
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_config_public_read"
  ON app_config FOR SELECT
  USING (true);

-- ── coach_waitlist ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS coach_waitlist (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name  TEXT NOT NULL,
  last_name   TEXT NOT NULL,
  email       TEXT NOT NULL,
  school      TEXT,
  division    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Anyone can insert (no auth needed — coach hasn't signed up yet)
ALTER TABLE coach_waitlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "coach_waitlist_public_insert"
  ON coach_waitlist FOR INSERT
  WITH CHECK (true);

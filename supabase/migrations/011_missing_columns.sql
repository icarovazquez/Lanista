-- 011 · Missing columns referenced in Flutter app but absent from schema

-- users: onboarding_complete flag (set true after profile wizard finishes)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE;

-- players: missing columns referenced by player_profile_setup_page
ALTER TABLE players
  ADD COLUMN IF NOT EXISTS primary_position    TEXT,
  ADD COLUMN IF NOT EXISTS secondary_position  TEXT,
  ADD COLUMN IF NOT EXISTS preferred_foot      TEXT,
  ADD COLUMN IF NOT EXISTS height_cm           INTEGER,
  ADD COLUMN IF NOT EXISTS club_name           TEXT,
  ADD COLUMN IF NOT EXISTS league              TEXT,
  ADD COLUMN IF NOT EXISTS gpa                 NUMERIC(3,2),
  ADD COLUMN IF NOT EXISTS sat_score           INTEGER,
  ADD COLUMN IF NOT EXISTS act_score           INTEGER,
  ADD COLUMN IF NOT EXISTS target_divisions    TEXT[],
  ADD COLUMN IF NOT EXISTS bio                 TEXT,
  ADD COLUMN IF NOT EXISTS bio_es              TEXT,
  ADD COLUMN IF NOT EXISTS graduation_year     INTEGER;

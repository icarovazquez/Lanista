-- 015 · Add columns needed by the tactical blueprint onboarding wizard
-- The coaches table uses UUID FKs to formations/positions tables which are
-- not yet seeded. We add denormalized TEXT columns so the wizard can save
-- without requiring FK lookups, matching the same pattern as migration 011.

-- Coaches: add missing onboarding columns
ALTER TABLE coaches
  ADD COLUMN IF NOT EXISTS primary_formation      TEXT,
  ADD COLUMN IF NOT EXISTS playing_styles         TEXT[],
  ADD COLUMN IF NOT EXISTS recruiting_class_years TEXT[],
  ADD COLUMN IF NOT EXISTS recruiting_notes       TEXT,
  ADD COLUMN IF NOT EXISTS onboarding_complete    BOOLEAN NOT NULL DEFAULT FALSE;

-- Also add onboarding_complete to users for coaches (already exists from 011
-- but added IF NOT EXISTS to be safe)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE;

-- Coach position requirements: add TEXT columns for position/qualities
-- since the position_id FK references an unseeded positions table.
-- We keep the existing table and add soft columns.
ALTER TABLE coach_position_requirements
  ADD COLUMN IF NOT EXISTS position_key       TEXT,   -- e.g. 'gk', 'cb', 'st'
  ADD COLUMN IF NOT EXISTS required_qualities TEXT[]; -- array of quality ids

-- Drop the NOT NULL FK constraints that block inserts from the wizard.
-- We'll re-add proper FK seeding in a later migration.
ALTER TABLE coach_position_requirements
  ALTER COLUMN formation_id DROP NOT NULL,
  ALTER COLUMN position_id  DROP NOT NULL;

-- Roster slots: the wizard sends graduation_year and needs_recruit toggle.
-- needs_recruit is a GENERATED column so we can't insert it.
-- Add graduation_year as alias and position_key TEXT.
ALTER TABLE roster_slots
  ADD COLUMN IF NOT EXISTS graduation_year INTEGER,
  ADD COLUMN IF NOT EXISTS position_key    TEXT;   -- e.g. 'gk', 'cb'

-- Drop NOT NULL on position_id and academic_year so wizard inserts work
ALTER TABLE roster_slots
  ALTER COLUMN position_id   DROP NOT NULL,
  ALTER COLUMN academic_year DROP NOT NULL;

-- Fix coaches RLS: add WITH CHECK so INSERT works (same issue as players)
DROP POLICY IF EXISTS "coaches_own_profile" ON coaches;
CREATE POLICY "coaches_own_profile"
  ON coaches FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Fix coach_position_requirements RLS INSERT
DROP POLICY IF EXISTS "coach_req_own" ON coach_position_requirements;
CREATE POLICY "coach_req_own"
  ON coach_position_requirements FOR ALL
  USING (EXISTS (
    SELECT 1 FROM coaches
    WHERE id = coach_position_requirements.coach_id
      AND user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM coaches
    WHERE id = coach_position_requirements.coach_id
      AND user_id = auth.uid()
  ));

-- Fix roster_slots RLS INSERT
DROP POLICY IF EXISTS "roster_slots_own" ON roster_slots;
CREATE POLICY "roster_slots_own"
  ON roster_slots FOR ALL
  USING (EXISTS (
    SELECT 1 FROM coaches
    WHERE id = roster_slots.coach_id
      AND user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM coaches
    WHERE id = roster_slots.coach_id
      AND user_id = auth.uid()
  ));

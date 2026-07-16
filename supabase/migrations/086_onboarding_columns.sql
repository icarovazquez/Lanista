-- 086: New columns for redesigned onboarding flow
ALTER TABLE players
  ADD COLUMN IF NOT EXISTS technical_skills  JSONB,
  ADD COLUMN IF NOT EXISTS highlight_url     TEXT,
  ADD COLUMN IF NOT EXISTS grade_level       INTEGER CHECK (grade_level BETWEEN 6 AND 13),
  ADD COLUMN IF NOT EXISTS target_schools    TEXT[];

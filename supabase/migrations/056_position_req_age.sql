-- 056 · Replace grad-year requirements with age requirements
-- Coaches can now specify a minimum and maximum player age per position.

ALTER TABLE coach_position_requirements
  DROP COLUMN IF EXISTS min_grad_year,
  DROP COLUMN IF EXISTS max_grad_year,
  ADD COLUMN IF NOT EXISTS min_age_years  INTEGER,   -- e.g. 18 (minimum age in years)
  ADD COLUMN IF NOT EXISTS max_age_years  INTEGER;   -- e.g. 22 (maximum age in years)

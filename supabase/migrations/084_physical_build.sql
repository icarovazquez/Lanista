-- Migration 084: Add physical build requirement to coach_position_requirements
-- Coaches can specify a minimum physical build per position.
-- Build is derived from a player's height + weight (BMI-based category).
--
-- Values:
--   'any'       — no build requirement (default)
--   'slight_ok' — slight builds accepted (all builds pass)
--   'athletic'  — must be athletic or powerful (BMI >= 21)
--   'powerful'  — must be powerful build (BMI >= 25 for athletes)

ALTER TABLE coach_position_requirements
  ADD COLUMN IF NOT EXISTS min_physical_build TEXT
    NOT NULL DEFAULT 'any'
    CHECK (min_physical_build IN ('any', 'slight_ok', 'athletic', 'powerful'));

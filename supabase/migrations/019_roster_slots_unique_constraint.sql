-- ============================================================
-- Migration 019: Add unique constraint to roster_slots
-- Required for upsert onConflict(coach_id, position_key, graduation_year)
-- ============================================================

ALTER TABLE roster_slots
  ADD CONSTRAINT roster_slots_coach_position_year_key
  UNIQUE (coach_id, position_key, graduation_year);

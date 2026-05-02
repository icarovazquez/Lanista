-- ============================================================
-- Migration 021: Add injury tracking to roster_slots
-- ============================================================

ALTER TABLE roster_slots
  ADD COLUMN IF NOT EXISTS is_injured       BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS injury_return_date DATE;

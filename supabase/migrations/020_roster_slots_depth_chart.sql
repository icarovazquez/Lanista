-- ============================================================
-- Migration 020: Roster slots depth chart support
-- Replaces single-player-per-position model with a depth chart
-- allowing multiple players per position per year (e.g. 3 GKs).
-- ============================================================

-- Drop the single-slot unique constraint from migration 019
ALTER TABLE roster_slots
  DROP CONSTRAINT IF EXISTS roster_slots_coach_position_year_key;

-- Add depth_order: 1 = starter, 2 = backup, 3 = third string, etc.
-- Capped at 4 per position per year to stay within NCAA roster norms.
ALTER TABLE roster_slots
  ADD COLUMN IF NOT EXISTS depth_order INTEGER NOT NULL DEFAULT 1;

-- New unique constraint including depth_order
ALTER TABLE roster_slots
  ADD CONSTRAINT roster_slots_depth_key
  UNIQUE (coach_id, position_key, graduation_year, depth_order);

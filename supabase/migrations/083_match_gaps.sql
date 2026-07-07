-- Migration 083: Add match_gaps columns to player_coach_matches
-- match_gaps / match_gaps_es store the plain-English reasons a player
-- does NOT fully match a program — the "what's holding you back" explanation.

ALTER TABLE player_coach_matches
  ADD COLUMN IF NOT EXISTS match_gaps    JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS match_gaps_es JSONB NOT NULL DEFAULT '[]'::jsonb;

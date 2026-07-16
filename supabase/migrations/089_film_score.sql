-- Migration 089: Add film_score to player_coach_matches
-- Populated by the matching engine when a player has analysis_result set.
-- Weight in total_score: up to 15 points (scout_rating + projection alignment).

ALTER TABLE player_coach_matches
  ADD COLUMN IF NOT EXISTS film_score DECIMAL(5,2) NOT NULL DEFAULT 0;

-- 060 · Align player_coach_matches column names with Edge Function + Flutter client
-- ─────────────────────────────────────────────────────────────────────────────
-- The Edge Function (supabase/functions/match-players/index.ts) writes:
--   total_score, last_computed_at
-- The Flutter client (player_matches_page.dart) reads:
--   total_score, last_computed_at
-- But the original schema (migration 006) used:
--   overall_score, computed_at
-- Rename to match what both the Edge Function and client expect.

ALTER TABLE player_coach_matches RENAME COLUMN overall_score TO total_score;
ALTER TABLE player_coach_matches RENAME COLUMN computed_at  TO last_computed_at;

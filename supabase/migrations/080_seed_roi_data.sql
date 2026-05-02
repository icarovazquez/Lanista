-- ── 079: Seed ROI & Player Value data for Coach Daniels (UNC) ────────────────
-- 6 players, 6 different stories, covering every quadrant of the 2×2 matrix.
--
-- Coach Daniels: c3000000-0000-0000-0000-000000000001

-- Add 'signed' to pipeline_stage enum (needed for ROI tracking)
--
--   Kieran Ross     (CF  → FWD) 3 seasons → FOUNDATION  (Elite ROI 88, High Value 82)
--   Trey Johnson    (→ MID)     2 seasons → FOUNDATION  (Strong ROI 75, High Value 73)
--   Emilio Sánchez  (→ DEF)     3 seasons → PROVEN      (Strong ROI 84, graduated)
--   Mason Williams  (→ GK)      2 seasons → DEVELOPING  (Solid ROI 67, High Value 73)
--   Pablo Castillo  (→ FWD)     2 seasons → RECONSIDER  (Poor ROI 36, transferred)
--   Chase Peterson  (→ DEF)     1 season  → RECONSIDER  (Poor ROI 24, never played)

DO $$
DECLARE
  v_coach UUID := 'c3000000-0000-0000-0000-000000000001';

  p_ross     UUID := '51ef304c-4720-4567-b990-a700297da6b1';
  p_johnson  UUID := '0f63de9f-5490-489a-9e72-4d50bc5670d2';
  p_sanchez  UUID := '3a2ac9fa-a875-45c5-88a2-7029ce58a933';
  p_williams UUID := 'b7ed2750-d66c-4629-8fda-da99e0ea5c3b';
  p_castillo UUID := 'c225681a-aab9-4570-824d-cf6c52c3fb38';
  p_peterson UUID := 'f20a55a8-3a78-4875-b25a-7a9952ecb98f';

  pip_ross     UUID;
  pip_johnson  UUID;
  pip_sanchez  UUID;
  pip_williams UUID;
  pip_castillo UUID;
  pip_peterson UUID;
BEGIN

-- ── Step 1: Move all 6 pipeline entries to 'signed' ──────────────────────────

UPDATE recruiting_pipeline SET
  stage = 'signed', roi_tracking_on = TRUE, updated_at = NOW(),
  signed_at = NOW() - INTERVAL '3 years'
WHERE coach_id = v_coach AND player_id = p_ross
RETURNING id INTO pip_ross;

UPDATE recruiting_pipeline SET
  stage = 'signed', roi_tracking_on = TRUE, updated_at = NOW(),
  signed_at = NOW() - INTERVAL '2 years'
WHERE coach_id = v_coach AND player_id = p_johnson
RETURNING id INTO pip_johnson;

UPDATE recruiting_pipeline SET
  stage = 'signed', roi_tracking_on = TRUE, updated_at = NOW(),
  signed_at = NOW() - INTERVAL '3 years'
WHERE coach_id = v_coach AND player_id = p_sanchez
RETURNING id INTO pip_sanchez;

UPDATE recruiting_pipeline SET
  stage = 'signed', roi_tracking_on = TRUE, updated_at = NOW(),
  signed_at = NOW() - INTERVAL '2 years'
WHERE coach_id = v_coach AND player_id = p_williams
RETURNING id INTO pip_williams;

UPDATE recruiting_pipeline SET
  stage = 'signed', roi_tracking_on = TRUE, updated_at = NOW(),
  signed_at = NOW() - INTERVAL '2 years'
WHERE coach_id = v_coach AND player_id = p_castillo
RETURNING id INTO pip_castillo;

UPDATE recruiting_pipeline SET
  stage = 'signed', roi_tracking_on = TRUE, updated_at = NOW(),
  signed_at = NOW() - INTERVAL '1 year'
WHERE coach_id = v_coach AND player_id = p_peterson
RETURNING id INTO pip_peterson;

-- ── Step 2: Season stats ──────────────────────────────────────────────────────

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │ KIERAN ROSS — FWD — FOUNDATION (Elite ROI 88, High Value 82, Portal Risk)
-- │ Immediate starter, program's best striker, flagged portal risk Jr year.
-- └─────────────────────────────────────────────────────────────────────────────
INSERT INTO player_season_stats (
  player_id, coach_id, season_year, academic_year, position_group,
  games_played, games_started, minutes_played, total_games_possible,
  passes_attempted, passes_completed,
  avg_distance_km, max_velocity_kmh,
  goals, assists, shots, shots_on_target, chances_created,
  yellow_cards, red_cards,
  gpa_this_season, credits_on_track,
  season_status, scholarship_type, depth_chart_peak,
  coach_verified, player_verified, entry_method
) VALUES
(p_ross, v_coach, 2023, 'Fr', 'FWD',
 21, 18, 1620, 22, 380, 248, 10.2, 33.4,
 12, 5, 68, 42, 14, 2, 0, 3.40, TRUE,
 'active', 'full', 1, TRUE, TRUE, 'both_verified'),
(p_ross, v_coach, 2024, 'So', 'FWD',
 22, 22, 1980, 22, 412, 276, 10.8, 34.1,
 15, 8, 74, 51, 18, 1, 0, 3.50, TRUE,
 'active', 'full', 1, TRUE, TRUE, 'both_verified'),
(p_ross, v_coach, 2025, 'Jr', 'FWD',
 20, 20, 1800, 22, 394, 261, 10.5, 34.8,
 11, 6, 61, 40, 12, 3, 0, 3.35, TRUE,
 'active', 'full', 1, TRUE, TRUE, 'both_verified');

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │ TREY JOHNSON — MID — FOUNDATION (Strong ROI 75, High Value 73)
-- │ Box-to-box mid, elite progressive actions, growing every season.
-- └─────────────────────────────────────────────────────────────────────────────
INSERT INTO player_season_stats (
  player_id, coach_id, season_year, academic_year, position_group,
  games_played, games_started, minutes_played, total_games_possible,
  passes_attempted, passes_completed,
  progressive_passes, progressive_carries,
  key_passes, chances_created,
  duels_won, duels_attempted,
  avg_distance_km, max_velocity_kmh,
  goals, assists,
  yellow_cards, red_cards,
  gpa_this_season, credits_on_track,
  season_status, scholarship_type, depth_chart_peak,
  coach_verified, player_verified, entry_method
) VALUES
(p_johnson, v_coach, 2024, 'Fr', 'MID',
 20, 14, 1260, 22, 620, 468, 48, 22, 38, 16, 62, 88, 11.4, 30.2,
 4, 8, 3, 0, 3.20, TRUE,
 'active', 'full', 2, TRUE, TRUE, 'both_verified'),
(p_johnson, v_coach, 2025, 'So', 'MID',
 22, 18, 1620, 22, 742, 578, 61, 31, 47, 22, 74, 101, 11.8, 30.9,
 6, 9, 2, 0, 3.25, TRUE,
 'active', 'full', 1, TRUE, TRUE, 'both_verified');

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │ EMILIO SÁNCHEZ — DEF — PROVEN (Strong ROI 84, graduated)
-- │ Backup Fr year, dominant starter So/Jr. Captain. Graduated on time.
-- └─────────────────────────────────────────────────────────────────────────────
INSERT INTO player_season_stats (
  player_id, coach_id, season_year, academic_year, position_group,
  games_played, games_started, minutes_played, total_games_possible,
  passes_attempted, passes_completed,
  progressive_passes, progressive_carries,
  key_passes,
  duels_won, duels_attempted,
  avg_distance_km, max_velocity_kmh,
  goals, assists,
  yellow_cards, red_cards,
  gpa_this_season, credits_on_track,
  season_status, scholarship_type, depth_chart_peak,
  coach_verified, player_verified, entry_method
) VALUES
(p_sanchez, v_coach, 2022, 'Fr', 'DEF',
 14, 8, 720, 22, 480, 374, 28, 12, 18, 44, 62, 10.1, 29.4,
 0, 1, 1, 0, 3.50, TRUE,
 'active', 'partial', 2, TRUE, TRUE, 'both_verified'),
(p_sanchez, v_coach, 2023, 'So', 'DEF',
 22, 22, 1980, 22, 614, 498, 52, 24, 28, 78, 98, 10.8, 30.1,
 1, 2, 2, 0, 3.60, TRUE,
 'active', 'full', 1, TRUE, TRUE, 'both_verified'),
(p_sanchez, v_coach, 2024, 'Jr', 'DEF',
 22, 22, 1980, 22, 642, 531, 58, 28, 32, 84, 102, 11.0, 30.4,
 2, 1, 1, 0, 3.70, TRUE,
 'graduated', 'full', 1, TRUE, TRUE, 'both_verified');

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │ MASON WILLIAMS — GK — DEVELOPING (Solid ROI 67, High Value 73)
-- │ Backup behind a senior Fr year. Took over So year, excellent save %.
-- └─────────────────────────────────────────────────────────────────────────────
INSERT INTO player_season_stats (
  player_id, coach_id, season_year, academic_year, position_group,
  games_played, games_started, minutes_played, total_games_possible,
  passes_attempted, passes_completed,
  avg_distance_km, max_velocity_kmh,
  saves, goals_allowed, clean_sheets,
  yellow_cards, red_cards,
  gpa_this_season, credits_on_track,
  season_status, scholarship_type, depth_chart_peak,
  coach_verified, player_verified, entry_method
) VALUES
(p_williams, v_coach, 2024, 'Fr', 'GK',
 6, 5, 450, 22, 210, 158, 6.2, 22.1,
 18, 8, 2, 0, 0, 3.10, TRUE,
 'active', 'partial', 2, TRUE, TRUE, 'both_verified'),
(p_williams, v_coach, 2025, 'So', 'GK',
 22, 20, 1800, 22, 398, 302, 6.8, 23.4,
 74, 22, 9, 1, 0, 3.20, TRUE,
 'active', 'full', 1, TRUE, TRUE, 'both_verified');

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │ PABLO CASTILLO — FWD — RECONSIDER (Poor ROI 36, transferred)
-- │ Hyped recruit, never delivered. Entered portal after So year. A miss.
-- └─────────────────────────────────────────────────────────────────────────────
INSERT INTO player_season_stats (
  player_id, coach_id, season_year, academic_year, position_group,
  games_played, games_started, minutes_played, total_games_possible,
  passes_attempted, passes_completed,
  avg_distance_km, max_velocity_kmh,
  goals, assists, shots, shots_on_target, chances_created,
  yellow_cards, red_cards,
  gpa_this_season, credits_on_track,
  season_status, scholarship_type, depth_chart_peak,
  coach_verified, player_verified, entry_method
) VALUES
(p_castillo, v_coach, 2023, 'Fr', 'FWD',
 14, 6, 540, 22, 198, 122, 9.1, 31.2,
 2, 1, 22, 9, 4, 3, 0, 2.80, TRUE,
 'active', 'full', 3, TRUE, FALSE, 'coach_manual'),
(p_castillo, v_coach, 2024, 'So', 'FWD',
 15, 8, 720, 22, 224, 141, 9.3, 31.8,
 1, 1, 18, 7, 3, 4, 1, 2.70, FALSE,
 'transfer_portal_end', 'full', 3, TRUE, FALSE, 'coach_manual');

-- ┌─────────────────────────────────────────────────────────────────────────────
-- │ CHASE PETERSON — DEF — RECONSIDER (Poor ROI 24, never played)
-- │ Walk-on recruited on potential. Never cracked the lineup. Sr year, no impact.
-- └─────────────────────────────────────────────────────────────────────────────
INSERT INTO player_season_stats (
  player_id, coach_id, season_year, academic_year, position_group,
  games_played, games_started, minutes_played, total_games_possible,
  passes_attempted, passes_completed,
  progressive_passes, progressive_carries,
  key_passes,
  duels_won, duels_attempted,
  avg_distance_km, max_velocity_kmh,
  goals, assists,
  yellow_cards, red_cards,
  gpa_this_season, credits_on_track,
  season_status, scholarship_type, depth_chart_peak,
  coach_verified, player_verified, entry_method
) VALUES
(p_peterson, v_coach, 2025, 'Sr', 'DEF',
 8, 2, 180, 22, 88, 58, 6, 2, 4, 11, 22, 8.2, 26.1,
 0, 0, 1, 0, 3.30, TRUE,
 'never_played', 'walk_on', 4, TRUE, FALSE, 'coach_manual');

-- ── Step 3: player_roi_records — pre-computed scores ─────────────────────────

INSERT INTO player_roi_records (
  pipeline_id, player_id, coach_id,
  position_recruited_for, signed_season_year, scholarship_type, target_graduation_year,
  roi_utilization, roi_production, roi_retention, roi_academics, roi_score,
  value_performance, value_scarcity, value_eligibility, value_replaceability, value_score,
  retention_quadrant, portal_risk, portal_risk_flagged_at,
  total_seasons_tracked, total_minutes_played, career_status, last_computed_at
) VALUES
-- KIERAN ROSS: FOUNDATION — fight hard
(pip_ross,     p_ross,     v_coach, 'cf',  2023, 'full',    2026, 91.0, 88.0, 85.0, 85.0, 88.0, 90.0, 80.0, 50.0, 60.0, 82.0, 'foundation', TRUE,  NOW()-INTERVAL '2 weeks', 3, 5400, 'active',     NOW()),
-- TREY JOHNSON: FOUNDATION
(pip_johnson,  p_johnson,  v_coach, 'cm',  2024, 'full',    2027, 72.0, 74.0, 85.0, 81.0, 75.3, 76.0, 72.0, 75.0, 55.0, 72.7, 'foundation', FALSE, NULL,                     2, 2880, 'active',     NOW()),
-- EMILIO SÁNCHEZ: PROVEN — graduated, reference class
(pip_sanchez,  p_sanchez,  v_coach, 'cb',  2022, 'full',    2025, 82.0, 76.0,100.0, 90.0, 83.5,  0.0,  0.0,  0.0,  0.0,  0.0, 'proven',     FALSE, NULL,                     3, 4680, 'graduated',  NOW()),
-- MASON WILLIAMS: DEVELOPING — ROI still building, high current value
(pip_williams, p_williams, v_coach, 'gk',  2024, 'partial', 2027, 58.0, 64.0, 85.0, 78.0, 67.0, 74.0, 88.0, 75.0, 45.0, 73.4, 'developing', FALSE, NULL,                     2, 2250, 'active',     NOW()),
-- PABLO CASTILLO: RECONSIDER — transferred, a miss
(pip_castillo, p_castillo, v_coach, 'st',  2023, 'full',    2026, 31.0, 27.0, 30.0, 70.0, 36.0,  0.0,  0.0,  0.0,  0.0,  0.0, 'reconsider', FALSE, NULL,                     2, 1260, 'transferred',NOW()),
-- CHASE PETERSON: RECONSIDER — never played
(pip_peterson, p_peterson, v_coach, 'cb',  2025, 'walk_on', 2026,  8.0, 14.0, 20.0, 82.0, 24.0,  8.0, 20.0, 25.0, 80.0, 25.2, 'reconsider', FALSE, NULL,                     1,  180, 'active',     NOW());

END $$;

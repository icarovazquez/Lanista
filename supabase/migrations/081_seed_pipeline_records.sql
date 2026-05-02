-- ── 081: Seed recruiting_pipeline records for Coach Daniels ──────────────────
--
-- Migration 080 tried to UPDATE pipeline rows that didn't exist yet.
-- This migration INSERTs them properly.
--
-- Coach Daniels (UNC): c3000000-0000-0000-0000-000000000001
--
-- Signed (6 ROI-tracked players, using the UUIDs stored in player_roi_records):
--   Kieran Ross, Trey Johnson, Emilio Sánchez, Mason Williams,
--   Pablo Castillo, Chase Peterson
--
-- Active pipeline (prospects in earlier stages via email lookup):
--   Jaylen Brooks     → evaluated
--   Noah Chen         → offered
--   Santiago Vega     → contacted
--   Elias Okonkwo     → identified
--   Dante Williams    → contacted
--   Victor Castillo   → evaluated

DO $$
DECLARE
  v_coach   UUID := 'c3000000-0000-0000-0000-000000000001';

  -- The 6 ROI-tracked signed players (these UUIDs live in player_roi_records)
  p_ross     UUID := '51ef304c-4720-4567-b990-a700297da6b1';
  p_johnson  UUID := '0f63de9f-5490-489a-9e72-4d50bc5670d2';
  p_sanchez  UUID := '3a2ac9fa-a875-45c5-88a2-7029ce58a933';
  p_williams UUID := 'b7ed2750-d66c-4629-8fda-da99e0ea5c3b';
  p_castillo UUID := 'c225681a-aab9-4570-824d-cf6c52c3fb38';
  p_peterson UUID := 'f20a55a8-3a78-4875-b25a-7a9952ecb98f';

  -- Prospects resolved from seeded users
  p_jaylan    UUID;
  p_noah      UUID;
  p_santiago  UUID;
  p_elias     UUID;
  p_dante     UUID;
  p_victor    UUID;

  -- Pipeline IDs for the ROI rows (needed to back-fill pipeline_id)
  pip_ross     UUID;
  pip_johnson  UUID;
  pip_sanchez  UUID;
  pip_williams UUID;
  pip_castillo UUID;
  pip_peterson UUID;

BEGIN

  -- ── Resolve prospect player IDs by email ───────────────────────────────────
  SELECT pl.id INTO p_jaylan
    FROM players pl JOIN users u ON pl.user_id = u.id
   WHERE u.email = 'jaylen.brooks@lanista.test';

  SELECT pl.id INTO p_noah
    FROM players pl JOIN users u ON pl.user_id = u.id
   WHERE u.email = 'noah.chen@lanista.test';

  SELECT pl.id INTO p_santiago
    FROM players pl JOIN users u ON pl.user_id = u.id
   WHERE u.email = 'santiago.vega@lanista.test';

  SELECT pl.id INTO p_elias
    FROM players pl JOIN users u ON pl.user_id = u.id
   WHERE u.email = 'elias.okonkwo@lanista.test';

  SELECT pl.id INTO p_dante
    FROM players pl JOIN users u ON pl.user_id = u.id
   WHERE u.email = 'dante.williams@lanista.test';

  SELECT pl.id INTO p_victor
    FROM players pl JOIN users u ON pl.user_id = u.id
   WHERE u.email = 'victor.castillo@lanista.test';

  -- ── Signed players (6 ROI-tracked) ────────────────────────────────────────
  INSERT INTO recruiting_pipeline
    (coach_id, player_id, stage, roi_tracking_on, signed_at, notes, created_at, updated_at)
  VALUES
    (v_coach, p_ross,     'signed', TRUE, NOW()-INTERVAL '3 years',
     'Elite striker. 3-season starter. Program cornerstone. Watch portal risk.', NOW()-INTERVAL '3 years', NOW()),
    (v_coach, p_johnson,  'signed', TRUE, NOW()-INTERVAL '2 years',
     'Box-to-box CM. Growing every season. Elite progressive actions.', NOW()-INTERVAL '2 years', NOW()),
    (v_coach, p_sanchez,  'signed', TRUE, NOW()-INTERVAL '3 years',
     'Graduated CB. Strong 3-year career. Model of consistency.', NOW()-INTERVAL '3 years', NOW()),
    (v_coach, p_williams, 'signed', TRUE, NOW()-INTERVAL '2 years',
     'GK on partial scholarship. High value, ROI still building.', NOW()-INTERVAL '2 years', NOW()),
    (v_coach, p_castillo, 'signed', TRUE, NOW()-INTERVAL '2 years',
     'Transferred after So year. Recruiting miss — revisit evaluation criteria.', NOW()-INTERVAL '2 years', NOW()),
    (v_coach, p_peterson, 'signed', TRUE, NOW()-INTERVAL '1 year',
     'Walk-on DEF. Never cracked lineup. Reconsidering walk-on approach.', NOW()-INTERVAL '1 year', NOW())
  ON CONFLICT (coach_id, player_id) DO UPDATE SET
    stage           = EXCLUDED.stage,
    roi_tracking_on = EXCLUDED.roi_tracking_on,
    signed_at       = EXCLUDED.signed_at,
    notes           = EXCLUDED.notes,
    updated_at      = NOW();

  -- Capture the pipeline IDs so we can back-fill player_roi_records.pipeline_id
  SELECT id INTO pip_ross     FROM recruiting_pipeline WHERE coach_id=v_coach AND player_id=p_ross;
  SELECT id INTO pip_johnson  FROM recruiting_pipeline WHERE coach_id=v_coach AND player_id=p_johnson;
  SELECT id INTO pip_sanchez  FROM recruiting_pipeline WHERE coach_id=v_coach AND player_id=p_sanchez;
  SELECT id INTO pip_williams FROM recruiting_pipeline WHERE coach_id=v_coach AND player_id=p_williams;
  SELECT id INTO pip_castillo FROM recruiting_pipeline WHERE coach_id=v_coach AND player_id=p_castillo;
  SELECT id INTO pip_peterson FROM recruiting_pipeline WHERE coach_id=v_coach AND player_id=p_peterson;

  -- Back-fill pipeline_id on the ROI records (was NULL because rows didn't exist yet)
  UPDATE player_roi_records SET pipeline_id = pip_ross     WHERE coach_id=v_coach AND player_id=p_ross;
  UPDATE player_roi_records SET pipeline_id = pip_johnson  WHERE coach_id=v_coach AND player_id=p_johnson;
  UPDATE player_roi_records SET pipeline_id = pip_sanchez  WHERE coach_id=v_coach AND player_id=p_sanchez;
  UPDATE player_roi_records SET pipeline_id = pip_williams WHERE coach_id=v_coach AND player_id=p_williams;
  UPDATE player_roi_records SET pipeline_id = pip_castillo WHERE coach_id=v_coach AND player_id=p_castillo;
  UPDATE player_roi_records SET pipeline_id = pip_peterson WHERE coach_id=v_coach AND player_id=p_peterson;

  -- ── Active prospects (evaluated / offered / contacted / identified) ─────────

  IF p_jaylan IS NOT NULL THEN
    INSERT INTO recruiting_pipeline
      (coach_id, player_id, stage, notes, last_contact, created_at, updated_at)
    VALUES
      (v_coach, p_jaylan, 'evaluated',
       'CB/CDM. Watched twice at Ohio Premier. Excellent aerial ability. Strong GPA.',
       NOW()-INTERVAL '10 days', NOW()-INTERVAL '3 months', NOW())
    ON CONFLICT (coach_id, player_id) DO NOTHING;
  END IF;

  IF p_noah IS NOT NULL THEN
    INSERT INTO recruiting_pipeline
      (coach_id, player_id, stage, notes, last_contact, created_at, updated_at)
    VALUES
      (v_coach, p_noah, 'offered',
       'GK. Scholarship offer extended. 6''2" frame, elite distribution. Needs to decide by Apr 30.',
       NOW()-INTERVAL '3 days', NOW()-INTERVAL '2 months', NOW())
    ON CONFLICT (coach_id, player_id) DO NOTHING;
  END IF;

  IF p_santiago IS NOT NULL THEN
    INSERT INTO recruiting_pipeline
      (coach_id, player_id, stage, notes, last_contact, created_at, updated_at)
    VALUES
      (v_coach, p_santiago, 'contacted',
       'LW. Reached out after MLS Next Fest. Pacey with elite 1v1. GPA concern (2.9).',
       NOW()-INTERVAL '18 days', NOW()-INTERVAL '5 months', NOW())
    ON CONFLICT (coach_id, player_id) DO NOTHING;
  END IF;

  IF p_elias IS NOT NULL THEN
    INSERT INTO recruiting_pipeline
      (coach_id, player_id, stage, notes, last_contact, created_at, updated_at)
    VALUES
      (v_coach, p_elias, 'identified',
       'RB. Flagged from ECNL film. High work rate, overlaps well. Monitoring.',
       NULL, NOW()-INTERVAL '6 weeks', NOW())
    ON CONFLICT (coach_id, player_id) DO NOTHING;
  END IF;

  IF p_dante IS NOT NULL THEN
    INSERT INTO recruiting_pipeline
      (coach_id, player_id, stage, notes, last_contact, created_at, updated_at)
    VALUES
      (v_coach, p_dante, 'contacted',
       'CM. Eclipse Select. Fast-rising 2026 grad. Good progressive actions, needs to see live.',
       NOW()-INTERVAL '7 days', NOW()-INTERVAL '2 months', NOW())
    ON CONFLICT (coach_id, player_id) DO NOTHING;
  END IF;

  IF p_victor IS NOT NULL THEN
    INSERT INTO recruiting_pipeline
      (coach_id, player_id, stage, notes, last_contact, created_at, updated_at)
    VALUES
      (v_coach, p_victor, 'evaluated',
       'GK. Lonestar SC. Tall (6''4"), good with feet. Competing with Noah Chen offer.',
       NOW()-INTERVAL '14 days', NOW()-INTERVAL '6 weeks', NOW())
    ON CONFLICT (coach_id, player_id) DO NOTHING;
  END IF;

END $$;

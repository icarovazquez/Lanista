-- 061 · Seed pre-computed player_coach_matches for test players
-- ─────────────────────────────────────────────────────────────────────────────
-- Populates the Matches tab with realistic demo data without needing to invoke
-- the matching Edge Function. Uses subqueries to resolve player/coach IDs by
-- email so this works regardless of auto-generated UUIDs.
-- Column names aligned with migration 060 (total_score, last_computed_at).

DO $$
DECLARE
  v_kieran_player_id  UUID;
  v_marcus_player_id  UUID;
  v_jaylen_player_id  UUID;
  v_santiago_player_id UUID;
BEGIN
  -- ── Resolve player IDs ─────────────────────────────────────────────────────
  SELECT p.id INTO v_kieran_player_id
    FROM players p JOIN users u ON p.user_id = u.id
   WHERE u.email = 'kieran.ross@lanista.test';

  SELECT p.id INTO v_marcus_player_id
    FROM players p JOIN users u ON p.user_id = u.id
   WHERE u.email = 'marcus.delgado@lanista.test';

  SELECT p.id INTO v_jaylen_player_id
    FROM players p JOIN users u ON p.user_id = u.id
   WHERE u.email = 'jaylen.brooks@lanista.test';

  SELECT p.id INTO v_santiago_player_id
    FROM players p JOIN users u ON p.user_id = u.id
   WHERE u.email = 'santiago.vega@lanista.test';

  -- ── Kieran Ross matches ────────────────────────────────────────────────────
  -- (ST, D1 target, GPA 3.4, grad 2027, 178 cm, MLS NEXT, right foot)
  IF v_kieran_player_id IS NOT NULL THEN

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      89.75, 31.25, 23.50, 18.00, 13.50, 3.50,
      '["Needs a ST in their system", "Perfect graduation year match", "3.5+ GPA — solid academics", "Height within program range", "Actively recruiting Class of 2027"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.daniels@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      84.00, 28.75, 22.00, 17.25, 12.50, 3.50,
      '["Can fill ST as a starter", "Has an open roster slot for this position", "3.5+ GPA — solid academics", "Actively recruiting Class of 2027"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.martinez@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      78.50, 26.25, 21.00, 16.75, 11.50, 3.00,
      '["Needs a ST in their 4-4-2 system", "Height within program range", "Good academic fit"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.osei@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      74.25, 24.50, 19.75, 15.50, 11.00, 3.50,
      '["Can also fill CF as backup", "Actively recruiting Class of 2027", "Height within program range"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.nguyen@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      68.75, 22.75, 18.50, 14.50, 10.50, 2.50,
      '["Position of need: Forward", "Class of 2027 on radar"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.sullivan@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      62.00, 20.50, 17.00, 13.50, 9.00, 2.00,
      '["ST in their preferred formation", "Graduation year fits timeline"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.reid@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      55.50, 18.25, 15.75, 12.00, 8.50, 1.00,
      '["Forward position available", "Height slightly below ideal range"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.patel@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_kieran_player_id, c.id,
      48.25, 16.00, 13.25, 11.00, 7.00, 1.00,
      '["Positional overlap possible", "Different timeline preference"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.foster@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

  END IF;

  -- ── Marcus Delgado matches ─────────────────────────────────────────────────
  IF v_marcus_player_id IS NOT NULL THEN

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_marcus_player_id, c.id,
      91.25, 33.50, 24.00, 18.75, 12.00, 3.00,
      '["Needs a CDM in their system", "4.0 GPA — strong academic profile", "Perfect graduation year match"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.kim@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_marcus_player_id, c.id,
      82.00, 29.75, 22.25, 17.00, 11.00, 2.00,
      '["Can fill CDM or CM", "3.5+ GPA — solid academics", "Has an open roster slot for this position"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.jackson@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_marcus_player_id, c.id,
      71.50, 25.25, 20.00, 15.25, 9.00, 2.00,
      '["Midfield depth needed", "Actively recruiting Class of 2026"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.okafor@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

  END IF;

  -- ── Jaylen Brooks matches ──────────────────────────────────────────────────
  IF v_jaylen_player_id IS NOT NULL THEN

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_jaylen_player_id, c.id,
      86.50, 30.25, 23.00, 17.75, 12.50, 3.00,
      '["Needs a CB in their system", "Height within program range", "3.5+ GPA — solid academics"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.hernandez@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_jaylen_player_id, c.id,
      76.75, 27.00, 21.25, 16.50, 10.00, 2.00,
      '["Can also fill RB as backup", "Actively recruiting Class of 2027"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.walsh@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

  END IF;

  -- ── Santiago Vega matches ──────────────────────────────────────────────────
  IF v_santiago_player_id IS NOT NULL THEN

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_santiago_player_id, c.id,
      93.00, 34.75, 24.50, 19.00, 13.25, 1.50,
      '["4.0 GPA — strong academic profile", "Needs a CAM in their 4-3-3 system", "Perfect graduation year match", "Has an open roster slot for this position"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.ibrahim@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

    INSERT INTO player_coach_matches
      (player_id, coach_id, total_score, tactical_score, position_score,
       physical_score, academic_score, timeline_score, match_reasons,
       last_computed_at, is_active)
    SELECT
      v_santiago_player_id, c.id,
      80.25, 28.50, 22.00, 16.25, 12.00, 1.50,
      '["CAM/CM flexible fit", "3.5+ GPA — solid academics", "Height within program range"]'::jsonb,
      NOW(), true
    FROM coaches c JOIN users u ON c.user_id = u.id
    WHERE u.email = 'coach.chen@lanista.test'
    ON CONFLICT (player_id, coach_id) DO UPDATE SET
      total_score = EXCLUDED.total_score, last_computed_at = NOW();

  END IF;

END $$;

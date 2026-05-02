-- 052 · Filter coach_player_matches() by gender_program
-- ─────────────────────────────────────────────────────────────────────────────
-- A soccer program is either men's or women's.  The existing RPC returned
-- ALL discoverable players regardless of gender.  This migration recreates
-- the function to filter players by the coach's gender_program so:
--   • A men's-program coach (gender_program = 'male')  sees only male players
--   • A women's-program coach (gender_program = 'female') sees only female players
--   • A coach with gender_program IS NULL sees everyone (no filtering)

CREATE OR REPLACE FUNCTION coach_player_matches()
RETURNS TABLE (
  player_user_id       UUID,
  first_name           TEXT,
  last_name            TEXT,
  primary_position     TEXT,
  secondary_position   TEXT,
  graduation_year      INTEGER,
  gpa                  NUMERIC,
  dominant_foot        TEXT,
  club_name            TEXT,
  league               TEXT,
  bio                  TEXT,
  target_divisions     TEXT[],
  height_cm            INTEGER,
  overall_score        NUMERIC,
  match_label          TEXT,
  position_matched     BOOLEAN,
  timeline_matched     BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_coach_id           UUID;
  v_position_keys      TEXT[];
  v_class_years        TEXT[];
  v_min_gpa            NUMERIC;
  v_gender_program     TEXT;   -- 'male' | 'female' | NULL
BEGIN
  -- ── Get the calling coach's profile ────────────────────────────────────────
  SELECT c.id, c.recruiting_class_years, c.min_gpa, c.gender_program
  INTO   v_coach_id, v_class_years, v_min_gpa, v_gender_program
  FROM   coaches c
  WHERE  c.user_id = auth.uid()
  LIMIT  1;

  IF v_coach_id IS NULL THEN
    RETURN; -- not a coach
  END IF;

  -- ── Collect position keys this coach needs ─────────────────────────────────
  SELECT array_agg(DISTINCT cpr.position_key)
  INTO   v_position_keys
  FROM   coach_position_requirements cpr
  WHERE  cpr.coach_id = v_coach_id
    AND  cpr.position_key IS NOT NULL;

  -- ── Return matched players (gender-filtered) ───────────────────────────────
  RETURN QUERY
  SELECT
    p.user_id::UUID                                           AS player_user_id,
    u.first_name::TEXT,
    u.last_name::TEXT,
    p.primary_position::TEXT,
    p.secondary_position::TEXT,
    p.graduation_year,
    p.gpa,
    p.dominant_foot::TEXT,
    p.club_name::TEXT,
    p.league::TEXT,
    p.bio::TEXT,
    p.target_divisions,
    p.height_cm,
    compute_match_score(
      p.primary_position,
      p.secondary_position,
      p.graduation_year,
      p.gpa,
      p.dominant_foot,
      v_position_keys,
      v_class_years,
      v_min_gpa
    )                                                         AS overall_score,
    CASE
      WHEN compute_match_score(
        p.primary_position, p.secondary_position,
        p.graduation_year, p.gpa, p.dominant_foot,
        v_position_keys, v_class_years, v_min_gpa
      ) >= 75 THEN 'Excellent'
      WHEN compute_match_score(
        p.primary_position, p.secondary_position,
        p.graduation_year, p.gpa, p.dominant_foot,
        v_position_keys, v_class_years, v_min_gpa
      ) >= 60 THEN 'Strong'
      WHEN compute_match_score(
        p.primary_position, p.secondary_position,
        p.graduation_year, p.gpa, p.dominant_foot,
        v_position_keys, v_class_years, v_min_gpa
      ) >= 45 THEN 'Good'
      ELSE 'Possible'
    END::TEXT                                                 AS match_label,
    (v_position_keys IS NOT NULL AND (
      p.primary_position = ANY(v_position_keys) OR
      p.secondary_position = ANY(v_position_keys)
    ))                                                        AS position_matched,
    (v_class_years IS NOT NULL AND p.graduation_year::TEXT = ANY(v_class_years))
                                                              AS timeline_matched
  FROM  players p
  JOIN  users   u ON u.id = p.user_id
  WHERE p.is_discoverable = TRUE
    -- Gender filter: only show players whose gender matches the coach's program.
    -- If the coach has no gender_program set, all players are returned.
    AND (v_gender_program IS NULL OR p.gender = v_gender_program)
  ORDER BY overall_score DESC;
END;
$$;

-- Permissions unchanged — re-grant to be safe
GRANT EXECUTE ON FUNCTION coach_player_matches() TO authenticated;

-- ── Verify the seed data is gender-consistent ──────────────────────────────
-- Quick sanity check: how many players per gender in the DB
DO $$
DECLARE
  v_male   INT;
  v_female INT;
  v_null   INT;
BEGIN
  SELECT COUNT(*) INTO v_male   FROM players WHERE gender = 'male';
  SELECT COUNT(*) INTO v_female FROM players WHERE gender = 'female';
  SELECT COUNT(*) INTO v_null   FROM players WHERE gender IS NULL;
  RAISE NOTICE 'Player gender breakdown — male: %, female: %, unset: %',
    v_male, v_female, v_null;
END;
$$;

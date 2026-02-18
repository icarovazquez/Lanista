-- 016 · Matching Engine
-- ─────────────────────────────────────────────────────────────────────────────
-- A lightweight, real-time matching function that coaches can call directly
-- (no service-role needed) to get a ranked list of players that fit their
-- tactical blueprint.
--
-- Score breakdown (0-100 each dimension):
--   position_score  (35 %) – player primary/secondary position matches coach
--                            position requirements
--   timeline_score  (30 %) – player graduation_year matches coach
--                            recruiting_class_years
--   academic_score  (20 %) – player GPA meets coach minimum
--   physical_score  (15 %) – player dominant_foot matches preference; height
--                            (future: currently placeholder)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Helper: compute match score between a player row and a coach row ──────────
CREATE OR REPLACE FUNCTION compute_match_score(
  p_primary_position   TEXT,
  p_secondary_position TEXT,
  p_graduation_year    INTEGER,
  p_gpa                NUMERIC,
  p_dominant_foot      TEXT,
  c_position_keys      TEXT[],   -- from coach_position_requirements
  c_class_years        TEXT[],   -- coach.recruiting_class_years
  c_min_gpa            NUMERIC   -- coach.min_gpa (may be null)
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  pos_score      NUMERIC := 0;
  timeline_score NUMERIC := 0;
  academic_score NUMERIC := 0;
  total          NUMERIC := 0;
BEGIN
  -- ── Position score (35) ────────────────────────────────────────────────────
  IF c_position_keys IS NOT NULL AND array_length(c_position_keys, 1) > 0 THEN
    IF p_primary_position = ANY(c_position_keys) THEN
      pos_score := 100;
    ELSIF p_secondary_position IS NOT NULL AND p_secondary_position = ANY(c_position_keys) THEN
      pos_score := 65;
    ELSE
      pos_score := 0;
    END IF;
  ELSE
    -- Coach has no specific requirements → neutral
    pos_score := 50;
  END IF;

  -- ── Timeline score (30) ────────────────────────────────────────────────────
  IF c_class_years IS NOT NULL
     AND array_length(c_class_years, 1) > 0
     AND p_graduation_year IS NOT NULL
  THEN
    IF p_graduation_year::TEXT = ANY(c_class_years) THEN
      timeline_score := 100;
    ELSE
      timeline_score := 0;
    END IF;
  ELSE
    timeline_score := 50;
  END IF;

  -- ── Academic score (20) ────────────────────────────────────────────────────
  IF c_min_gpa IS NOT NULL AND p_gpa IS NOT NULL THEN
    IF p_gpa >= c_min_gpa THEN
      -- bonus for exceeding minimum
      academic_score := LEAST(100, 70 + (p_gpa - c_min_gpa) * 30);
    ELSE
      academic_score := 0;
    END IF;
  ELSE
    academic_score := 60; -- unknown / no requirement → neutral
  END IF;

  -- ── Weighted total ─────────────────────────────────────────────────────────
  total := (pos_score * 0.35)
         + (timeline_score * 0.30)
         + (academic_score * 0.20)
         -- physical placeholder (15 %) — always 50 for now
         + (50 * 0.15);

  RETURN ROUND(total, 1);
END;
$$;

-- ── Main matching function: returns ranked players for the calling coach ──────
-- Usage: SELECT * FROM coach_player_matches() ORDER BY overall_score DESC LIMIT 30;
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
  match_label          TEXT,   -- 'Excellent', 'Strong', 'Good', 'Possible'
  position_matched     BOOLEAN,
  timeline_matched     BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER   -- runs with owner privileges so it can join all tables
STABLE
AS $$
DECLARE
  v_coach_id           UUID;
  v_position_keys      TEXT[];
  v_class_years        TEXT[];
  v_min_gpa            NUMERIC;
BEGIN
  -- ── Get the calling coach's profile ────────────────────────────────────────
  SELECT c.id, c.recruiting_class_years, c.min_gpa
  INTO v_coach_id, v_class_years, v_min_gpa
  FROM coaches c
  WHERE c.user_id = auth.uid()
  LIMIT 1;

  IF v_coach_id IS NULL THEN
    RETURN; -- not a coach
  END IF;

  -- ── Collect position keys this coach needs ─────────────────────────────────
  SELECT array_agg(DISTINCT cpr.position_key)
  INTO v_position_keys
  FROM coach_position_requirements cpr
  WHERE cpr.coach_id = v_coach_id
    AND cpr.position_key IS NOT NULL;

  -- ── Return matched players ─────────────────────────────────────────────────
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
  FROM players p
  JOIN users u ON u.id = p.user_id
  WHERE p.is_discoverable = TRUE
  ORDER BY overall_score DESC;
END;
$$;

-- Grant execute permission to authenticated users (coaches call via JWT)
GRANT EXECUTE ON FUNCTION coach_player_matches() TO authenticated;
GRANT EXECUTE ON FUNCTION compute_match_score(TEXT,TEXT,INTEGER,NUMERIC,TEXT,TEXT[],TEXT[],NUMERIC) TO authenticated;

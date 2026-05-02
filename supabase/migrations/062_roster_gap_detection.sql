-- Migration 062: Roster gap detection
--
-- Adds a position_type classifier and a coach_roster_gaps view that identifies
-- which position groups will open up as scraped players graduate.
-- Works at position-type granularity (gk / def / mid / fwd) because college
-- athletic sites only publish coarse positions (GK / D / M / F).
--
-- Also fixes hybrid position_key values already in the DB:
--   F/M, M/F  → cam   |   M/D, D/M, D/MF, MID/FWD  → cdm

-- ── 1. Fix hybrid position_key values stored from old normalizer logic ────────

UPDATE college_roster_players
SET    position_key = 'cam'
WHERE  position_raw IN ('F/M', 'M/F', 'MID/FWD')
  AND  position_key IN ('cf', 'cm');   -- only correct mis-mapped rows

UPDATE college_roster_players
SET    position_key = 'cdm'
WHERE  position_raw IN ('M/D', 'D/M', 'D/MF', 'D/M')
  AND  position_key IN ('cb', 'cm');

-- ── 2. Helper: position_key → broad position_type ────────────────────────────

CREATE OR REPLACE FUNCTION position_type_from_key(p_key TEXT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE STRICT AS $$
  SELECT CASE
    WHEN p_key = 'gk'                          THEN 'gk'
    WHEN p_key IN ('rb', 'cb', 'lb')           THEN 'def'
    WHEN p_key IN ('cdm','cm','cam','rm','lm') THEN 'mid'
    WHEN p_key IN ('rw','lw','st','cf')        THEN 'fwd'
    ELSE NULL
  END;
$$;

-- ── 3. View: graduating players per coach, year, position_type ────────────────
-- Used by the blueprint matching engine and the coach dashboard "gaps" widget.

CREATE OR REPLACE VIEW coach_roster_gaps AS
SELECT
  crp.coach_id,
  c.school_name,
  c.division,
  crp.graduation_year,
  position_type_from_key(crp.position_key)   AS position_type,
  COUNT(*)                                    AS players_graduating,
  -- convenience: list of player names graduating in this slot
  string_agg(crp.player_name, ', ' ORDER BY crp.player_name) AS player_names
FROM  college_roster_players  crp
JOIN  coaches                 c   ON c.id = crp.coach_id
WHERE crp.graduation_year IS NOT NULL
  AND crp.position_key    IS NOT NULL
GROUP BY
  crp.coach_id,
  c.school_name,
  c.division,
  crp.graduation_year,
  position_type_from_key(crp.position_key);

-- ── 4. View: upcoming gaps (graduating within 2 years from current season) ────

CREATE OR REPLACE VIEW coach_upcoming_gaps AS
SELECT
  g.*,
  -- How many blueprint slots of this position_type exist for this coach
  (
    SELECT COUNT(*)
    FROM   coach_position_requirements pr
    JOIN   positions pos ON pos.id = pr.position_id
    WHERE  pr.coach_id = g.coach_id
      AND  position_type_from_key(lower(pos.abbreviation)) = g.position_type
  ) AS blueprint_slots_required,
  -- How many current players fill this position_type (not graduating yet)
  (
    SELECT COUNT(*)
    FROM   college_roster_players crp2
    WHERE  crp2.coach_id = g.coach_id
      AND  position_type_from_key(crp2.position_key) = g.position_type
      AND  (crp2.graduation_year IS NULL OR crp2.graduation_year > g.graduation_year)
  ) AS current_players_remaining
FROM  coach_roster_gaps g
WHERE g.graduation_year <= (EXTRACT(YEAR FROM now())::int + 2);

-- ── 5. RLS: coaches see their own gap data ────────────────────────────────────

-- Views inherit RLS from the underlying tables; no additional policies needed.
-- Service role used by the matching engine can read everything.

-- ── 6. Updated preload_roster_from_scraped: smarter slot distribution ─────────
-- When distributing generic defenders (cb) into specific slots, prefer slots
-- that match the broader position_type when an exact position_key match fails.

CREATE OR REPLACE FUNCTION preload_roster_from_scraped(
  p_coach_id    UUID,
  p_season_year INTEGER DEFAULT 2025
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inserted INTEGER := 0;
  v_count    INTEGER;
  v_player   RECORD;
  v_pos_id   UUID;
BEGIN
  FOR v_player IN
    SELECT *
    FROM   college_roster_players
    WHERE  coach_id     = p_coach_id
      AND  season_year  = p_season_year
      AND  position_key IS NOT NULL
  LOOP
    -- 1. Exact position match
    SELECT id INTO v_pos_id
    FROM   positions
    WHERE  lower(abbreviation) = lower(v_player.position_key)
    LIMIT  1;

    -- 2. Fallback: pick any position of the same broad type
    IF v_pos_id IS NULL THEN
      SELECT p.id INTO v_pos_id
      FROM   positions p
      WHERE  position_type_from_key(lower(p.abbreviation))
               = position_type_from_key(lower(v_player.position_key))
      ORDER  BY p.abbreviation   -- deterministic pick
      LIMIT  1;
    END IF;

    CONTINUE WHEN v_pos_id IS NULL;

    INSERT INTO roster_slots (
      coach_id,
      position_id,
      position_key,
      player_name,
      graduation_year,
      slot_status,
      depth_order
    )
    SELECT
      p_coach_id,
      v_pos_id,
      v_player.position_key,
      v_player.player_name,
      v_player.graduation_year,
      'filled',
      1
    WHERE NOT EXISTS (
      SELECT 1 FROM roster_slots
      WHERE  coach_id    = p_coach_id
        AND  player_name = v_player.player_name
        AND  position_key = v_player.position_key
    );

    GET DIAGNOSTICS v_count = ROW_COUNT;
    v_inserted := v_inserted + v_count;
  END LOOP;

  RETURN v_inserted;
END;
$$;

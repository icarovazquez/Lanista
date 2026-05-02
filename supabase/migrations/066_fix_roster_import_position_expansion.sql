-- The scraper uses generic position keys (cb, cdm, cam) but the formation
-- visualisation uses specific keys (rcb, lcb, rcm, lcm).  The previous import
-- stored generic keys so players were invisible on the formation field.
--
-- This migration:
--   1. Deletes roster_slots that were imported from scraped data (player_name
--      matches a row in college_roster_players) so the re-import can place them
--      under the correct formation-specific keys.
--   2. Replaces preload_roster_from_scraped with a version that expands
--      generic positions to formation-specific ones using a priority list.

-- 1. Remove previously-imported slots whose position_key came from the scraper.
--    We match on player_name + coach_id to avoid touching manually-added slots.
DELETE FROM roster_slots rs
WHERE EXISTS (
  SELECT 1
  FROM   college_roster_players crp
  WHERE  crp.coach_id    = rs.coach_id
    AND  crp.player_name = rs.player_name
);

-- 2. Replacement function with position expansion
CREATE OR REPLACE FUNCTION preload_roster_from_scraped(
  p_coach_id   UUID,
  p_season_year INTEGER DEFAULT 2025
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inserted      INTEGER := 0;
  v_count         INTEGER;
  v_player        RECORD;
  v_pos_key       TEXT;
  v_candidates    TEXT[];
  v_candidate     TEXT;
  v_next_depth    INTEGER;
  v_done          BOOLEAN;
BEGIN
  FOR v_player IN
    SELECT *
    FROM   college_roster_players
    WHERE  coach_id    = p_coach_id
      AND  season_year = p_season_year
      AND  position_key IS NOT NULL
    ORDER BY position_key, graduation_year, player_name
  LOOP
    v_pos_key := LOWER(v_player.position_key);

    -- Expand generic positions → formation-specific position_key candidates.
    -- The list is tried in order; the first position with a free slot wins.
    -- rcb/lcb and rcm/lcm balance themselves because earlier players fill
    -- depth 1, leaving room for the complementary position first.
    v_candidates := CASE v_pos_key
      WHEN 'cb'  THEN ARRAY['rcb', 'lcb']          -- central defenders split
      WHEN 'cdm' THEN ARRAY['rcm', 'cm', 'lcm']    -- defensive mid → central
      WHEN 'cam' THEN ARRAY['rcm', 'cm', 'lcm']    -- attacking mid → central
      WHEN 'rm'  THEN ARRAY['rcm', 'rw', 'cm']
      WHEN 'lm'  THEN ARRAY['lcm', 'lw', 'cm']
      WHEN 'f9'  THEN ARRAY['st']
      WHEN 'wb'  THEN ARRAY['rb', 'lb']
      ELSE ARRAY[v_pos_key]                         -- gk, lb, rb, cm, lw, rw, st → exact
    END;

    v_done := FALSE;

    FOREACH v_candidate IN ARRAY v_candidates LOOP
      EXIT WHEN v_done;

      -- Skip if this player is already stored at this position+year
      CONTINUE WHEN EXISTS (
        SELECT 1 FROM roster_slots
        WHERE  coach_id        = p_coach_id
          AND  player_name     = v_player.player_name
          AND  position_key    = v_candidate
          AND  graduation_year = v_player.graduation_year
      );

      -- Pick the lowest available depth_order (≤ 4)
      SELECT COALESCE(MAX(depth_order), 0) + 1 INTO v_next_depth
      FROM   roster_slots
      WHERE  coach_id        = p_coach_id
        AND  position_key    = v_candidate
        AND  graduation_year = v_player.graduation_year;

      CONTINUE WHEN v_next_depth > 4;

      -- For symmetric pairs (rcb/lcb, rcm/lcm) prefer the side with fewer players
      -- so they fill up evenly rather than stacking all on one side.
      IF v_pos_key = 'cb' THEN
        DECLARE
          v_rcb_depth INTEGER;
          v_lcb_depth INTEGER;
        BEGIN
          SELECT COALESCE(MAX(depth_order), 0) INTO v_rcb_depth FROM roster_slots
          WHERE coach_id = p_coach_id AND position_key = 'rcb' AND graduation_year = v_player.graduation_year;
          SELECT COALESCE(MAX(depth_order), 0) INTO v_lcb_depth FROM roster_slots
          WHERE coach_id = p_coach_id AND position_key = 'lcb' AND graduation_year = v_player.graduation_year;
          -- Override candidate to whichever side is shorter
          IF v_rcb_depth <= v_lcb_depth THEN
            v_candidate := 'rcb';
          ELSE
            v_candidate := 'lcb';
          END IF;
          v_next_depth := LEAST(v_rcb_depth, v_lcb_depth) + 1;
          IF v_next_depth > 4 THEN CONTINUE; END IF;
        END;
      END IF;

      INSERT INTO roster_slots (
        coach_id,
        position_key,
        player_name,
        graduation_year,
        slot_status,
        depth_order
      ) VALUES (
        p_coach_id,
        v_candidate,
        v_player.player_name,
        v_player.graduation_year,
        'filled',
        v_next_depth
      )
      ON CONFLICT DO NOTHING;

      GET DIAGNOSTICS v_count = ROW_COUNT;
      IF v_count > 0 THEN
        v_inserted := v_inserted + 1;
        v_done     := TRUE;
      END IF;
    END LOOP;
  END LOOP;

  RETURN v_inserted;
END;
$$;

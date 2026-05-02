-- Fix position_key casing: the app uses lowercase positionId ('cb', 'gk', 'st'…)
-- but migration 064 stored uppercase. Lowercase all existing roster_slots and
-- update preload_roster_from_scraped to store lowercase going forward.

-- 1. Fix existing rows
UPDATE roster_slots
SET position_key = LOWER(position_key)
WHERE position_key != LOWER(position_key);

-- 2. Fix the import function to store lowercase
CREATE OR REPLACE FUNCTION preload_roster_from_scraped(
  p_coach_id   UUID,
  p_season_year INTEGER DEFAULT 2025
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inserted   INTEGER := 0;
  v_count      INTEGER;
  v_player     RECORD;
  v_pos_id     UUID;
  v_next_depth INTEGER;
  v_pos_key    TEXT;   -- lowercase, matches app positionId
BEGIN
  FOR v_player IN
    SELECT *
    FROM   college_roster_players
    WHERE  coach_id    = p_coach_id
      AND  season_year = p_season_year
      AND  position_key IS NOT NULL
    ORDER BY position_key, graduation_year, player_name
  LOOP
    -- Normalise to lowercase; map rm/lm → cm (not in positions table)
    v_pos_key := LOWER(v_player.position_key);
    IF v_pos_key IN ('rm', 'lm') THEN
      v_pos_key := 'cm';
    END IF;

    -- Look up the position UUID (case-insensitive)
    SELECT id INTO v_pos_id
    FROM   positions
    WHERE  LOWER(abbreviation) = v_pos_key
    LIMIT  1;

    CONTINUE WHEN v_pos_id IS NULL;

    -- Skip if this player already exists in any slot for this position+year
    CONTINUE WHEN EXISTS (
      SELECT 1 FROM roster_slots
      WHERE  coach_id        = p_coach_id
        AND  player_name     = v_player.player_name
        AND  position_key    = v_pos_key
        AND  graduation_year = v_player.graduation_year
    );

    -- Find the next available depth_order (max 4 per position per year)
    SELECT COALESCE(MAX(depth_order), 0) + 1 INTO v_next_depth
    FROM   roster_slots
    WHERE  coach_id        = p_coach_id
      AND  position_key    = v_pos_key
      AND  graduation_year = v_player.graduation_year;

    CONTINUE WHEN v_next_depth > 4;

    INSERT INTO roster_slots (
      coach_id,
      position_id,
      position_key,
      player_name,
      graduation_year,
      slot_status,
      depth_order
    ) VALUES (
      p_coach_id,
      v_pos_id,
      v_pos_key,
      v_player.player_name,
      v_player.graduation_year,
      'filled',
      v_next_depth
    )
    ON CONFLICT DO NOTHING;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    v_inserted := v_inserted + v_count;
  END LOOP;

  RETURN v_inserted;
END;
$$;

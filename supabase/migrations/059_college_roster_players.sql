-- Migration 059: College roster players (scraped reference data)
--
-- Stores read-only roster data scraped from college athletic websites.
-- Separate from coach-managed roster_slots — this is external reference data
-- used for analytics (height/position distributions, recruiting cycle prediction)
-- and to pre-populate a coach's roster_slots during onboarding.
--
-- Scraper: scripts/scrape-rosters/scraper.py
-- Supported platform: Sidearm Sports (covers ~75% of NCAA programs)

-- ── Scraped roster players ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS college_roster_players (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id        UUID REFERENCES coaches(id) ON DELETE CASCADE,
  season_year     INTEGER NOT NULL,          -- e.g. 2025 (fall semester year)
  jersey_number   TEXT,
  player_name     TEXT NOT NULL,
  position_raw    TEXT,                      -- verbatim from source ("GK", "Goalkeeper", etc.)
  position_key    TEXT,                      -- normalized to Lanista system (gk, cb, st…)
  academic_year   TEXT CHECK (academic_year IN ('Fr', 'So', 'Jr', 'Sr', 'Grad')),
  graduation_year INTEGER,                   -- estimated from academic_year + season_year
  height_cm       INTEGER,
  hometown        TEXT,
  high_school     TEXT,                      -- recruiting origin — high school or club
  source_url      TEXT,                      -- URL of the roster page scraped
  scraped_at      TIMESTAMPTZ DEFAULT now() NOT NULL,

  CONSTRAINT chk_season_year CHECK (season_year BETWEEN 2020 AND 2035),
  CONSTRAINT chk_height_cm   CHECK (height_cm IS NULL OR height_cm BETWEEN 140 AND 220)
);

-- ── Scrape audit log ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS roster_scrape_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id     UUID REFERENCES coaches(id) ON DELETE CASCADE,
  season_year  INTEGER NOT NULL,
  roster_url   TEXT,
  status       TEXT NOT NULL CHECK (status IN ('success', 'failed', 'partial', 'no_change')),
  player_count INTEGER DEFAULT 0,
  error_detail TEXT,                         -- populated on failure
  scraped_at   TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ── Indexes ───────────────────────────────────────────────────────────────────

-- Primary lookup: players for a given coach+season
CREATE INDEX IF NOT EXISTS idx_crp_coach_season
  ON college_roster_players (coach_id, season_year);

-- Analytics: filter by position across all programs
CREATE INDEX IF NOT EXISTS idx_crp_position_key
  ON college_roster_players (position_key);

-- Analytics: filter by graduation year for recruiting cycle prediction
CREATE INDEX IF NOT EXISTS idx_crp_graduation_year
  ON college_roster_players (graduation_year);

-- Scrape log: latest run per coach
CREATE INDEX IF NOT EXISTS idx_scrape_log_coach
  ON roster_scrape_log (coach_id, scraped_at DESC);

-- ── RLS: coaches see their own scraped roster; service_role for scraper writes

ALTER TABLE college_roster_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE roster_scrape_log      ENABLE ROW LEVEL SECURITY;

-- Coaches can read their own scraped roster data
CREATE POLICY "Coaches read own scraped roster"
  ON college_roster_players FOR SELECT
  USING (
    coach_id IN (
      SELECT id FROM coaches WHERE user_id = auth.uid()
    )
  );

-- Coaches can read their own scrape log
CREATE POLICY "Coaches read own scrape log"
  ON roster_scrape_log FOR SELECT
  USING (
    coach_id IN (
      SELECT id FROM coaches WHERE user_id = auth.uid()
    )
  );

-- Players can read all scraped rosters (for analytics / program research)
CREATE POLICY "Players read scraped rosters"
  ON college_roster_players FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM players WHERE user_id = auth.uid())
  );

-- ── Analytics view: roster profile per program ────────────────────────────────
-- Used by the player-facing "Program Analytics" feature.

CREATE OR REPLACE VIEW coach_roster_profiles AS
SELECT
  c.id                                           AS coach_id,
  c.school_name,
  c.division,
  c.state,
  crp.season_year,
  COUNT(*)                                       AS total_players,
  ROUND(AVG(crp.height_cm))                     AS avg_height_cm,
  ROUND(AVG(crp.height_cm) FILTER (WHERE crp.position_key IN ('gk')))          AS avg_height_gk,
  ROUND(AVG(crp.height_cm) FILTER (WHERE crp.position_key IN ('cb', 'rb', 'lb'))) AS avg_height_def,
  ROUND(AVG(crp.height_cm) FILTER (WHERE crp.position_key IN ('cdm','cm','cam','rm','lm'))) AS avg_height_mid,
  ROUND(AVG(crp.height_cm) FILTER (WHERE crp.position_key IN ('rw','lw','st','cf'))) AS avg_height_fwd,
  COUNT(*) FILTER (WHERE crp.graduation_year <= (EXTRACT(YEAR FROM now()) + 1)::int)
                                                 AS players_graduating_soon,  -- graduating this/next year
  COUNT(*) FILTER (WHERE crp.position_key = 'gk') AS count_gk,
  COUNT(*) FILTER (WHERE crp.position_key IN ('cb','rb','lb')) AS count_def,
  COUNT(*) FILTER (WHERE crp.position_key IN ('cdm','cm','cam','rm','lm')) AS count_mid,
  COUNT(*) FILTER (WHERE crp.position_key IN ('rw','lw','st','cf')) AS count_fwd
FROM coaches c
JOIN college_roster_players crp ON crp.coach_id = c.id
GROUP BY c.id, c.school_name, c.division, c.state, crp.season_year;

-- ── Helper function: preload roster_slots from scraped data ───────────────────
-- Call this after a coach registers to bootstrap their roster_slots.
-- Only inserts slots that don't already exist.

CREATE OR REPLACE FUNCTION preload_roster_from_scraped(
  p_coach_id   UUID,
  p_season_year INTEGER DEFAULT 2025
)
RETURNS INTEGER   -- number of slots inserted
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
    WHERE  coach_id    = p_coach_id
      AND  season_year = p_season_year
      AND  position_key IS NOT NULL
  LOOP
    -- Look up the position UUID from the positions table
    SELECT id INTO v_pos_id
    FROM   positions
    WHERE  abbreviation = v_player.position_key
    LIMIT  1;

    -- Skip if we can't map the position
    CONTINUE WHEN v_pos_id IS NULL;

    -- Insert if this slot doesn't already exist
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
      1   -- default to starter; coach can adjust depth order manually
    WHERE NOT EXISTS (
      SELECT 1 FROM roster_slots
      WHERE  coach_id      = p_coach_id
        AND  player_name   = v_player.player_name
        AND  position_key  = v_player.position_key
    );

    GET DIAGNOSTICS v_count = ROW_COUNT;
    v_inserted := v_inserted + v_count;
  END LOOP;

  RETURN v_inserted;
END;
$$;

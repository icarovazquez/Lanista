-- ── 078: Recruiting ROI & Player Value ────────────────────────────────────────
-- Tracks recruited player performance each season, computes ROI (was the
-- recruiting decision good?) and Player Value (how much does this player
-- matter RIGHT NOW?). Together they power the 2×2 Retention Matrix.

-- ── 1. player_season_stats ────────────────────────────────────────────────────
-- One row per player per season per coach. Source of truth for all stats.

CREATE TABLE player_season_stats (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Context
  player_id             UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  coach_id              UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  season_year           INTEGER NOT NULL,         -- e.g. 2025 = Fall 2025/Spring 2026
  academic_year         TEXT NOT NULL
                          CHECK (academic_year IN ('Fr','So','Jr','Sr','Grad')),
  position_group        TEXT NOT NULL
                          CHECK (position_group IN ('GK','DEF','MID','FWD')),

  -- ── Universal: Playing Time (coach-controlled, authoritative) ──────────────
  games_played          INTEGER DEFAULT 0,
  games_started         INTEGER DEFAULT 0,
  minutes_played        INTEGER DEFAULT 0,
  total_games_possible  INTEGER,                  -- denominator; NULL = estimated

  -- ── Universal: Passing (all positions) ────────────────────────────────────
  passes_attempted      INTEGER,
  passes_completed      INTEGER,
  -- pass_completion_pct computed: passes_completed / NULLIF(passes_attempted, 0)

  -- ── Universal: Physical (GPS/wearable — optional) ─────────────────────────
  avg_distance_km       NUMERIC(5,2),             -- km per game average
  max_velocity_kmh      NUMERIC(5,2),             -- peak km/h this season

  -- ── Universal: Discipline ─────────────────────────────────────────────────
  yellow_cards          INTEGER DEFAULT 0,
  red_cards             INTEGER DEFAULT 0,

  -- ── GK-specific ───────────────────────────────────────────────────────────
  saves                 INTEGER,
  goals_allowed         INTEGER,
  clean_sheets          INTEGER,
  -- save_pct computed: saves / NULLIF(saves + goals_allowed, 0)

  -- ── DEF + MID: Duels ──────────────────────────────────────────────────────
  duels_won             INTEGER,
  duels_attempted       INTEGER,

  -- ── DEF + MID: Progressive actions ───────────────────────────────────────
  progressive_passes    INTEGER,
  progressive_carries   INTEGER,

  -- ── DEF + MID + FWD: Creative output ─────────────────────────────────────
  key_passes            INTEGER,
  chances_created       INTEGER,

  -- ── DEF + MID + FWD: Goal contributions ──────────────────────────────────
  goals                 INTEGER,
  assists               INTEGER,

  -- ── FWD: Shooting ─────────────────────────────────────────────────────────
  shots                 INTEGER,
  shots_on_target       INTEGER,
  -- shot_accuracy_pct computed: shots_on_target / NULLIF(shots, 0)

  -- ── Academics ─────────────────────────────────────────────────────────────
  gpa_this_season       NUMERIC(3,2),
  credits_on_track      BOOLEAN,

  -- ── Roster / retention ────────────────────────────────────────────────────
  season_status         TEXT NOT NULL DEFAULT 'active'
                          CHECK (season_status IN (
                            'active',
                            'redshirt',
                            'redshirt_transfer',
                            'transfer_portal',
                            'transfer_portal_end',
                            'graduated',
                            'dismissed',
                            'walk_on_converted',
                            'never_played'
                          )),
  scholarship_type      TEXT DEFAULT 'not_set'
                          CHECK (scholarship_type IN (
                            'full','partial','walk_on','preferred_walk_on','not_set')),
  depth_chart_peak      INTEGER CHECK (depth_chart_peak BETWEEN 1 AND 4),

  -- ── Data provenance ───────────────────────────────────────────────────────
  entry_method          TEXT DEFAULT 'coach_manual'
                          CHECK (entry_method IN (
                            'coach_manual','player_self','both_verified','imported')),
  player_verified       BOOLEAN DEFAULT FALSE,
  coach_verified        BOOLEAN DEFAULT FALSE,
  notes                 TEXT,

  created_at            TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at            TIMESTAMPTZ DEFAULT now() NOT NULL,

  UNIQUE (player_id, coach_id, season_year)
);

CREATE INDEX idx_pss_player_coach  ON player_season_stats(player_id, coach_id);
CREATE INDEX idx_pss_coach_season  ON player_season_stats(coach_id, season_year DESC);
CREATE INDEX idx_pss_status        ON player_season_stats(season_status);

-- ── 2. player_roi_records ─────────────────────────────────────────────────────
-- One row per player+coach pair. Auto-created when pipeline → signed.
-- Contains both ROI Score (retrospective) and Player Value Score (current).
-- Recomputed by the roi-tracker Edge Function after every season_stats upsert.

CREATE TABLE player_roi_records (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_id               UUID REFERENCES recruiting_pipeline(id) ON DELETE SET NULL,
  player_id                 UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  coach_id                  UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  position_recruited_for    TEXT,
  signed_season_year        INTEGER,
  scholarship_type          TEXT,
  target_graduation_year    INTEGER,

  -- ── ROI Score (retrospective: was this a good recruiting decision?) ────────
  roi_utilization           NUMERIC(5,2),         -- 0–100, weight 35%
  roi_production            NUMERIC(5,2),         -- 0–100, weight 30%
  roi_retention             NUMERIC(5,2),         -- 0–100, weight 20%
  roi_academics             NUMERIC(5,2),         -- 0–100, weight 15%
  roi_score                 NUMERIC(5,2),         -- composite 0–100
  -- Grade: Elite≥85, Strong≥70, Solid≥55, Below Average≥40, Poor<40

  -- ── Player Value Score (current: how much does this player matter now?) ───
  value_performance         NUMERIC(5,2),         -- 0–100, weight 40% (latest season)
  value_scarcity            NUMERIC(5,2),         -- 0–100, weight 25% (roster depth)
  value_eligibility         NUMERIC(5,2),         -- 0–100, weight 20% (seasons left)
  value_replaceability      NUMERIC(5,2),         -- 0–100, weight 15% (blueprint matches)
  value_score               NUMERIC(5,2),         -- composite 0–100

  -- ── Retention Matrix quadrant ─────────────────────────────────────────────
  -- foundation:  high ROI + high value  → fight hard
  -- developing:  low ROI  + high value  → grew into it, fight hard
  -- proven:      high ROI + low value   → good pick, past peak
  -- reconsider:  low ROI  + low value   → let go
  retention_quadrant        TEXT
                              CHECK (retention_quadrant IN (
                                'foundation','developing','proven','reconsider')),

  -- ── Portal risk flag ──────────────────────────────────────────────────────
  portal_risk               BOOLEAN DEFAULT FALSE,
  portal_risk_flagged_at    TIMESTAMPTZ,

  -- ── Career summary ────────────────────────────────────────────────────────
  total_seasons_tracked     INTEGER DEFAULT 0,
  total_minutes_played      INTEGER DEFAULT 0,
  career_status             TEXT DEFAULT 'active'
                              CHECK (career_status IN (
                                'active','graduated','transferred','departed')),

  last_computed_at          TIMESTAMPTZ,
  created_at                TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at                TIMESTAMPTZ DEFAULT now() NOT NULL,

  UNIQUE (player_id, coach_id)
);

CREATE INDEX idx_roi_coach          ON player_roi_records(coach_id);
CREATE INDEX idx_roi_quadrant       ON player_roi_records(coach_id, retention_quadrant);
CREATE INDEX idx_roi_composite      ON player_roi_records(coach_id, roi_score DESC);
CREATE INDEX idx_roi_value          ON player_roi_records(coach_id, value_score DESC);
CREATE INDEX idx_roi_portal         ON player_roi_records(coach_id, portal_risk)
                                      WHERE portal_risk = TRUE;

-- ── 3. roi_stat_disputes ──────────────────────────────────────────────────────

CREATE TABLE roi_stat_disputes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_stat_id  UUID NOT NULL REFERENCES player_season_stats(id) ON DELETE CASCADE,
  raised_by_role  TEXT NOT NULL CHECK (raised_by_role IN ('coach','player')),
  field_name      TEXT NOT NULL,
  coach_value     TEXT,
  player_value    TEXT,
  resolved        BOOLEAN DEFAULT FALSE,
  resolved_value  TEXT,
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX idx_disputes_stat      ON roi_stat_disputes(season_stat_id);
CREATE INDEX idx_disputes_unresolved ON roi_stat_disputes(season_stat_id)
                                       WHERE resolved = FALSE;

-- ── 4. Pipeline: signed_at + roi_tracking_on ─────────────────────────────────

ALTER TABLE recruiting_pipeline
  ADD COLUMN IF NOT EXISTS signed_at        TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS roi_tracking_on  BOOLEAN DEFAULT FALSE;

-- ── 5. RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE player_season_stats   ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_roi_records    ENABLE ROW LEVEL SECURITY;
ALTER TABLE roi_stat_disputes     ENABLE ROW LEVEL SECURITY;

-- player_season_stats: coach full access to own records
CREATE POLICY "coach_own_season_stats"
  ON player_season_stats FOR ALL
  USING (coach_id IN (SELECT id FROM coaches WHERE user_id = auth.uid()));

-- player_season_stats: player read + limited update (production stats + verify flag)
CREATE POLICY "player_read_own_season_stats"
  ON player_season_stats FOR SELECT
  USING (player_id IN (SELECT id FROM players WHERE user_id = auth.uid()));

CREATE POLICY "player_update_own_season_stats"
  ON player_season_stats FOR UPDATE
  USING (player_id IN (SELECT id FROM players WHERE user_id = auth.uid()))
  WITH CHECK (player_id IN (SELECT id FROM players WHERE user_id = auth.uid()));

-- player_roi_records: coach read own
CREATE POLICY "coach_read_own_roi"
  ON player_roi_records FOR ALL
  USING (coach_id IN (SELECT id FROM coaches WHERE user_id = auth.uid()));

-- player_roi_records: player read own (value score visible, ROI gated by coach)
CREATE POLICY "player_read_own_roi"
  ON player_roi_records FOR SELECT
  USING (player_id IN (SELECT id FROM players WHERE user_id = auth.uid()));

-- roi_stat_disputes: coach access
CREATE POLICY "coach_own_disputes"
  ON roi_stat_disputes FOR ALL
  USING (
    season_stat_id IN (
      SELECT id FROM player_season_stats
      WHERE coach_id IN (SELECT id FROM coaches WHERE user_id = auth.uid())
    )
  );

-- roi_stat_disputes: player access
CREATE POLICY "player_own_disputes"
  ON roi_stat_disputes FOR ALL
  USING (
    season_stat_id IN (
      SELECT id FROM player_season_stats
      WHERE player_id IN (SELECT id FROM players WHERE user_id = auth.uid())
    )
  );

-- Pre-computed player-coach matches
CREATE TABLE player_coach_matches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id         UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  coach_id          UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  overall_score     DECIMAL(5,2) NOT NULL DEFAULT 0,
  tactical_score    DECIMAL(5,2) NOT NULL DEFAULT 0,
  position_score    DECIMAL(5,2) NOT NULL DEFAULT 0,
  physical_score    DECIMAL(5,2) NOT NULL DEFAULT 0,
  academic_score    DECIMAL(5,2) NOT NULL DEFAULT 0,
  timeline_score    DECIMAL(5,2) NOT NULL DEFAULT 0,
  match_reasons     JSONB,
  match_reasons_es  JSONB,
  roster_gap_year   INTEGER,
  position_id       UUID REFERENCES positions(id),
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  computed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (player_id, coach_id)
);

-- Saved searches
CREATE TABLE saved_searches (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  search_type   TEXT NOT NULL CHECK (search_type IN ('player_search', 'program_search')),
  name          TEXT,
  filters       JSONB NOT NULL DEFAULT '{}',
  alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_run_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE player_coach_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_searches ENABLE ROW LEVEL SECURITY;

-- Players see their own matches
CREATE POLICY "players_see_own_matches"
  ON player_coach_matches FOR SELECT
  USING (EXISTS (SELECT 1 FROM players WHERE id = player_coach_matches.player_id AND user_id = auth.uid()));

-- Coaches see their own matches
CREATE POLICY "coaches_see_own_matches"
  ON player_coach_matches FOR SELECT
  USING (EXISTS (SELECT 1 FROM coaches WHERE id = player_coach_matches.coach_id AND user_id = auth.uid()));

-- Service role can write matches (matching engine)
CREATE POLICY "service_write_matches"
  ON player_coach_matches FOR ALL
  USING (auth.role() = 'service_role');

-- Saved searches
CREATE POLICY "saved_searches_own"
  ON saved_searches FOR ALL
  USING (user_id = auth.uid());

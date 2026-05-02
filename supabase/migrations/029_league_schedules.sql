-- ── League Schedules ────────────────────────────────────────────────────────
-- Stores clubs, events (tournaments/showcases), and individual games
-- for MLS Next, ECNL, ECRL, Girls Academy, and NPL.
-- Player → club linking via player_club_affiliations.

-- ── Clubs ────────────────────────────────────────────────────────────────────
CREATE TABLE league_clubs (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  league      TEXT    NOT NULL CHECK (league IN ('mlsnext', 'ecnl', 'ecrl', 'ga', 'npl')),
  club_name   TEXT    NOT NULL,
  city        TEXT,
  state       TEXT    NOT NULL,
  region      TEXT,   -- 'Northeast' | 'Midwest' | 'South' | 'West'
  gender      TEXT    CHECK (gender IN ('male', 'female', 'both')) DEFAULT 'both',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Events / Tournaments / Showcases ────────────────────────────────────────
CREATE TABLE league_events (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  league       TEXT    NOT NULL CHECK (league IN ('mlsnext', 'ecnl', 'ecrl', 'ga', 'npl')),
  event_name   TEXT    NOT NULL,
  event_type   TEXT    CHECK (event_type IN ('showcase', 'playoff', 'championship', 'regular_season', 'id_camp')),
  start_date   DATE    NOT NULL,
  end_date     DATE    NOT NULL,
  venue_name   TEXT,
  city         TEXT,
  state        TEXT    NOT NULL,
  gender       TEXT    CHECK (gender IN ('male', 'female', 'both')) DEFAULT 'both',
  age_groups   TEXT[], -- e.g. ARRAY['U15','U16','U17','U18']
  description  TEXT,
  website_url  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Individual Games ─────────────────────────────────────────────────────────
CREATE TABLE league_games (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id      UUID    REFERENCES league_events(id) ON DELETE SET NULL,
  league        TEXT    NOT NULL CHECK (league IN ('mlsnext', 'ecnl', 'ecrl', 'ga', 'npl')),
  home_club_id  UUID    REFERENCES league_clubs(id) ON DELETE SET NULL,
  away_club_id  UUID    REFERENCES league_clubs(id) ON DELETE SET NULL,
  game_date     DATE    NOT NULL,
  game_time     TIME,
  field_name    TEXT,
  city          TEXT,
  state         TEXT,
  age_group     TEXT,   -- 'U15' | 'U16' | 'U17' | 'U18' | 'U19'
  gender        TEXT    CHECK (gender IN ('male', 'female')),
  home_score    INTEGER,
  away_score    INTEGER,
  is_completed  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Player → Club Affiliations ───────────────────────────────────────────────
-- Links a player profile to their club team for a given season.
CREATE TABLE player_club_affiliations (
  id             UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id      UUID    NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  club_id        UUID    NOT NULL REFERENCES league_clubs(id) ON DELETE CASCADE,
  age_group      TEXT    NOT NULL,  -- 'U16', 'U17', etc.
  season         TEXT    NOT NULL,  -- '2025-2026'
  jersey_number  INTEGER,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (player_id, club_id, season)
);

-- ── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_league_events_league      ON league_events(league);
CREATE INDEX idx_league_events_start_date  ON league_events(start_date);
CREATE INDEX idx_league_events_state       ON league_events(state);
CREATE INDEX idx_league_games_event_id     ON league_games(event_id);
CREATE INDEX idx_league_games_game_date    ON league_games(game_date);
CREATE INDEX idx_league_games_home_club    ON league_games(home_club_id);
CREATE INDEX idx_league_games_away_club    ON league_games(away_club_id);
CREATE INDEX idx_player_club_player        ON player_club_affiliations(player_id);
CREATE INDEX idx_player_club_club          ON player_club_affiliations(club_id);
CREATE INDEX idx_player_club_active        ON player_club_affiliations(is_active) WHERE is_active = TRUE;

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE league_clubs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE league_events            ENABLE ROW LEVEL SECURITY;
ALTER TABLE league_games             ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_club_affiliations ENABLE ROW LEVEL SECURITY;

-- Schedule data is publicly readable by all authenticated users
CREATE POLICY "league_clubs_read"  ON league_clubs  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "league_events_read" ON league_events FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "league_games_read"  ON league_games  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Players manage their own club affiliations
CREATE POLICY "player_club_affiliations_own" ON player_club_affiliations
  FOR ALL USING (
    EXISTS (SELECT 1 FROM players WHERE id = player_club_affiliations.player_id AND user_id = auth.uid())
  );

-- Coaches can read all club affiliations (to know where pipeline players are playing)
CREATE POLICY "player_club_affiliations_coaches_read" ON player_club_affiliations
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'coach')
  );

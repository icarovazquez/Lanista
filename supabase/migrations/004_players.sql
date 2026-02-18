-- Core player profile
CREATE TABLE players (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id              UUID REFERENCES sports(id),
  gender                TEXT CHECK (gender IN ('male', 'female')),
  date_of_birth         DATE,
  grade                 INTEGER CHECK (grade BETWEEN 6 AND 12),
  graduation_year       INTEGER,
  height_cm             INTEGER,
  weight_kg             INTEGER,
  dominant_foot         TEXT CHECK (dominant_foot IN ('left', 'right', 'both')),
  speed_rating          INTEGER CHECK (speed_rating BETWEEN 1 AND 10),
  gpa                   DECIMAL(3,2),
  sat_score             INTEGER,
  act_score             INTEGER,
  intended_major        TEXT,
  club_id               UUID REFERENCES clubs(id),
  league_id             UUID REFERENCES leagues(id),
  target_division       TEXT CHECK (target_division IN ('D1', 'D2', 'D3', 'NAIA', 'JUCO')),
  is_discoverable       BOOLEAN NOT NULL DEFAULT TRUE,
  leadership_rating     INTEGER CHECK (leadership_rating BETWEEN 1 AND 5),
  character_description TEXT,
  bio                   TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_players_updated_at
  BEFORE UPDATE ON players
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Player positions (many-to-many)
CREATE TABLE player_positions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id   UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  position_id UUID NOT NULL REFERENCES positions(id),
  is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
  proficiency INTEGER CHECK (proficiency BETWEEN 1 AND 10),
  UNIQUE (player_id, position_id)
);

-- Player target schools
CREATE TABLE player_target_schools (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id   UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  college_id  UUID NOT NULL REFERENCES colleges(id),
  priority    INTEGER,
  status      TEXT NOT NULL DEFAULT 'interested' CHECK (status IN (
                'interested', 'contacted', 'visited',
                'applied', 'offered', 'committed', 'declined'
              )),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (player_id, college_id)
);

-- Player highlight videos
CREATE TABLE player_videos (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id         UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  title             TEXT,
  source            TEXT CHECK (source IN ('hudl', 'taka', 'youtube', 'mux', 'other')),
  external_url      TEXT,
  mux_asset_id      TEXT,
  mux_playback_id   TEXT,
  thumbnail_url     TEXT,
  duration_secs     INTEGER,
  analysis_status   TEXT NOT NULL DEFAULT 'pending' CHECK (analysis_status IN (
                      'pending', 'processing', 'complete', 'failed'
                    )),
  analysis_result   JSONB,
  recommendations   JSONB,
  is_primary        BOOLEAN NOT NULL DEFAULT FALSE,
  uploaded_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for player tables
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_target_schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_videos ENABLE ROW LEVEL SECURITY;

-- Players can manage their own profile
CREATE POLICY "players_own_profile"
  ON players FOR ALL
  USING (user_id = auth.uid());

-- Coaches can read discoverable player profiles
CREATE POLICY "coaches_read_players"
  ON players FOR SELECT
  USING (
    is_discoverable = TRUE
    AND EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'coach'
    )
  );

-- Parents can read their linked player's profile
CREATE POLICY "parents_read_player_profile"
  ON players FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM parent_player_relationships
      WHERE parent_id = auth.uid() AND player_id = players.user_id
    )
  );

-- Mentors can read their assigned player's profile
CREATE POLICY "mentors_read_player_profile"
  ON players FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM mentor_player_relationships
      WHERE mentor_id = auth.uid() AND player_id = players.user_id AND status = 'active'
    )
  );

-- Player positions policies
CREATE POLICY "player_positions_own" ON player_positions FOR ALL
  USING (EXISTS (SELECT 1 FROM players WHERE id = player_positions.player_id AND user_id = auth.uid()));

CREATE POLICY "coaches_read_player_positions" ON player_positions FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'coach'));

-- Player target schools policies
CREATE POLICY "player_target_schools_own" ON player_target_schools FOR ALL
  USING (EXISTS (SELECT 1 FROM players WHERE id = player_target_schools.player_id AND user_id = auth.uid()));

-- Player videos policies
CREATE POLICY "player_videos_own" ON player_videos FOR ALL
  USING (EXISTS (SELECT 1 FROM players WHERE id = player_videos.player_id AND user_id = auth.uid()));

CREATE POLICY "coaches_read_player_videos" ON player_videos FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'coach'));

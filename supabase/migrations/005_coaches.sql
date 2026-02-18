-- Core coach profile
CREATE TABLE coaches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  college_id        UUID REFERENCES colleges(id),
  sport_id          UUID REFERENCES sports(id),
  coach_type        TEXT NOT NULL DEFAULT 'assistant' CHECK (coach_type IN ('head', 'assistant')),
  gender_program    TEXT CHECK (gender_program IN ('male', 'female')),
  min_gpa           DECIMAL(3,2),
  min_sat           INTEGER,
  min_act           INTEGER,
  subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'institutional')),
  bio               TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_coaches_updated_at
  BEFORE UPDATE ON coaches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Coach formations (tactical blueprint)
CREATE TABLE coach_formations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id      UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  formation_id  UUID NOT NULL REFERENCES formations(id),
  is_primary    BOOLEAN NOT NULL DEFAULT FALSE,
  notes         TEXT,
  UNIQUE (coach_id, formation_id)
);

-- Coach position requirements
CREATE TABLE coach_position_requirements (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id          UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  formation_id      UUID NOT NULL REFERENCES formations(id),
  position_id       UUID NOT NULL REFERENCES positions(id),
  min_height_cm     INTEGER,
  preferred_foot    TEXT CHECK (preferred_foot IN ('left', 'right', 'both', 'any')),
  min_speed_rating  INTEGER,
  min_gpa           DECIMAL(3,2),
  tactical_notes    TEXT,
  tactical_notes_es TEXT,
  character_notes   TEXT,
  is_published      BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (coach_id, formation_id, position_id)
);

-- Roster map slots
CREATE TABLE roster_slots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id        UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  academic_year   INTEGER NOT NULL,
  position_id     UUID NOT NULL REFERENCES positions(id),
  slot_status     slot_status NOT NULL DEFAULT 'unknown',
  player_name     TEXT,
  player_user_id  UUID REFERENCES users(id),
  needs_recruit   BOOLEAN GENERATED ALWAYS AS (
                    slot_status IN ('graduating', 'portal_risk', 'open')
                  ) STORED,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_roster_slots_updated_at
  BEFORE UPDATE ON roster_slots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Recruiting pipeline
CREATE TABLE recruiting_pipeline (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id        UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  stage           pipeline_stage NOT NULL DEFAULT 'identified',
  target_year     INTEGER,
  position_id     UUID REFERENCES positions(id),
  notes           TEXT,
  last_contact    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (coach_id, player_id)
);

-- RLS for coach tables
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_formations ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_position_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE roster_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruiting_pipeline ENABLE ROW LEVEL SECURITY;

-- Coaches manage their own profile
CREATE POLICY "coaches_own_profile" ON coaches FOR ALL
  USING (user_id = auth.uid());

-- Players can read coach profiles
CREATE POLICY "players_read_coaches" ON coaches FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('player', 'parent', 'mentor')));

-- Coach formations
CREATE POLICY "coach_formations_own" ON coach_formations FOR ALL
  USING (EXISTS (SELECT 1 FROM coaches WHERE id = coach_formations.coach_id AND user_id = auth.uid()));

-- Published position requirements visible to players
CREATE POLICY "coach_req_own" ON coach_position_requirements FOR ALL
  USING (EXISTS (SELECT 1 FROM coaches WHERE id = coach_position_requirements.coach_id AND user_id = auth.uid()));

CREATE POLICY "coach_req_players_read_published" ON coach_position_requirements FOR SELECT
  USING (is_published = TRUE AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'player'));

-- Roster slots
CREATE POLICY "roster_slots_own" ON roster_slots FOR ALL
  USING (EXISTS (SELECT 1 FROM coaches WHERE id = roster_slots.coach_id AND user_id = auth.uid()));

-- Pipeline
CREATE POLICY "pipeline_own" ON recruiting_pipeline FOR ALL
  USING (EXISTS (SELECT 1 FROM coaches WHERE id = recruiting_pipeline.coach_id AND user_id = auth.uid()));

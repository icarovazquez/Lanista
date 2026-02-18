-- Sports table
CREATE TABLE sports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  name_es     TEXT NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Formations / Systems of play
CREATE TABLE formations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id    UUID NOT NULL REFERENCES sports(id),
  name        TEXT NOT NULL,        -- '4-3-3'
  description TEXT,
  description_es TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Positions per sport/formation
CREATE TABLE positions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id        UUID NOT NULL REFERENCES sports(id),
  formation_id    UUID REFERENCES formations(id),
  name            TEXT NOT NULL,
  name_es         TEXT NOT NULL,
  abbreviation    TEXT,
  position_type   TEXT CHECK (position_type IN (
                    'goalkeeper', 'defender', 'midfielder', 'forward'
                  )),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- College divisions
CREATE TABLE divisions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  name_es         TEXT NOT NULL,
  scholarship_type TEXT CHECK (scholarship_type IN ('equivalency', 'headcount', 'none')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Conferences
CREATE TABLE conferences (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  division_id UUID NOT NULL REFERENCES divisions(id),
  sport_id    UUID NOT NULL REFERENCES sports(id),
  name        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Colleges and Universities
CREATE TABLE colleges (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT NOT NULL,
  city              TEXT,
  state             TEXT,
  country           TEXT NOT NULL DEFAULT 'USA',
  conference_id     UUID REFERENCES conferences(id),
  division_id       UUID REFERENCES divisions(id),
  acceptance_rate   DECIMAL,
  avg_sat           INTEGER,
  avg_act           INTEGER,
  total_enrollment  INTEGER,
  campus_type       TEXT CHECK (campus_type IN ('urban', 'suburban', 'rural')),
  website_url       TEXT,
  logo_url          TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Youth soccer leagues
CREATE TABLE leagues (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id    UUID NOT NULL REFERENCES sports(id),
  name        TEXT NOT NULL,
  name_es     TEXT,
  gender      TEXT CHECK (gender IN ('male', 'female', 'coed')),
  level       INTEGER NOT NULL DEFAULT 1,
  website_url TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Youth soccer clubs
CREATE TABLE clubs (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                    TEXT NOT NULL,
  city                    TEXT,
  state                   TEXT,
  league_id               UUID REFERENCES leagues(id),
  gender                  TEXT CHECK (gender IN ('male', 'female', 'coed')),
  sport_id                UUID REFERENCES sports(id),
  website_url             TEXT,
  logo_url                TEXT,
  verified                BOOLEAN NOT NULL DEFAULT FALSE,
  development_rating      DECIMAL CHECK (development_rating BETWEEN 1 AND 5),
  college_placement_rate  DECIMAL,
  d1_placement_rate       DECIMAL,
  d2_placement_rate       DECIMAL,
  d3_placement_rate       DECIMAL,
  is_premium              BOOLEAN NOT NULL DEFAULT FALSE,
  description             TEXT,
  description_es          TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- European gap year academies
CREATE TABLE gap_year_academies (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,
  country               TEXT NOT NULL,
  city                  TEXT,
  sport_id              UUID REFERENCES sports(id),
  cost_per_year_usd     INTEGER,
  duration_months       INTEGER,
  website_url           TEXT,
  logo_url              TEXT,
  is_verified           BOOLEAN NOT NULL DEFAULT FALSE,
  is_reputable          BOOLEAN,
  ncaa_eligible         BOOLEAN,
  description           TEXT,
  description_es        TEXT,
  american_alumni_count INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS — reference data is publicly readable
ALTER TABLE sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE formations ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE divisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE conferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE colleges ENABLE ROW LEVEL SECURITY;
ALTER TABLE leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE gap_year_academies ENABLE ROW LEVEL SECURITY;

-- Everyone can read reference data
CREATE POLICY "reference_data_public_read" ON sports FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON formations FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON positions FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON divisions FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON conferences FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON colleges FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON leagues FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON clubs FOR SELECT USING (true);
CREATE POLICY "reference_data_public_read" ON gap_year_academies FOR SELECT USING (true);

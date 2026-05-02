-- Migration 022: Player Recruiting Roadmap tables

CREATE TABLE player_roadmaps (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  generated_at    TIMESTAMPTZ DEFAULT now(),
  last_edited_at  TIMESTAMPTZ,
  raw_ai_response JSONB,
  UNIQUE(player_id)
);

CREATE TABLE roadmap_target_schools (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  roadmap_id  UUID NOT NULL REFERENCES player_roadmaps(id) ON DELETE CASCADE,
  school_name TEXT NOT NULL,
  division    TEXT,
  bucket      TEXT CHECK (bucket IN ('reach', 'target', 'safety')),
  notes       TEXT,
  order_index INTEGER DEFAULT 0
);

CREATE TABLE roadmap_milestones (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  roadmap_id   UUID NOT NULL REFERENCES player_roadmaps(id) ON DELETE CASCADE,
  category     TEXT CHECK (category IN ('academic', 'conditioning', 'strength', 'skills')),
  grade        INTEGER,
  title        TEXT NOT NULL,
  description  TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  order_index  INTEGER DEFAULT 0
);

-- RLS policies
ALTER TABLE player_roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmap_target_schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmap_milestones ENABLE ROW LEVEL SECURITY;

-- Players can only see/edit their own roadmap
CREATE POLICY "player_roadmaps_own" ON player_roadmaps
  FOR ALL USING (
    player_id IN (
      SELECT id FROM players WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "roadmap_target_schools_own" ON roadmap_target_schools
  FOR ALL USING (
    roadmap_id IN (
      SELECT pr.id FROM player_roadmaps pr
      JOIN players p ON p.id = pr.player_id
      WHERE p.user_id = auth.uid()
    )
  );

CREATE POLICY "roadmap_milestones_own" ON roadmap_milestones
  FOR ALL USING (
    roadmap_id IN (
      SELECT pr.id FROM player_roadmaps pr
      JOIN players p ON p.id = pr.player_id
      WHERE p.user_id = auth.uid()
    )
  );

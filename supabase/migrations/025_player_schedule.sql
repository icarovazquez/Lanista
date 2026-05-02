-- Player schedule: upcoming games and showcases coaches can attend to scout live
CREATE TABLE player_schedule (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id    UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  event_type   TEXT NOT NULL CHECK (event_type IN ('game', 'showcase')),
  title        TEXT NOT NULL,           -- opponent for games, event name for showcases
  event_date   DATE NOT NULL,
  location     TEXT,                    -- city/venue e.g. "Frisco, TX"
  competition  TEXT,                    -- e.g. "MLS Next", "ECNL", "Jefferson Cup"
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS: players manage their own schedule; coaches can read all
ALTER TABLE player_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Players manage own schedule"
  ON player_schedule FOR ALL
  USING (
    player_id IN (
      SELECT id FROM players WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    player_id IN (
      SELECT id FROM players WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Coaches can read player schedule"
  ON player_schedule FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM coaches WHERE user_id = auth.uid())
  );

-- Index for fast lookups
CREATE INDEX idx_player_schedule_player_date
  ON player_schedule(player_id, event_date);

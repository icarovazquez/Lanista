-- Stores programs a player has bookmarked from the Openings page.
-- Status tracks where they are in the recruiting process with that program.

CREATE TABLE player_saved_coaches (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id  UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  coach_id   UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'interested'
             CHECK (status IN ('interested', 'contacted', 'applied', 'committed')),
  saved_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (player_id, coach_id)
);

ALTER TABLE player_saved_coaches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "player_saved_coaches_own" ON player_saved_coaches FOR ALL
  USING (EXISTS (
    SELECT 1 FROM players WHERE id = player_saved_coaches.player_id AND user_id = auth.uid()
  ));

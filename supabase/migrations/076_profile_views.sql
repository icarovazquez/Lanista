-- ── 076: Profile Views ─────────────────────────────────────────────────────
-- Tracks when a coach views a player's profile.

CREATE TABLE profile_views (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id   UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  player_id  UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  viewed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_views_player ON profile_views(player_id, viewed_at DESC);
CREATE INDEX idx_profile_views_coach  ON profile_views(coach_id);

-- RLS
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;

-- Players can see who viewed their profile
CREATE POLICY "Players see own profile views"
  ON profile_views FOR SELECT
  USING (
    player_id IN (
      SELECT id FROM players WHERE user_id = auth.uid()
    )
  );

-- Coaches can insert their own views
CREATE POLICY "Coaches can record views"
  ON profile_views FOR INSERT
  WITH CHECK (
    coach_id IN (
      SELECT id FROM coaches WHERE user_id = auth.uid()
    )
  );

-- Coaches can see their own views (to avoid duplicate tracking)
CREATE POLICY "Coaches see own views"
  ON profile_views FOR SELECT
  USING (
    coach_id IN (
      SELECT id FROM coaches WHERE user_id = auth.uid()
    )
  );

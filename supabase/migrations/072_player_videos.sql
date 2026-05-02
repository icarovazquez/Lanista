-- Migration 072: Add Mux columns to existing player_videos table

-- Add Mux-specific columns (ignore if already exist)
ALTER TABLE player_videos
  ADD COLUMN IF NOT EXISTS mux_upload_id    TEXT,
  ADD COLUMN IF NOT EXISTS mux_asset_id     TEXT,
  ADD COLUMN IF NOT EXISTS mux_playback_id  TEXT,
  ADD COLUMN IF NOT EXISTS duration_seconds NUMERIC;

-- Update status check to include Mux statuses (drop old constraint first)
ALTER TABLE player_videos DROP CONSTRAINT IF EXISTS player_videos_status_check;
ALTER TABLE player_videos DROP CONSTRAINT IF EXISTS player_videos_analysis_status_check;

-- Add new status column if it doesn't exist (some migrations used analysis_status)
ALTER TABLE player_videos ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'waiting';

-- Migrate existing analysis_status values to status
UPDATE player_videos
SET status = CASE
  WHEN analysis_status = 'completed' THEN 'ready'
  WHEN analysis_status = 'failed'    THEN 'errored'
  WHEN analysis_status = 'pending'   THEN 'waiting'
  WHEN analysis_status = 'processing' THEN 'processing'
  ELSE 'waiting'
END
WHERE analysis_status IS NOT NULL AND status = 'waiting';

-- Add proper status constraint
ALTER TABLE player_videos
  ADD CONSTRAINT player_videos_status_check
  CHECK (status IN ('waiting', 'processing', 'ready', 'errored'));

-- Ensure video_type constraint exists
ALTER TABLE player_videos DROP CONSTRAINT IF EXISTS player_videos_video_type_check;
ALTER TABLE player_videos
  ADD CONSTRAINT player_videos_video_type_check
  CHECK (video_type IN ('highlight', 'game_film'));

-- Indexes for Mux webhook lookups
CREATE INDEX IF NOT EXISTS idx_player_videos_player_id    ON player_videos(player_id);
CREATE INDEX IF NOT EXISTS idx_player_videos_mux_upload_id ON player_videos(mux_upload_id);
CREATE INDEX IF NOT EXISTS idx_player_videos_mux_asset_id  ON player_videos(mux_asset_id);

-- RLS policies (drop and recreate to ensure they're current)
ALTER TABLE player_videos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "players_manage_own_videos"  ON player_videos;
DROP POLICY IF EXISTS "coaches_read_player_videos"  ON player_videos;

CREATE POLICY "players_manage_own_videos"
  ON player_videos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM players
      WHERE players.id = player_videos.player_id
        AND players.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM players
      WHERE players.id = player_videos.player_id
        AND players.user_id = auth.uid()
    )
  );

CREATE POLICY "coaches_read_player_videos"
  ON player_videos FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM coaches WHERE coaches.user_id = auth.uid())
    AND EXISTS (
      SELECT 1 FROM players
      WHERE players.id = player_videos.player_id
        AND players.is_discoverable = true
    )
  );

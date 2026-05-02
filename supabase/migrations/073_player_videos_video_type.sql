-- Migration 073: Add video_type column and unique constraint to player_videos

-- Add video_type column if it doesn't exist
ALTER TABLE player_videos
  ADD COLUMN IF NOT EXISTS video_type TEXT NOT NULL DEFAULT 'highlight';

-- Drop old video_type constraint if it exists (from migration 072 attempt)
ALTER TABLE player_videos DROP CONSTRAINT IF EXISTS player_videos_video_type_check;

-- Add proper constraint
ALTER TABLE player_videos
  ADD CONSTRAINT player_videos_video_type_check
  CHECK (video_type IN ('highlight', 'game_film'));

-- Add unique constraint so upsert onConflict works
ALTER TABLE player_videos DROP CONSTRAINT IF EXISTS player_videos_player_video_type_unique;
ALTER TABLE player_videos
  ADD CONSTRAINT player_videos_player_video_type_unique
  UNIQUE (player_id, video_type);

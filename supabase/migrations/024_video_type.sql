-- Add video_type to player_videos to distinguish highlights from game film
ALTER TABLE player_videos
  ADD COLUMN video_type TEXT NOT NULL DEFAULT 'highlight'
    CHECK (video_type IN ('highlight', 'game_film'));

-- Existing rows are all highlights
UPDATE player_videos SET video_type = 'highlight' WHERE video_type IS NULL;

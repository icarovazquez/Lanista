-- Migration 050: Extend YouTube video update to ALL players (not just @lanista.test).
-- Migration 049 only caught the 37 players with @lanista.test emails.
-- The players table has additional seeded records; this covers all of them.
-- URL: https://www.youtube.com/watch?v=uFXyuraHqJg

-- ── 1. Update ALL existing highlight videos to real YouTube URL ───────────────
UPDATE public.player_videos
SET
  source       = 'youtube',
  external_url = 'https://www.youtube.com/watch?v=uFXyuraHqJg',
  video_type   = 'highlight',
  is_primary   = true
WHERE video_type = 'highlight';

-- ── 2. Remove duplicate or stale game_film entries inserted by mig 049 ────────
DELETE FROM public.player_videos WHERE video_type = 'game_film';

-- ── 3. Insert ONE game_film entry for every player that doesn't have one ──────
INSERT INTO public.player_videos (player_id, title, source, external_url, is_primary, video_type, analysis_status)
SELECT
  pl.id,
  '2025-26 Full Game – ' || COALESCE(u.first_name || ' ' || u.last_name, 'Player'),
  'youtube',
  'https://www.youtube.com/watch?v=uFXyuraHqJg',
  false,
  'game_film',
  'pending'
FROM public.players pl
LEFT JOIN public.users u ON u.id = pl.user_id;

-- ── 4. Ensure every player has exactly one highlight video ────────────────────
-- Insert a highlight for any player that has no video at all
INSERT INTO public.player_videos (player_id, title, source, external_url, is_primary, video_type, analysis_status)
SELECT
  pl.id,
  '2025-26 Highlights – ' || COALESCE(u.first_name || ' ' || u.last_name, 'Player'),
  'youtube',
  'https://www.youtube.com/watch?v=uFXyuraHqJg',
  true,
  'highlight',
  'pending'
FROM public.players pl
LEFT JOIN public.users u ON u.id = pl.user_id
WHERE NOT EXISTS (
  SELECT 1 FROM public.player_videos pv
  WHERE pv.player_id = pl.id AND pv.video_type = 'highlight'
);

-- ── Verify ────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  total_players    INT;
  highlight_count  INT;
  film_count       INT;
BEGIN
  SELECT count(*) INTO total_players FROM public.players;
  SELECT count(*) INTO highlight_count FROM public.player_videos WHERE video_type = 'highlight' AND source = 'youtube';
  SELECT count(*) INTO film_count     FROM public.player_videos WHERE video_type = 'game_film'  AND source = 'youtube';

  RAISE NOTICE 'Total players: %', total_players;
  RAISE NOTICE 'Highlight videos (youtube): %', highlight_count;
  RAISE NOTICE 'Game film videos (youtube): %', film_count;
END $$;

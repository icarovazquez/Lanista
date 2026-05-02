-- Migration 049: Replace all fake Hudl highlight URLs with a real YouTube video
-- and add a matching game_film entry for every seeded player.
-- URL: https://www.youtube.com/watch?v=uFXyuraHqJg (Kieran Ross / real match film)

-- ── 1. Update all existing highlight videos to the real YouTube URL ────────────
UPDATE public.player_videos
SET
  source       = 'youtube',
  external_url = 'https://www.youtube.com/watch?v=uFXyuraHqJg',
  title        = '2025-26 Highlights – ' || (
                   SELECT u.first_name || ' ' || u.last_name
                   FROM public.players pl
                   JOIN public.users u ON u.id = pl.user_id
                   WHERE pl.id = player_videos.player_id
                 ),
  video_type   = 'highlight',
  is_primary   = true
WHERE player_id IN (
  SELECT pl.id
  FROM public.players pl
  JOIN public.users u ON u.id = pl.user_id
  WHERE u.email LIKE '%@lanista.test'
);

-- ── 2. Remove any existing game_film entries for seeded players ───────────────
DELETE FROM public.player_videos
WHERE video_type = 'game_film'
  AND player_id IN (
    SELECT pl.id
    FROM public.players pl
    JOIN public.users u ON u.id = pl.user_id
    WHERE u.email LIKE '%@lanista.test'
  );

-- ── 3. Insert a game_film entry for every seeded player ───────────────────────
INSERT INTO public.player_videos (player_id, title, source, external_url, is_primary, video_type, analysis_status)
SELECT
  pl.id,
  '2025-26 Full Game – ' || u.first_name || ' ' || u.last_name,
  'youtube',
  'https://www.youtube.com/watch?v=uFXyuraHqJg',
  false,
  'game_film',
  'pending'
FROM public.players pl
JOIN public.users u ON u.id = pl.user_id
WHERE u.email LIKE '%@lanista.test';

-- ── Verify ────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  highlight_count INT;
  film_count      INT;
BEGIN
  SELECT count(*) INTO highlight_count
  FROM public.player_videos pv
  JOIN public.players pl ON pl.id = pv.player_id
  JOIN public.users u ON u.id = pl.user_id
  WHERE u.email LIKE '%@lanista.test'
    AND pv.video_type = 'highlight'
    AND pv.source = 'youtube';

  SELECT count(*) INTO film_count
  FROM public.player_videos pv
  JOIN public.players pl ON pl.id = pv.player_id
  JOIN public.users u ON u.id = pl.user_id
  WHERE u.email LIKE '%@lanista.test'
    AND pv.video_type = 'game_film'
    AND pv.source = 'youtube';

  RAISE NOTICE 'Highlight videos updated: %', highlight_count;
  RAISE NOTICE 'Game film videos inserted: %', film_count;
END $$;

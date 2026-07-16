-- Remove match records for coaches that are not published.
-- These accumulate when coaches are unpublished after the engine has already run.
DELETE FROM player_coach_matches pcm
WHERE NOT EXISTS (
  SELECT 1 FROM coaches c
  WHERE c.id = pcm.coach_id AND c.is_published = TRUE
);

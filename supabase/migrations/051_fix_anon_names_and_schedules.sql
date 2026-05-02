-- Migration 051: Fix anonymous player names + add club affiliations for schedule visibility
--
-- Problem 1: 105 players seeded via seed_100_players.dart show "Anonymous Player"
--   because the handle_new_user trigger fired with empty raw_user_meta_data,
--   and ON CONFLICT DO NOTHING blocked the subsequent name update.
--   Fix: derive first/last name from email (format: firstname.lastname.NNN@lanista.test).
--
-- Problem 2: The 12 original players (migration 018) and all 105 Dart-seeded players
--   have no player_club_affiliations, so the schedule page shows nothing for them.
--   Fix: assign each unaffiliated player to a matching league_clubs entry.

-- ── 1. Fix anonymous player names ─────────────────────────────────────────────
UPDATE public.users
SET
  first_name = initcap(split_part(split_part(email, '@', 1), '.', 1)),
  last_name  = initcap(split_part(split_part(email, '@', 1), '.', 2))
WHERE role = 'player'
  AND (
    first_name IS NULL
    OR trim(first_name) = ''
  );

-- ── 2. Add player_club_affiliations for all players missing one ───────────────
-- Picks the first league_clubs entry that matches the player's gender.
-- Graduation year → age group: 2026=U18, 2027=U17, 2028=U16, else U15.
INSERT INTO public.player_club_affiliations
  (player_id, club_id, age_group, season, is_active)
SELECT
  p.id,
  (
    SELECT lc.id
    FROM public.league_clubs lc
    WHERE lc.gender IN (
      CASE WHEN p.gender = 'male' THEN 'male' ELSE 'female' END,
      'both'
    )
    ORDER BY lc.club_name   -- deterministic order so reruns give same result
    LIMIT 1
  ),
  CASE
    WHEN p.graduation_year <= 2026 THEN 'U18'
    WHEN p.graduation_year = 2027  THEN 'U17'
    WHEN p.graduation_year = 2028  THEN 'U16'
    ELSE 'U15'
  END,
  '2025-2026',
  true
FROM public.players p
WHERE NOT EXISTS (
  SELECT 1 FROM public.player_club_affiliations pca
  WHERE pca.player_id = p.id
)
-- Only insert if the subquery found a matching club (avoids NULL club_id violation)
AND EXISTS (
  SELECT 1 FROM public.league_clubs lc
  WHERE lc.gender IN (
    CASE WHEN p.gender = 'male' THEN 'male' ELSE 'female' END,
    'both'
  )
);

-- ── Verify ────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  anon_remaining   INT;
  no_affiliation   INT;
BEGIN
  SELECT count(*) INTO anon_remaining
  FROM public.users u
  JOIN public.players p ON p.user_id = u.id
  WHERE trim(u.first_name) = '' OR u.first_name IS NULL;

  SELECT count(*) INTO no_affiliation
  FROM public.players p
  WHERE NOT EXISTS (
    SELECT 1 FROM public.player_club_affiliations pca WHERE pca.player_id = p.id
  );

  RAISE NOTICE 'Players still with empty name: %', anon_remaining;
  RAISE NOTICE 'Players still without club affiliation: %', no_affiliation;
END $$;

-- Migration 054: Ensure onboarding_complete = true for all seeded players
-- Seeded players have full profile data and should bypass the setup flow.

UPDATE public.users
SET onboarding_complete = true
WHERE role = 'player'
  AND email LIKE '%@lanista.test';

DO $$
DECLARE
  fixed_count INT;
BEGIN
  SELECT COUNT(*) INTO fixed_count
  FROM public.users
  WHERE role = 'player'
    AND email LIKE '%@lanista.test'
    AND onboarding_complete = true;

  RAISE NOTICE 'Players with onboarding_complete=true: %', fixed_count;
END $$;

-- Migration 048: Set onboarding_complete = true for all seeded coaches
-- The app gates Matches tab and Dashboard blueprint card behind this flag.
-- It must be true in BOTH public.users AND public.coaches.

-- Fix public.users
UPDATE public.users
SET onboarding_complete = true
WHERE id IN (
  SELECT user_id FROM public.coaches
  WHERE id::text LIKE 'c3000000%'
);

-- Fix public.coaches
UPDATE public.coaches
SET onboarding_complete = true
WHERE id::text LIKE 'c3000000%';

-- Verify
DO $$
DECLARE
  users_fixed  INT;
  coaches_fixed INT;
BEGIN
  SELECT count(*) INTO users_fixed
  FROM public.users u
  JOIN public.coaches c ON c.user_id = u.id
  WHERE c.id::text LIKE 'c3000000%' AND u.onboarding_complete = true;

  SELECT count(*) INTO coaches_fixed
  FROM public.coaches
  WHERE id::text LIKE 'c3000000%' AND onboarding_complete = true;

  RAISE NOTICE 'users.onboarding_complete=true: %/20', users_fixed;
  RAISE NOTICE 'coaches.onboarding_complete=true: %/20', coaches_fixed;
END $$;

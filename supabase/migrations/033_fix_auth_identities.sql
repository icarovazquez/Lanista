-- Migration 033: Add missing auth.identities for seeded coach accounts
--
-- Supabase requires a record in auth.identities for email/password login.
-- Migration 023 inserted into auth.users but skipped auth.identities,
-- causing "invalid credentials" errors for all seeded coaches.

INSERT INTO auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  gen_random_uuid(),
  id,
  email,
  jsonb_build_object('sub', id::text, 'email', email),
  'email',
  NOW(),
  NOW(),
  NOW()
FROM auth.users
WHERE email LIKE '%@lanista.test'
  AND id NOT IN (
    SELECT user_id FROM auth.identities WHERE provider = 'email'
  );

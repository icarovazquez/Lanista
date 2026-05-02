-- Migration 043: Fix auth.identities for coaches
-- Problem: provider_id was set to email (our bug in migration 035)
-- GoTrue expects provider_id = user's UUID (as text) for email provider
-- Also fix identity_data to match GoTrue format, and user metadata

-- Fix identities: set provider_id = user UUID (not email)
UPDATE auth.identities i
SET
  provider_id    = u.id::text,
  identity_data  = jsonb_build_object(
    'sub',            u.id::text,
    'email',          u.email,
    'email_verified', false,
    'phone_verified', false
  ),
  updated_at     = NOW()
FROM auth.users u
WHERE i.user_id = u.id
  AND u.email LIKE '%coach.%@lanista.test';

-- Fix user_metadata to match GoTrue format
UPDATE auth.users
SET
  raw_user_meta_data = '{"email_verified": true}'::jsonb,
  updated_at         = NOW()
WHERE email LIKE '%coach.%@lanista.test';

-- Verify
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT u.email, i.provider_id,
           (i.provider_id = u.id::text) as provider_id_correct
    FROM auth.identities i
    JOIN auth.users u ON u.id = i.user_id
    WHERE u.email LIKE '%coach.%@lanista.test'
    LIMIT 3
  LOOP
    RAISE NOTICE 'coach=% provider_id=% correct=%', r.email, r.provider_id, r.provider_id_correct;
  END LOOP;
END $$;

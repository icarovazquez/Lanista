-- Migration 053: Fix auth for player accounts
-- Apply the same fixes as coaches (040, 043, 047) to player accounts.
-- Players use firstname.lastname@lanista.test format (no "coach." prefix).

-- 1. Fix instance_id (GoTrue filters by this, NULL = user not found)
UPDATE auth.users
SET instance_id = '00000000-0000-0000-0000-000000000000'
WHERE email LIKE '%@lanista.test'
  AND email NOT LIKE '%coach.%@lanista.test';

-- 2. Delete duplicate/incorrect identity rows where a correct one already exists
--    (some players have two identity rows: one correct, one with wrong provider_id)
DELETE FROM auth.identities i
USING auth.users u
WHERE i.user_id = u.id
  AND u.email LIKE '%@lanista.test'
  AND u.email NOT LIKE '%coach.%@lanista.test'
  AND i.provider_id != u.id::text
  AND EXISTS (
    SELECT 1 FROM auth.identities i2
    WHERE i2.user_id = u.id
      AND i2.provider_id = u.id::text
  );

-- 3. Update remaining identities where provider_id is still wrong
UPDATE auth.identities i
SET
  provider_id   = u.id::text,
  identity_data = jsonb_build_object(
    'sub',            u.id::text,
    'email',          u.email,
    'email_verified', false,
    'phone_verified', false
  ),
  updated_at    = NOW()
FROM auth.users u
WHERE i.user_id = u.id
  AND u.email LIKE '%@lanista.test'
  AND u.email NOT LIKE '%coach.%@lanista.test'
  AND i.provider_id != u.id::text;

-- 4. Fix null token fields and user metadata
UPDATE auth.users
SET
  confirmation_token         = COALESCE(confirmation_token, ''),
  recovery_token             = COALESCE(recovery_token, ''),
  reauthentication_token     = COALESCE(reauthentication_token, ''),
  email_change               = COALESCE(email_change, ''),
  email_change_token_new     = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  raw_user_meta_data         = '{"email_verified": true}'::jsonb,
  updated_at                 = NOW()
WHERE email LIKE '%@lanista.test'
  AND email NOT LIKE '%coach.%@lanista.test';

-- Verify
DO $$
DECLARE
  player_count  INT;
  identity_count INT;
BEGIN
  SELECT COUNT(*) INTO player_count
  FROM auth.users
  WHERE email LIKE '%@lanista.test'
    AND email NOT LIKE '%coach.%@lanista.test'
    AND instance_id = '00000000-0000-0000-0000-000000000000';

  SELECT COUNT(*) INTO identity_count
  FROM auth.identities i
  JOIN auth.users u ON u.id = i.user_id
  WHERE u.email LIKE '%@lanista.test'
    AND u.email NOT LIKE '%coach.%@lanista.test'
    AND i.provider_id = u.id::text;

  RAISE NOTICE 'Player accounts fixed: % users, % identities with correct provider_id', player_count, identity_count;
END $$;

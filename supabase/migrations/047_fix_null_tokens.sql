-- Migration 047: Fix NULL token fields that GoTrue can't scan into Go strings
-- GoTrue maps these columns to Go `string` (not *string), so NULL causes scan error.
-- phone has a UNIQUE constraint so we leave it NULL (like test.temp).

UPDATE auth.users SET
  confirmation_token         = COALESCE(confirmation_token, ''),
  recovery_token             = COALESCE(recovery_token, ''),
  reauthentication_token     = COALESCE(reauthentication_token, ''),
  email_change               = COALESCE(email_change, ''),
  email_change_token_new     = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  updated_at                 = NOW()
WHERE email LIKE '%coach.%@lanista.test';

-- Verify coach.daniels is now consistent with a GoTrue-created user
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT email,
      confirmation_token IS NULL as ct_null,
      recovery_token IS NULL as rt_null,
      email_change IS NULL as ec_null
    FROM auth.users
    WHERE email = 'coach.daniels@lanista.test'
  LOOP
    RAISE NOTICE 'coach.daniels: confirm_null=% recover_null=% email_change_null=%',
      r.ct_null, r.rt_null, r.ec_null;
  END LOOP;
END $$;

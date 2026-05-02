-- Migration 037: Clear soft-deleted state on coach auth users
-- GoTrue soft-deletes users via deleted_at. Previous migrations inserted/updated
-- the rows but didn't clear deleted_at, so GoTrue still treats them as deleted.

DO $$
DECLARE
  deleted_count INT;
  pw_hash TEXT := '$2b$10$xMI8e/IsHOcpjfi6wWCj/u6z381000etIhOCcCLW9SmWobtazukBG';
BEGIN
  SELECT count(*) INTO deleted_count
  FROM auth.users
  WHERE email LIKE '%coach.%@lanista.test' AND deleted_at IS NOT NULL;

  RAISE NOTICE 'Coach users with deleted_at set: %', deleted_count;

  -- Clear deleted_at and refresh password
  UPDATE auth.users
  SET
    deleted_at          = NULL,
    encrypted_password  = pw_hash,
    email_confirmed_at  = COALESCE(email_confirmed_at, NOW()),
    updated_at          = NOW()
  WHERE email LIKE '%coach.%@lanista.test';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'Updated % coach users (cleared deleted_at)', deleted_count;

  -- Ensure identities exist and are not soft-deleted either
  UPDATE auth.identities
  SET updated_at = NOW()
  WHERE user_id IN (
    SELECT id FROM auth.users WHERE email LIKE '%coach.%@lanista.test'
  );

  RAISE NOTICE 'Done. Try logging in now.';
END $$;

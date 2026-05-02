-- Migration 042: Compare test user (working) vs coach.daniels (broken)

DO $$
DECLARE
  r RECORD;
BEGIN
  -- Show auth.users rows for both
  RAISE NOTICE '=== auth.users comparison ===';
  FOR r IN
    SELECT
      email,
      instance_id,
      aud,
      role,
      email_confirmed_at IS NOT NULL as has_email_confirmed,
      confirmed_at IS NOT NULL as has_confirmed,
      is_sso_user,
      is_anonymous,
      deleted_at IS NULL as not_deleted,
      banned_until IS NULL as not_banned,
      length(encrypted_password) as pw_len,
      raw_app_meta_data,
      raw_user_meta_data
    FROM auth.users
    WHERE email IN ('test.temp@lanista.test', 'coach.daniels@lanista.test')
    ORDER BY email
  LOOP
    RAISE NOTICE 'user=%  instance=% aud=% role=% email_confirmed=% confirmed=% sso=% anon=% pw_len=%',
      r.email, r.instance_id, r.aud, r.role,
      r.has_email_confirmed, r.has_confirmed,
      r.is_sso_user, r.is_anonymous, r.pw_len;
    RAISE NOTICE '  app_meta=% user_meta=%', r.raw_app_meta_data, r.raw_user_meta_data;
  END LOOP;

  -- Show auth.identities for both
  RAISE NOTICE '=== auth.identities comparison ===';
  FOR r IN
    SELECT
      u.email as user_email,
      i.id as identity_id,
      i.user_id,
      i.provider,
      i.provider_id,
      i.identity_data,
      i.email as identity_email
    FROM auth.identities i
    JOIN auth.users u ON u.id = i.user_id
    WHERE u.email IN ('test.temp@lanista.test', 'coach.daniels@lanista.test')
    ORDER BY u.email
  LOOP
    RAISE NOTICE 'identity for %: id=% provider=% provider_id=% email=%',
      r.user_email, r.identity_id, r.provider, r.provider_id, r.identity_email;
    RAISE NOTICE '  identity_data=%', r.identity_data;
  END LOOP;

  -- Specifically check: does coach.daniels identity have same structure as test user?
  -- GoTrue for email auth sets provider_id = user's UUID (not email)
  RAISE NOTICE '=== provider_id check ===';
  FOR r IN
    SELECT u.email, u.id, i.provider_id,
           (i.provider_id = u.id::text) as provider_id_matches_user_id,
           (i.provider_id = u.email) as provider_id_is_email
    FROM auth.identities i
    JOIN auth.users u ON u.id = i.user_id
    WHERE u.email IN ('test.temp@lanista.test', 'coach.daniels@lanista.test')
    ORDER BY u.email
  LOOP
    RAISE NOTICE 'user=% provider_id_is_user_uuid=% provider_id_is_email=%',
      r.email, r.provider_id_matches_user_id, r.provider_id_is_email;
  END LOOP;
END $$;

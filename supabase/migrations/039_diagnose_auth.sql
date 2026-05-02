-- Migration 039: Diagnose auth.users visibility

DO $$
DECLARE
  r RECORD;
  cnt INT;
BEGIN
  -- Check if auth.users is a table or view
  SELECT table_type INTO r FROM information_schema.tables
  WHERE table_schema = 'auth' AND table_name = 'users';
  RAISE NOTICE 'auth.users type: %', r.table_type;

  -- Check RLS
  SELECT relrowsecurity INTO r FROM pg_class
  WHERE relname = 'users' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth');
  RAISE NOTICE 'auth.users RLS enabled: %', r.relrowsecurity;

  -- Check columns including is_sso_user
  FOR r IN SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users'
    ORDER BY ordinal_position
  LOOP
    RAISE NOTICE 'column: %', r.column_name;
  END LOOP;

  -- Check what coach.daniels row looks like
  FOR r IN SELECT id, email, email_confirmed_at, deleted_at, is_sso_user,
                  banned_until, confirmation_token, recovery_token,
                  length(encrypted_password) as pw_len
           FROM auth.users WHERE email = 'coach.daniels@lanista.test'
  LOOP
    RAISE NOTICE 'coach.daniels: id=% confirmed=% deleted=% sso=% banned=% pw_len=%',
      r.id, r.email_confirmed_at, r.deleted_at, r.is_sso_user, r.banned_until, r.pw_len;
  END LOOP;
END $$;

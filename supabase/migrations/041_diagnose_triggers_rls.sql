-- Migration 041: Check triggers and RLS policies on auth.users

DO $$
DECLARE
  r RECORD;
BEGIN
  -- Check triggers on auth.users
  RAISE NOTICE '=== TRIGGERS ON auth.users ===';
  FOR r IN
    SELECT trigger_name, event_manipulation, action_timing, action_statement
    FROM information_schema.triggers
    WHERE event_object_schema = 'auth' AND event_object_table = 'users'
    ORDER BY trigger_name
  LOOP
    RAISE NOTICE 'trigger: % % % %', r.trigger_name, r.event_manipulation, r.action_timing, r.action_statement;
  END LOOP;

  -- Check RLS policies on auth.users
  RAISE NOTICE '=== RLS POLICIES ON auth.users ===';
  FOR r IN
    SELECT polname, polcmd, polroles, polqual::text, polwithcheck::text
    FROM pg_policy
    WHERE polrelid = 'auth.users'::regclass
    ORDER BY polname
  LOOP
    RAISE NOTICE 'policy: % cmd=% roles=%', r.polname, r.polcmd, r.polroles;
  END LOOP;

  -- Check what roles can bypass RLS on auth.users
  RAISE NOTICE '=== GRANTS ON auth.users ===';
  FOR r IN
    SELECT grantee, privilege_type
    FROM information_schema.role_table_grants
    WHERE table_schema = 'auth' AND table_name = 'users'
    ORDER BY grantee, privilege_type
  LOOP
    RAISE NOTICE 'grant: % can %', r.grantee, r.privilege_type;
  END LOOP;

  -- Check is_anonymous column value and any other potentially blocking fields
  RAISE NOTICE '=== FULL ROW for coach.daniels ===';
  FOR r IN
    SELECT id, email, aud, role, instance_id,
           email_confirmed_at, confirmed_at,
           is_sso_user, is_anonymous, deleted_at, banned_until,
           length(encrypted_password) as pw_len,
           raw_app_meta_data, raw_user_meta_data
    FROM auth.users
    WHERE email = 'coach.daniels@lanista.test'
  LOOP
    RAISE NOTICE 'id=% aud=% role=% instance=% confirmed=% is_anon=% pw_len=%',
      r.id, r.aud, r.role, r.instance_id, r.confirmed_at, r.is_anonymous, r.pw_len;
    RAISE NOTICE 'app_meta=% user_meta=%', r.raw_app_meta_data, r.raw_user_meta_data;
  END LOOP;
END $$;

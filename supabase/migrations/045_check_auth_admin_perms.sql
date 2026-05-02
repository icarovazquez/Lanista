-- Migration 045: Check supabase_auth_admin permissions on auth.users

DO $$
DECLARE
  r RECORD;
  owns_auth BOOLEAN;
BEGIN
  -- Check who owns auth.users
  RAISE NOTICE '=== OWNERSHIP ===';
  SELECT rolname INTO r FROM pg_roles
  WHERE oid = (
    SELECT relowner FROM pg_class
    WHERE relname = 'users'
      AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth')
  );
  RAISE NOTICE 'auth.users owner: %', r.rolname;

  -- Check if supabase_auth_admin exists and its attributes
  RAISE NOTICE '=== supabase_auth_admin ROLE ===';
  FOR r IN
    SELECT rolname, rolsuper, rolcreatedb, rolbypassrls, rolinherit
    FROM pg_roles WHERE rolname = 'supabase_auth_admin'
  LOOP
    RAISE NOTICE 'role: % super=% bypassrls=% inherit=%',
      r.rolname, r.rolsuper, r.rolbypassrls, r.rolinherit;
  END LOOP;

  -- Try to SET ROLE to supabase_auth_admin and query
  RAISE NOTICE '=== QUERYING AS supabase_auth_admin ===';
  BEGIN
    SET LOCAL ROLE 'supabase_auth_admin';
    FOR r IN
      SELECT id, email FROM auth.users
      WHERE email = 'coach.daniels@lanista.test'
    LOOP
      RAISE NOTICE 'supabase_auth_admin can see: %', r.email;
    END LOOP;
    RESET ROLE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'supabase_auth_admin query FAILED: %', SQLERRM;
    RESET ROLE;
  END;

  -- Check GRANTS specifically for supabase_auth_admin
  RAISE NOTICE '=== GRANTS FOR supabase_auth_admin ===';
  FOR r IN
    SELECT privilege_type, is_grantable
    FROM information_schema.role_table_grants
    WHERE table_schema = 'auth'
      AND table_name = 'users'
      AND grantee = 'supabase_auth_admin'
  LOOP
    RAISE NOTICE 'grant: % grantable=%', r.privilege_type, r.is_grantable;
  END LOOP;
END $$;

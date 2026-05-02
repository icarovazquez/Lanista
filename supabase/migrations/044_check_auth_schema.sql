-- Migration 044: Check all tables in auth schema

DO $$
DECLARE
  r RECORD;
BEGIN
  RAISE NOTICE '=== ALL TABLES IN auth SCHEMA ===';
  FOR r IN
    SELECT table_name, table_type
    FROM information_schema.tables
    WHERE table_schema = 'auth'
    ORDER BY table_name
  LOOP
    RAISE NOTICE 'auth.%: %', r.table_name, r.table_type;
  END LOOP;

  -- Try to directly query what GoTrue would query for a user by ID
  -- GoTrue uses supabase_auth_admin role - let's try a simple direct query
  RAISE NOTICE '=== TRYING DIRECT QUERY as postgres ===';
  FOR r IN
    SELECT u.id, u.email,
           (SELECT count(*) FROM auth.identities i WHERE i.user_id = u.id) as identity_count
    FROM auth.users u
    WHERE u.id = 'b2000000-0000-0000-0000-000000000001'::uuid
  LOOP
    RAISE NOTICE 'result: id=% email=% identities=%', r.id, r.email, r.identity_count;
  END LOOP;
END $$;

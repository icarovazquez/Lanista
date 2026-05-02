-- Migration 046: Check FORCE ROW SECURITY on auth.users
-- If relforcerowsecurity=t AND no policies exist → ALL rows hidden, even for owner

DO $$
DECLARE
  r RECORD;
BEGIN
  SELECT relrowsecurity, relforcerowsecurity
  INTO r
  FROM pg_class
  WHERE relname = 'users'
    AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth');

  RAISE NOTICE 'auth.users: RLS=% FORCE_RLS=%', r.relrowsecurity, r.relforcerowsecurity;

  -- If force RLS is enabled, disable it so owner (supabase_auth_admin) can access all rows
  IF r.relforcerowsecurity THEN
    RAISE NOTICE 'FORCE ROW SECURITY is ON — this blocks ALL access including table owner!';
    ALTER TABLE auth.users NO FORCE ROW SECURITY;
    RAISE NOTICE 'Disabled FORCE ROW SECURITY on auth.users';
  ELSE
    RAISE NOTICE 'FORCE ROW SECURITY is OFF — not the issue';
  END IF;

  -- Verify fix
  SELECT relrowsecurity, relforcerowsecurity
  INTO r
  FROM pg_class
  WHERE relname = 'users'
    AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth');
  RAISE NOTICE 'After: RLS=% FORCE_RLS=%', r.relrowsecurity, r.relforcerowsecurity;
END $$;

-- Migration 071: Fix RLS policies that use auth.jwt() ->> 'user_role'
-- Replace JWT-claim approach with a SECURITY DEFINER function that reads
-- the role directly from public.users without triggering RLS recursion.

-- 1. Create a helper function that reads the current user's role
--    SECURITY DEFINER bypasses RLS so there's no infinite recursion.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role::text FROM public.users WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated, anon;

-- 2. Recreate the affected policies using get_my_role() instead of JWT claims

-- users table: coaches can read player user records
DROP POLICY IF EXISTS "coaches_read_player_users" ON users;
CREATE POLICY "coaches_read_player_users"
  ON users FOR SELECT
  USING (
    role = 'player'
    AND public.get_my_role() = 'coach'
  );

-- users table: players can read coach user records
DROP POLICY IF EXISTS "players_read_coach_users" ON users;
CREATE POLICY "players_read_coach_users"
  ON users FOR SELECT
  USING (
    role = 'coach'
    AND public.get_my_role() = 'player'
  );

-- users table: any authenticated user can read mentor records (if policy exists)
DROP POLICY IF EXISTS "authenticated_read_mentor_users" ON users;
CREATE POLICY "authenticated_read_mentor_users"
  ON users FOR SELECT
  USING (
    role = 'mentor'
    AND auth.uid() IS NOT NULL
  );

-- users table: any authenticated user can read parent records (if policy exists)
DROP POLICY IF EXISTS "authenticated_read_parent_users" ON users;
CREATE POLICY "authenticated_read_parent_users"
  ON users FOR SELECT
  USING (
    role = 'parent'
    AND auth.uid() IS NOT NULL
  );

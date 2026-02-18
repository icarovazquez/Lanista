-- Simplify cross-user RLS to avoid any recursion issues.
-- During development, allow authenticated users to read other users' basic info.
-- We'll tighten this down in production with proper JWT claims.

DROP POLICY IF EXISTS "coaches_read_player_users" ON users;
DROP POLICY IF EXISTS "players_read_coach_users" ON users;

-- Any authenticated user can read other users' basic public info
-- (role, first_name, last_name, avatar_url) - needed for messaging, search, etc.
CREATE POLICY "authenticated_read_users"
  ON users FOR SELECT
  USING (auth.uid() IS NOT NULL);

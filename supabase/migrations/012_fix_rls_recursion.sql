-- Fix recursive RLS policies on users table.
-- The original policies query the users table FROM WITHIN a users policy,
-- causing infinite recursion. Replace with auth.jwt() claims instead.

-- Drop the recursive policies
DROP POLICY IF EXISTS "coaches_read_player_users" ON users;
DROP POLICY IF EXISTS "players_read_coach_users" ON users;
DROP POLICY IF EXISTS "mentors_read_assigned_players" ON users;
DROP POLICY IF EXISTS "parents_read_linked_players" ON users;

-- Coaches can read player users (use auth.jwt() to avoid recursion)
CREATE POLICY "coaches_read_player_users"
  ON users FOR SELECT
  USING (
    role = 'player'
    AND (auth.jwt() ->> 'user_role') = 'coach'
  );

-- Players can read coach users (use auth.jwt() to avoid recursion)
CREATE POLICY "players_read_coach_users"
  ON users FOR SELECT
  USING (
    role = 'coach'
    AND (auth.jwt() ->> 'user_role') = 'player'
  );

-- Mentors can read their assigned players
CREATE POLICY "mentors_read_assigned_players"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM mentor_player_relationships mpr
      WHERE mpr.mentor_id = auth.uid()
        AND mpr.player_id = users.id
        AND mpr.status = 'active'
    )
  );

-- Parents can read their linked players
CREATE POLICY "parents_read_linked_players"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM parent_player_relationships ppr
      WHERE ppr.parent_id = auth.uid()
        AND ppr.player_id = users.id
    )
  );

-- Also add WITH CHECK to the update policy to be explicit
DROP POLICY IF EXISTS "users_update_own" ON users;
CREATE POLICY "users_update_own"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

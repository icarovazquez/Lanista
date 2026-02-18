-- 014 · Fix players RLS so users can INSERT their own row
-- The existing "players_own_profile" FOR ALL policy only has a USING clause,
-- which applies to SELECT/UPDATE/DELETE but NOT INSERT.
-- We need a WITH CHECK clause for INSERT to work.

DROP POLICY IF EXISTS "players_own_profile" ON players;

CREATE POLICY "players_own_profile"
  ON players FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

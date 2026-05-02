-- contact_window_valid defaults to FALSE but players should always be able
-- to initiate contact with coaches.  There was also no UPDATE policy so the
-- app could never re-open a closed window.
--
-- This migration:
--  1. Changes the default to TRUE (player-initiated messaging is always open)
--  2. Opens all existing conversations
--  3. Adds an UPDATE policy so participants can manage the window

ALTER TABLE conversations
  ALTER COLUMN contact_window_valid SET DEFAULT TRUE;

UPDATE conversations SET contact_window_valid = TRUE;

-- Allow participants to update conversation metadata (contact window, status)
CREATE POLICY "conversation_update"
  ON conversations FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM players WHERE id = conversations.player_id AND user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM coaches WHERE id = conversations.coach_id AND user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM players WHERE id = conversations.player_id AND user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM coaches WHERE id = conversations.coach_id AND user_id = auth.uid())
  );

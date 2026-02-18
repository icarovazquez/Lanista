-- ─────────────────────────────────────────────────────────────────────────────
-- 009 · Schema Reconciliation
-- Aligns the messaging schema with what the Flutter app expects:
--   • messages.body (was: content)
--   • messages.created_at (was: sent_at)
--   • messages.approved_at TIMESTAMPTZ (was: parent_approved BOOLEAN)
--   • messages.read_at TIMESTAMPTZ (was: is_read BOOLEAN)
--   • conversations.contact_window_open (was: contact_window_valid)
--   • conversations.player_id now references users(id) directly for RLS clarity
-- Also adds missing columns the app writes/reads.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── conversations ─────────────────────────────────────────────────────────────

-- Add contact_window_open alias column (keep contact_window_valid for backcompat)
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS contact_window_open BOOLEAN NOT NULL DEFAULT TRUE;

-- Sync existing rows
UPDATE conversations SET contact_window_open = contact_window_valid;

-- ── messages ─────────────────────────────────────────────────────────────────

-- Add body column (app sends this; backfill from content)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS body TEXT;

UPDATE messages SET body = content WHERE body IS NULL;

-- Make body non-null after backfill
ALTER TABLE messages
  ALTER COLUMN body SET NOT NULL;

-- Add created_at column (was sent_at)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Backfill from sent_at
UPDATE messages SET created_at = sent_at WHERE created_at = NOW();

-- Add read_at timestamp (app sets this when marking read)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- Add approved_at timestamp (replaces parent_approved boolean)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- Backfill: if parent_approved was true, set approved_at to sent_at
UPDATE messages
  SET approved_at = sent_at
  WHERE parent_approved = TRUE AND approved_at IS NULL;

-- ── coaches: add state column used by player search ───────────────────────────
ALTER TABLE coaches
  ADD COLUMN IF NOT EXISTS state TEXT;

-- ── coaches: add is_published column ─────────────────────────────────────────
ALTER TABLE coaches
  ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT FALSE;

-- ── players: add birth_year for COPPA minor detection ─────────────────────────
ALTER TABLE players
  ADD COLUMN IF NOT EXISTS birth_year INTEGER;

-- ── Indexes for search performance ───────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON messages (conversation_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_conversations_player_coach
  ON conversations (player_id, coach_id);

CREATE INDEX IF NOT EXISTS idx_players_position_year
  ON players (primary_position, graduation_year);

CREATE INDEX IF NOT EXISTS idx_coaches_division_state
  ON coaches (division, state);

CREATE INDEX IF NOT EXISTS idx_coaches_published
  ON coaches (is_published) WHERE is_published = TRUE;

-- ── messages UPDATE policy (for marking read) ────────────────────────────────
CREATE POLICY IF NOT EXISTS "messages_update_read"
  ON messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      JOIN players pl ON pl.id = c.player_id
      JOIN coaches co ON co.id = c.coach_id
      WHERE c.id = messages.conversation_id
        AND (pl.user_id = auth.uid() OR co.user_id = auth.uid())
    )
  )
  WITH CHECK (sender_id != auth.uid()); -- can only mark others' messages read

-- ── conversations UPDATE policy (for setting contact_window_open) ─────────────
CREATE POLICY IF NOT EXISTS "conversation_update_window"
  ON conversations FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM coaches WHERE id = conversations.coach_id AND user_id = auth.uid())
  );

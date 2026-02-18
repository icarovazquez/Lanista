-- 009 · Schema Reconciliation
-- Aligns messaging schema with Flutter app expectations.
-- Indexes and policies are in 010_indexes_and_policies.sql

-- conversations
ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS contact_window_open BOOLEAN NOT NULL DEFAULT TRUE;
UPDATE conversations SET contact_window_open = contact_window_valid;

-- messages
ALTER TABLE messages ADD COLUMN IF NOT EXISTS body TEXT;
UPDATE messages SET body = content WHERE body IS NULL;
ALTER TABLE messages ALTER COLUMN body SET NOT NULL;

ALTER TABLE messages ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
UPDATE messages SET created_at = sent_at WHERE created_at = NOW();

ALTER TABLE messages ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
UPDATE messages SET approved_at = sent_at WHERE parent_approved = TRUE AND approved_at IS NULL;

-- coaches
ALTER TABLE coaches ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE coaches ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT FALSE;

-- players
ALTER TABLE players ADD COLUMN IF NOT EXISTS birth_year INTEGER;

-- indexes (safe ones only — positions are in player_positions join table)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON messages (conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_conversations_player_coach ON conversations (player_id, coach_id);

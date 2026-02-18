-- Conversation threads
CREATE TABLE conversations (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id               UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  coach_id                UUID NOT NULL REFERENCES coaches(id) ON DELETE CASCADE,
  contact_window_valid    BOOLEAN NOT NULL DEFAULT FALSE,
  initiated_by            TEXT NOT NULL CHECK (initiated_by IN ('player', 'coach')),
  status                  TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'blocked')),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (player_id, coach_id)
);

-- Individual messages
CREATE TABLE messages (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id             UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id                   UUID NOT NULL REFERENCES users(id),
  content                     TEXT NOT NULL,
  is_read                     BOOLEAN NOT NULL DEFAULT FALSE,
  requires_parent_approval    BOOLEAN NOT NULL DEFAULT FALSE,
  parent_approved             BOOLEAN,
  sent_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Participants can see their conversations
CREATE POLICY "conversation_participants"
  ON conversations FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM players WHERE id = conversations.player_id AND user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM coaches WHERE id = conversations.coach_id AND user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM parent_player_relationships ppr
      JOIN players p ON p.user_id = ppr.player_id
      WHERE ppr.parent_id = auth.uid() AND p.id = conversations.player_id
    )
  );

CREATE POLICY "conversation_create"
  ON conversations FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM players WHERE id = conversations.player_id AND user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM coaches WHERE id = conversations.coach_id AND user_id = auth.uid())
  );

-- Messages
CREATE POLICY "messages_participants"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      JOIN players pl ON pl.id = c.player_id
      JOIN coaches co ON co.id = c.coach_id
      WHERE c.id = messages.conversation_id
        AND (pl.user_id = auth.uid() OR co.user_id = auth.uid())
    )
  );

CREATE POLICY "messages_send"
  ON messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

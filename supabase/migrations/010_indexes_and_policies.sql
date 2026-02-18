-- 010 · Indexes and Policies
-- Adds denormalized search columns to coaches, performance indexes, and RLS policies.

-- ── Denormalize division + school_name + state onto coaches for fast search ───
-- (coaches.college_id → colleges.name/state, coaches.college_id → colleges.division_id → divisions)
ALTER TABLE coaches
  ADD COLUMN IF NOT EXISTS school_name TEXT,
  ADD COLUMN IF NOT EXISTS division    TEXT,
  ADD COLUMN IF NOT EXISTS primary_formation TEXT,
  ADD COLUMN IF NOT EXISTS playing_style    TEXT;

-- Backfill school_name and state from colleges table
UPDATE coaches c
SET
  school_name = col.name,
  state       = col.state
FROM colleges col
WHERE col.id = c.college_id
  AND c.school_name IS NULL;

-- ── Indexes ───────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_players_graduation_year
  ON players (graduation_year);

CREATE INDEX IF NOT EXISTS idx_players_birth_year
  ON players (birth_year);

CREATE INDEX IF NOT EXISTS idx_player_positions_position
  ON player_positions (position_id);

CREATE INDEX IF NOT EXISTS idx_coaches_division_state
  ON coaches (division, state);

CREATE INDEX IF NOT EXISTS idx_coaches_published
  ON coaches (is_published) WHERE is_published = TRUE;

CREATE INDEX IF NOT EXISTS idx_coaches_school_name
  ON coaches USING gin (to_tsvector('english', coalesce(school_name, '')));

-- ── RLS Policies ──────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND policyname = 'messages_update_read'
  ) THEN
    CREATE POLICY "messages_update_read"
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
      WITH CHECK (sender_id != auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'conversations' AND policyname = 'conversation_update_window'
  ) THEN
    CREATE POLICY "conversation_update_window"
      ON conversations FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM coaches
          WHERE id = conversations.coach_id AND user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'players' AND policyname = 'coaches_read_players'
  ) THEN
    CREATE POLICY "coaches_read_players"
      ON players FOR SELECT
      USING (
        EXISTS (SELECT 1 FROM coaches WHERE user_id = auth.uid())
        OR user_id = auth.uid()
      );
  END IF;
END $$;

-- coaches: anyone can read published coaches
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'coaches' AND policyname = 'coaches_public_read'
  ) THEN
    CREATE POLICY "coaches_public_read"
      ON coaches FOR SELECT
      USING (is_published = TRUE OR user_id = auth.uid());
  END IF;
END $$;

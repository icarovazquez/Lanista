-- Core users table (synced with Supabase Auth)
CREATE TABLE users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  role          user_role NOT NULL,
  first_name    TEXT NOT NULL DEFAULT '',
  last_name     TEXT NOT NULL DEFAULT '',
  avatar_url    TEXT,
  language      TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'es')),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Parent <-> Player relationships
CREATE TABLE parent_player_relationships (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  player_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  control_mode          control_mode NOT NULL DEFAULT 'parent_led',
  parent_can_message    BOOLEAN NOT NULL DEFAULT TRUE,
  parent_can_override   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (parent_id, player_id)
);

-- Mentor <-> Player relationships
CREATE TABLE mentor_player_relationships (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mentor_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  player_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_level  permission_level NOT NULL DEFAULT 'read_only',
  status            relationship_status NOT NULL DEFAULT 'pending',
  approved_by       UUID REFERENCES users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (mentor_id, player_id)
);

-- RLS Policies for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own record
CREATE POLICY "users_read_own"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own record
CREATE POLICY "users_update_own"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own record
CREATE POLICY "users_insert_own"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Coaches can read basic info of discoverable players
CREATE POLICY "coaches_read_player_users"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'coach'
    )
    AND role = 'player'
  );

-- Players can read basic coach info
CREATE POLICY "players_read_coach_users"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'player'
    )
    AND role = 'coach'
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

-- RLS for relationships tables
ALTER TABLE parent_player_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_player_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "parent_player_own"
  ON parent_player_relationships FOR ALL
  USING (parent_id = auth.uid() OR player_id = auth.uid());

CREATE POLICY "mentor_player_own"
  ON mentor_player_relationships FOR ALL
  USING (mentor_id = auth.uid() OR player_id = auth.uid());

-- Trigger to auto-create user record after auth signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    'player', -- Default role, updated on role selection
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

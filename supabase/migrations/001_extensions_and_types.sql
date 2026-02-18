-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- User roles enum
CREATE TYPE user_role AS ENUM (
  'player',
  'parent',
  'coach',
  'mentor',
  'club_admin',
  'admin'
);

-- Slot status enum
CREATE TYPE slot_status AS ENUM (
  'filled',
  'graduating',
  'portal_risk',
  'open',
  'unknown'
);

-- Pipeline stage enum
CREATE TYPE pipeline_stage AS ENUM (
  'identified',
  'contacted',
  'evaluated',
  'offered',
  'committed',
  'declined',
  'lost'
);

-- Control mode enum
CREATE TYPE control_mode AS ENUM (
  'parent_led',
  'player_led'
);

-- Permission level enum
CREATE TYPE permission_level AS ENUM (
  'read_only',
  'advisory'
);

-- Relationship status enum
CREATE TYPE relationship_status AS ENUM (
  'pending',
  'active',
  'revoked'
);

-- Migration 034: Fix coach auth.users + identities
--
-- Root cause: Migration 023 inserted coaches into auth.users without auth.identities.
-- GoTrue cleaned up the identity-less auth.users rows (cascade deleted public.users too,
-- but FK orphans remained). We now:
--   1. Bypass the handle_new_user trigger (it would conflict on existing public.users rows)
--   2. Insert auth.users for all 20 coaches
--   3. Create auth.identities so login works
--   4. Ensure public.users has role='coach' and correct names

SET search_path TO public, extensions, auth;

-- ── 1. Disable triggers for this session so handle_new_user doesn't fire ──────
SET LOCAL session_replication_role = replica;

-- ── 2. Insert auth.users ──────────────────────────────────────────────────────
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) VALUES
  ('b2000000-0000-0000-0000-000000000001', 'coach.daniels@lanista.test',   extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000002', 'coach.martinez@lanista.test',  extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000003', 'coach.osei@lanista.test',      extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000004', 'coach.nguyen@lanista.test',    extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000005', 'coach.sullivan@lanista.test',  extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000006', 'coach.reid@lanista.test',      extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000007', 'coach.patel@lanista.test',     extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000008', 'coach.foster@lanista.test',    extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000009', 'coach.diaz@lanista.test',      extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000010', 'coach.kim@lanista.test',       extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000011', 'coach.jackson@lanista.test',   extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000012', 'coach.okafor@lanista.test',    extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000013', 'coach.hernandez@lanista.test', extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000014', 'coach.walsh@lanista.test',     extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000015', 'coach.ibrahim@lanista.test',   extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000016', 'coach.chen@lanista.test',      extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000017', 'coach.morrison@lanista.test',  extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000018', 'coach.tran@lanista.test',      extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000019', 'coach.owens@lanista.test',     extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  ('b2000000-0000-0000-0000-000000000020', 'coach.reyes@lanista.test',     extensions.crypt('Lanista2026!', extensions.gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO UPDATE SET
  encrypted_password = EXCLUDED.encrypted_password,
  email_confirmed_at = EXCLUDED.email_confirmed_at,
  updated_at = NOW();

-- ── 3. Create auth.identities ─────────────────────────────────────────────────
INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT
  gen_random_uuid(),
  id,
  email,
  jsonb_build_object('sub', id::text, 'email', email),
  'email',
  NOW(), NOW(), NOW()
FROM auth.users
WHERE email LIKE '%@lanista.test'
  AND role = 'authenticated'
ON CONFLICT (provider, provider_id) DO NOTHING;

-- ── 4. Fix public.users: correct role + names for all 20 coaches ──────────────
INSERT INTO public.users (id, email, role, first_name, last_name, language, onboarding_complete)
VALUES
  ('b2000000-0000-0000-0000-000000000001', 'coach.daniels@lanista.test',   'coach', 'Marcus',   'Daniels',   'en', true),
  ('b2000000-0000-0000-0000-000000000002', 'coach.martinez@lanista.test',  'coach', 'Elena',    'Martinez',  'es', true),
  ('b2000000-0000-0000-0000-000000000003', 'coach.osei@lanista.test',      'coach', 'Kwame',    'Osei',      'en', true),
  ('b2000000-0000-0000-0000-000000000004', 'coach.nguyen@lanista.test',    'coach', 'David',    'Nguyen',    'en', true),
  ('b2000000-0000-0000-0000-000000000005', 'coach.sullivan@lanista.test',  'coach', 'Patrick',  'Sullivan',  'en', true),
  ('b2000000-0000-0000-0000-000000000006', 'coach.reid@lanista.test',      'coach', 'Alicia',   'Reid',      'en', true),
  ('b2000000-0000-0000-0000-000000000007', 'coach.patel@lanista.test',     'coach', 'Raj',      'Patel',     'en', true),
  ('b2000000-0000-0000-0000-000000000008', 'coach.foster@lanista.test',    'coach', 'James',    'Foster',    'en', true),
  ('b2000000-0000-0000-0000-000000000009', 'coach.diaz@lanista.test',      'coach', 'Carlos',   'Diaz',      'es', true),
  ('b2000000-0000-0000-0000-000000000010', 'coach.kim@lanista.test',       'coach', 'Jenny',    'Kim',       'en', true),
  ('b2000000-0000-0000-0000-000000000011', 'coach.jackson@lanista.test',   'coach', 'Terrence', 'Jackson',   'en', true),
  ('b2000000-0000-0000-0000-000000000012', 'coach.okafor@lanista.test',    'coach', 'Emeka',    'Okafor',    'en', true),
  ('b2000000-0000-0000-0000-000000000013', 'coach.hernandez@lanista.test', 'coach', 'Miguel',   'Hernandez', 'es', true),
  ('b2000000-0000-0000-0000-000000000014', 'coach.walsh@lanista.test',     'coach', 'Sean',     'Walsh',     'en', true),
  ('b2000000-0000-0000-0000-000000000015', 'coach.ibrahim@lanista.test',   'coach', 'Tariq',    'Ibrahim',   'en', true),
  ('b2000000-0000-0000-0000-000000000016', 'coach.chen@lanista.test',      'coach', 'William',  'Chen',      'en', true),
  ('b2000000-0000-0000-0000-000000000017', 'coach.morrison@lanista.test',  'coach', 'Brian',    'Morrison',  'en', true),
  ('b2000000-0000-0000-0000-000000000018', 'coach.tran@lanista.test',      'coach', 'Lisa',     'Tran',      'en', true),
  ('b2000000-0000-0000-0000-000000000019', 'coach.owens@lanista.test',     'coach', 'Derek',    'Owens',     'en', true),
  ('b2000000-0000-0000-0000-000000000020', 'coach.reyes@lanista.test',     'coach', 'Ana',      'Reyes',     'es', true)
ON CONFLICT (id) DO UPDATE SET
  role          = EXCLUDED.role,
  first_name    = EXCLUDED.first_name,
  last_name     = EXCLUDED.last_name,
  language      = EXCLUDED.language,
  onboarding_complete = EXCLUDED.onboarding_complete;

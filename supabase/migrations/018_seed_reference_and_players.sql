-- ============================================================
-- SEED: Reference Data + Player Profiles
-- Migration 018
-- ============================================================

-- ============================================================
-- SPORT
-- ============================================================
INSERT INTO sports (id, name, name_es, is_active) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Soccer', 'Fútbol', true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- LEAGUES
-- ============================================================
INSERT INTO leagues (id, sport_id, name, name_es, gender, level) VALUES
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'MLS Next',        'MLS Next',        'male',   1),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'ECNL Boys',       'ECNL Varones',    'male',   1),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'ECNL Girls',      'ECNL Chicas',     'female', 1),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Girls Academy',   'Girls Academy',   'female', 1),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'ECRL',            'ECRL',            'male',   2),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'NPL Boys',        'NPL Varones',     'male',   2),
  ('10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'NPL Girls',       'NPL Chicas',      'female', 2)
ON CONFLICT DO NOTHING;

-- ============================================================
-- CLUBS
-- ============================================================
INSERT INTO clubs (id, sport_id, name, city, state, league_id, gender, verified, development_rating) VALUES
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'LA Galaxy Academy',         'Los Angeles',  'CA', '10000000-0000-0000-0000-000000000001', 'male',   true, 4.8),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'NYCFC Academy',             'New York',     'NY', '10000000-0000-0000-0000-000000000001', 'male',   true, 4.7),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Chicago Fire Academy',      'Chicago',      'IL', '10000000-0000-0000-0000-000000000001', 'male',   true, 4.5),
  ('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'FC Dallas Academy',         'Dallas',       'TX', '10000000-0000-0000-0000-000000000001', 'male',   true, 4.6),
  ('20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Seattle Sounders Academy',  'Seattle',      'WA', '10000000-0000-0000-0000-000000000001', 'male',   true, 4.7),
  ('20000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'SoCal Blues',               'San Diego',    'CA', '10000000-0000-0000-0000-000000000003', 'female', true, 4.5),
  ('20000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'Ohio Premier FC',           'Columbus',     'OH', '10000000-0000-0000-0000-000000000002', 'male',   true, 4.3),
  ('20000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 'De Anza Force',             'Cupertino',    'CA', '10000000-0000-0000-0000-000000000002', 'male',   true, 4.4),
  ('20000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000001', 'Florida Elite Soccer Academy','Orlando',    'FL', '10000000-0000-0000-0000-000000000003', 'female', true, 4.2),
  ('20000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'Dallas Texans',             'Dallas',       'TX', '10000000-0000-0000-0000-000000000006', 'male',   false, 4.0)
ON CONFLICT DO NOTHING;

-- ============================================================
-- DIVISIONS
-- ============================================================
INSERT INTO divisions (id, name, name_es, scholarship_type) VALUES
  ('30000000-0000-0000-0000-000000000001', 'Division I',    'División I',    'equivalency'),
  ('30000000-0000-0000-0000-000000000002', 'Division II',   'División II',   'equivalency'),
  ('30000000-0000-0000-0000-000000000003', 'Division III',  'División III',  'none'),
  ('30000000-0000-0000-0000-000000000004', 'NAIA',          'NAIA',          'equivalency'),
  ('30000000-0000-0000-0000-000000000005', 'Junior College','Colegio Junior', 'equivalency')
ON CONFLICT DO NOTHING;

-- ============================================================
-- SEED PLAYER AUTH USERS + PROFILES
-- NOTE: Run this section via Supabase service role only.
-- Creates auth.users entries then public.users + players.
-- ============================================================

DO $$
DECLARE
  sport_id UUID := '00000000-0000-0000-0000-000000000001';

  -- Auth user IDs (pre-generated)
  uid1  UUID := 'a1000000-0000-0000-0000-000000000001';
  uid2  UUID := 'a1000000-0000-0000-0000-000000000002';
  uid3  UUID := 'a1000000-0000-0000-0000-000000000003';
  uid4  UUID := 'a1000000-0000-0000-0000-000000000004';
  uid5  UUID := 'a1000000-0000-0000-0000-000000000005';
  uid6  UUID := 'a1000000-0000-0000-0000-000000000006';
  uid7  UUID := 'a1000000-0000-0000-0000-000000000007';
  uid8  UUID := 'a1000000-0000-0000-0000-000000000008';
  uid9  UUID := 'a1000000-0000-0000-0000-000000000009';
  uid10 UUID := 'a1000000-0000-0000-0000-000000000010';
  uid11 UUID := 'a1000000-0000-0000-0000-000000000011';
  uid12 UUID := 'a1000000-0000-0000-0000-000000000012';

BEGIN

-- ============================================================
-- INSERT AUTH USERS (requires service role)
-- ============================================================
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES
  (uid1,  'kieran.ross@lanista.test',     crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid2,  'marcus.delgado@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid3,  'jaylen.brooks@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid4,  'santiago.vega@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid5,  'noah.chen@lanista.test',       crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid6,  'elias.okonkwo@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid7,  'luca.ferrari@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid8,  'omar.hassan@lanista.test',     crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  -- Female players
  (uid9,  'lucy.kim@lanista.test',        crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid10, 'sofia.ramirez@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid11, 'maya.johnson@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (uid12, 'isabela.santos@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- INSERT PUBLIC USERS
-- ============================================================
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete)
VALUES
  (uid1,  'kieran.ross@lanista.test',    'player', 'Kieran',   'Ross',     'en', true),
  (uid2,  'marcus.delgado@lanista.test', 'player', 'Marcus',   'Delgado',  'es', true),
  (uid3,  'jaylen.brooks@lanista.test',  'player', 'Jaylen',   'Brooks',   'en', true),
  (uid4,  'santiago.vega@lanista.test',  'player', 'Santiago', 'Vega',     'es', true),
  (uid5,  'noah.chen@lanista.test',      'player', 'Noah',     'Chen',     'en', true),
  (uid6,  'elias.okonkwo@lanista.test',  'player', 'Elias',    'Okonkwo',  'en', true),
  (uid7,  'luca.ferrari@lanista.test',   'player', 'Luca',     'Ferrari',  'en', true),
  (uid8,  'omar.hassan@lanista.test',    'player', 'Omar',     'Hassan',   'en', true),
  (uid9,  'lucy.kim@lanista.test',       'player', 'Lucy',     'Kim',      'en', true),
  (uid10, 'sofia.ramirez@lanista.test',  'player', 'Sofía',    'Ramírez',  'es', true),
  (uid11, 'maya.johnson@lanista.test',   'player', 'Maya',     'Johnson',  'en', true),
  (uid12, 'isabela.santos@lanista.test', 'player', 'Isabela',  'Santos',   'es', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- INSERT PLAYER PROFILES
-- ============================================================
-- Male players (MLS Next / ECNL Boys)
INSERT INTO players (
  user_id, sport_id, gender, grade, graduation_year,
  height_cm, weight_kg, dominant_foot, speed_rating,
  gpa, target_division, is_discoverable,
  leadership_rating, club_id, league_id,
  bio, character_description
) VALUES
  -- Kieran Ross | Striker | MLS Next | 2027 grad | D1 target
  (uid1, sport_id, 'male', 10, 2027, 178, 72, 'right', 9, 3.4, 'D1', true, 5,
   '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   'Technically gifted striker with explosive first step. Top scorer in MLS Next Southwest.',
   'High-energy leader. Vocal on the field. Known for dragging teammates through tough moments.'),

  -- Marcus Delgado | Central Midfielder | MLS Next | 2027 grad | D1 target
  (uid2, sport_id, 'male', 10, 2027, 175, 68, 'both', 8, 3.1, 'D1', true, 4,
   '20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001',
   'Box-to-box midfielder with elite passing range and tactical IQ. Press-resistant in tight spaces.',
   'Quiet leader. Earns respect with effort. Never misses training.'),

  -- Jaylen Brooks | Center Back | ECNL Boys | 2028 grad | D1 target
  (uid3, sport_id, 'male', 9, 2028, 185, 80, 'right', 7, 3.6, 'D1', true, 4,
   '20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002',
   'Commanding CB with strong aerial ability and smart positioning. Reads the game two steps ahead.',
   'Natural captain. Organizes back line vocally. Calm under pressure.'),

  -- Santiago Vega | Left Winger | MLS Next | 2026 grad | D1 target
  (uid4, sport_id, 'male', 11, 2026, 172, 65, 'left', 10, 2.9, 'D1', true, 3,
   '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   'Pacey left winger with elite 1v1 ability. Direct and dangerous in transition.',
   'Passionate competitor. Still developing decision-making in the final third.'),

  -- Noah Chen | Goalkeeper | ECNL Boys | 2027 grad | D1 target
  (uid5, sport_id, 'male', 10, 2027, 188, 82, 'right', 6, 3.8, 'D1', true, 5,
   '20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000002',
   'Shot-stopper with exceptional footwork and distribution. Comfortable playing out from the back.',
   'Intellectually driven. Studies film regularly. Future coach mentality.'),

  -- Elias Okonkwo | Right Back | MLS Next | 2027 grad | D2 target
  (uid6, sport_id, 'male', 10, 2027, 176, 73, 'right', 9, 3.2, 'D2', true, 4,
   '20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001',
   'Attacking fullback with high work rate and strong defensive awareness. Overlaps constantly.',
   'Team-first mentality. Reliable in every role asked of him.'),

  -- Luca Ferrari | Defensive Midfielder | ECRL | 2028 grad | D2 target
  (uid7, sport_id, 'male', 9, 2028, 180, 76, 'right', 7, 3.5, 'D2', true, 3,
   '20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000005',
   'Disciplined DM who breaks up play and recycles possession efficiently. High-IQ positional player.',
   'Low-ego competitor. Does the dirty work without complaint.'),

  -- Omar Hassan | Striker | NPL | 2026 grad | D3 target
  (uid8, sport_id, 'male', 11, 2026, 182, 78, 'right', 8, 3.0, 'D3', true, 4,
   '20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000006',
   'Physical target striker with strong hold-up play. Excellent in aerial duels.',
   'Hardworking, coachable, and determined to improve every session.')
ON CONFLICT (user_id) DO NOTHING;

-- Female players (ECNL Girls / Girls Academy)
INSERT INTO players (
  user_id, sport_id, gender, grade, graduation_year,
  height_cm, weight_kg, dominant_foot, speed_rating,
  gpa, target_division, is_discoverable,
  leadership_rating, club_id, league_id,
  bio, character_description
) VALUES
  -- Lucy Kim | Central Midfielder | ECNL Girls | 2027 grad | D2 target
  (uid9, sport_id, 'female', 10, 2027, 163, 57, 'right', 7, 3.7, 'D2', true, 5,
   '20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000003',
   'Technically precise midfielder. Excellent 1-2 combinations and high press intensity.',
   'Academic-first player. Will bring the same discipline to college that she brings to the classroom.'),

  -- Sofía Ramírez | Striker | ECNL Girls | 2027 grad | D1 target
  (uid10, sport_id, 'female', 10, 2027, 168, 60, 'left', 9, 3.3, 'D1', true, 4,
   '20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000003',
   'Creative forward with flair and clinical finishing. Dangerous in 1v1 situations against defenders.',
   'Fearless and expressive. Bilingual — communicates seamlessly with any teammate.'),

  -- Maya Johnson | Center Back | Girls Academy | 2028 grad | D1 target
  (uid11, sport_id, 'female', 9, 2028, 173, 65, 'right', 7, 3.5, 'D1', true, 5,
   '20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000004',
   'Commanding CB who dominates aerially and reads attacking patterns early. Strong in the press.',
   'Natural leader. Runs warmups. First to arrive, last to leave.'),

  -- Isabela Santos | Right Midfielder | ECNL Girls | 2026 grad | D2 target
  (uid12, sport_id, 'female', 11, 2026, 161, 55, 'right', 8, 3.2, 'D2', true, 3,
   '20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000003',
   'Wide midfielder with tireless engine. Covers ground rapidly and contributes on both ends.',
   'Coachable and mentally tough. Responds well to feedback and pushes her limits in training.')
ON CONFLICT (user_id) DO NOTHING;

END $$;

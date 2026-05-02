-- Migration 074: Seed 10 coaches covering Mountain West & South Central states
-- Adds programs for: CO, NM, AR, OR, WA, UT, OK
-- Addresses player search returning 0 results for these regions.

SET search_path TO public, extensions;

DO $$
DECLARE
  -- Auth user UUIDs (32–41)
  cuid32 UUID := 'b2000000-0000-0000-0000-000000000032';
  cuid33 UUID := 'b2000000-0000-0000-0000-000000000033';
  cuid34 UUID := 'b2000000-0000-0000-0000-000000000034';
  cuid35 UUID := 'b2000000-0000-0000-0000-000000000135';
  cuid36 UUID := 'b2000000-0000-0000-0000-000000000036';
  cuid37 UUID := 'b2000000-0000-0000-0000-000000000037';
  cuid38 UUID := 'b2000000-0000-0000-0000-000000000038';
  cuid39 UUID := 'b2000000-0000-0000-0000-000000000039';
  cuid40 UUID := 'b2000000-0000-0000-0000-000000000040';
  cuid41 UUID := 'b2000000-0000-0000-0000-000000000041';

  -- Coach profile UUIDs (32–41)
  coach32 UUID := 'c3000000-0000-0000-0000-000000000032';
  coach33 UUID := 'c3000000-0000-0000-0000-000000000033';
  coach34 UUID := 'c3000000-0000-0000-0000-000000000034';
  coach35 UUID := 'c3000000-0000-0000-0000-000000000135';
  coach36 UUID := 'c3000000-0000-0000-0000-000000000036';
  coach37 UUID := 'c3000000-0000-0000-0000-000000000037';
  coach38 UUID := 'c3000000-0000-0000-0000-000000000038';
  coach39 UUID := 'c3000000-0000-0000-0000-000000000039';
  coach40 UUID := 'c3000000-0000-0000-0000-000000000040';
  coach41 UUID := 'c3000000-0000-0000-0000-000000000041';

BEGIN

-- ─── Auth Users ───────────────────────────────────────────────────────────────
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, reauthentication_token,
  email_change, email_change_token_new, email_change_token_current,
  created_at, updated_at, aud, role
) VALUES
  (cuid32, '00000000-0000-0000-0000-000000000000',
   'coach.navarro@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid33, '00000000-0000-0000-0000-000000000000',
   'coach.pierce@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid34, '00000000-0000-0000-0000-000000000000',
   'coach.luna@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid35, '00000000-0000-0000-0000-000000000000',
   'coach.reyes2@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid36, '00000000-0000-0000-0000-000000000000',
   'coach.dupree@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid37, '00000000-0000-0000-0000-000000000000',
   'coach.fletcher@lanista.test',crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid38, '00000000-0000-0000-0000-000000000000',
   'coach.manning@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid39, '00000000-0000-0000-0000-000000000000',
   'coach.nguyen2@lanista.test', crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid40, '00000000-0000-0000-0000-000000000000',
   'coach.olsen@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid41, '00000000-0000-0000-0000-000000000000',
   'coach.wade@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}', '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- ─── Auth Identities ──────────────────────────────────────────────────────────
INSERT INTO auth.identities (
  id, user_id, provider_id, provider,
  identity_data, last_sign_in_at, created_at, updated_at
) VALUES
  (gen_random_uuid(), cuid32, cuid32::text, 'email',
   jsonb_build_object('sub', cuid32::text, 'email', 'coach.navarro@lanista.test'),   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid33, cuid33::text, 'email',
   jsonb_build_object('sub', cuid33::text, 'email', 'coach.pierce@lanista.test'),    NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid34, cuid34::text, 'email',
   jsonb_build_object('sub', cuid34::text, 'email', 'coach.luna@lanista.test'),      NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid35, cuid35::text, 'email',
   jsonb_build_object('sub', cuid35::text, 'email', 'coach.reyes2@lanista.test'),     NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid36, cuid36::text, 'email',
   jsonb_build_object('sub', cuid36::text, 'email', 'coach.dupree@lanista.test'),    NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid37, cuid37::text, 'email',
   jsonb_build_object('sub', cuid37::text, 'email', 'coach.fletcher@lanista.test'),  NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid38, cuid38::text, 'email',
   jsonb_build_object('sub', cuid38::text, 'email', 'coach.manning@lanista.test'),   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid39, cuid39::text, 'email',
   jsonb_build_object('sub', cuid39::text, 'email', 'coach.nguyen2@lanista.test'),   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid40, cuid40::text, 'email',
   jsonb_build_object('sub', cuid40::text, 'email', 'coach.olsen@lanista.test'),     NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid41, cuid41::text, 'email',
   jsonb_build_object('sub', cuid41::text, 'email', 'coach.wade@lanista.test'),      NOW(), NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ─── Public Users ─────────────────────────────────────────────────────────────
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete)
VALUES
  (cuid32, 'coach.navarro@lanista.test',  'coach', 'Carlos',   'Navarro',   'es', true),
  (cuid33, 'coach.pierce@lanista.test',   'coach', 'Ashley',   'Pierce',    'en', true),
  (cuid34, 'coach.luna@lanista.test',     'coach', 'Sofia',    'Luna',      'es', true),
  (cuid35, 'coach.reyes2@lanista.test',   'coach', 'Miguel',   'Reyes',     'es', true),
  (cuid36, 'coach.dupree@lanista.test',   'coach', 'James',    'Dupree',    'en', true),
  (cuid37, 'coach.fletcher@lanista.test', 'coach', 'Hannah',   'Fletcher',  'en', true),
  (cuid38, 'coach.manning@lanista.test',  'coach', 'Patrick',  'Manning',   'en', true),
  (cuid39, 'coach.nguyen2@lanista.test',  'coach', 'Kevin',    'Nguyen',    'en', true),
  (cuid40, 'coach.olsen@lanista.test',    'coach', 'Erik',     'Olsen',     'en', true),
  (cuid41, 'coach.wade@lanista.test',     'coach', 'Denise',   'Wade',      'en', true)
ON CONFLICT (id) DO NOTHING;

-- ─── Coach Profiles ───────────────────────────────────────────────────────────
INSERT INTO coaches (
  id, user_id, school_name, division, state,
  primary_formation, gender_program, playing_styles,
  recruiting_class_years, min_gpa, is_published,
  bio, recruiting_notes
) VALUES

  -- Coach 32 — University of Denver — CO — D1 — 4-3-3
  (coach32, cuid32,
   'University of Denver', 'D1', 'CO',
   '4-3-3', 'male', ARRAY['possession', 'high_press'],
   ARRAY['2026','2027','2028'], 2.8, true,
   'DU Men''s Soccer — Summit League. One of the premier soccer programs in the Rocky Mountain region with a strong professional pipeline.',
   'Seeking technically gifted wingers and a pressing striker for our high-energy 4-3-3. Colorado''s top D1 soccer program.'),

  -- Coach 33 — Colorado State University — CO — D2 — 4-2-3-1
  (coach33, cuid33,
   'Colorado State University-Pueblo', 'D2', 'CO',
   '4-2-3-1', 'male', ARRAY['balanced', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.5, true,
   'CSU-Pueblo Men''s Soccer — RMAC Conference. Competitive D2 program in southern Colorado with scholarship availability.',
   'Double pivot with an attacking #10. Looking for a creative playmaker and a reliable goal scorer. Partial scholarships available.'),

  -- Coach 34 — University of New Mexico — NM — D1 — 4-3-3
  (coach34, cuid34,
   'University of New Mexico', 'D1', 'NM',
   '4-3-3', 'male', ARRAY['possession', 'technical'],
   ARRAY['2026','2027','2028'], 2.7, true,
   'UNM Men''s Soccer — Mountain West Conference. High-altitude training in Albuquerque. Strong bilingual recruiting network.',
   'Technical 4-3-3 with an emphasis on possession and ball control. Actively recruiting bilingual players. Strong academic support.'),

  -- Coach 35 — Eastern New Mexico University — NM — D2 — 4-4-2
  (coach35, cuid35,
   'Eastern New Mexico University', 'D2', 'NM',
   '4-4-2', 'male', ARRAY['direct', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.3, true,
   'ENMU Men''s Soccer — Lone Star Conference. D2 program in Portales, NM. Scholarship opportunities for quality players.',
   'Classic two-striker system with wide midfielders. Seeking athletic players who can run for 90 minutes. Full ride potential.'),

  -- Coach 36 — University of Arkansas — AR — D1 — 4-2-3-1
  (coach36, cuid36,
   'University of Arkansas', 'D1', 'AR',
   '4-2-3-1', 'male', ARRAY['possession', 'build_from_back'],
   ARRAY['2026','2027'], 2.8, true,
   'Arkansas Men''s Soccer — Sun Belt Conference. SEC university with top-tier facilities and a growing soccer program.',
   'Possession-based double pivot system. Need technically sound defenders, a distributing DM, and a dynamic #10.'),

  -- Coach 37 — Henderson State University — AR — D2 — 4-3-3
  (coach37, cuid37,
   'Henderson State University', 'D2', 'AR',
   '4-3-3', 'male', ARRAY['high_press', 'vertical'],
   ARRAY['2026','2027','2028'], 2.4, true,
   'Henderson State Men''s Soccer — GAC Conference in Arkadelphia, AR. Competitive D2 with financial aid available for student-athletes.',
   'High-pressing 4-3-3. Looking for quick, tenacious players who love to press and transition fast. Aid packages available.'),

  -- Coach 38 — University of Portland — OR — D1 — 4-3-3
  (coach38, cuid38,
   'University of Portland', 'D1', 'OR',
   '4-3-3', 'male', ARRAY['possession', 'build_from_back'],
   ARRAY['2026','2027','2028'], 3.0, true,
   'UP Men''s Soccer — West Coast Conference. Consistently ranked Top 25 nationally. Strong academic and athletic culture in the Pacific Northwest.',
   'Technically demanding program. Seeking players who are comfortable with the ball under pressure. High GPA culture.'),

  -- Coach 39 — Seattle University — WA — D1 — 4-2-3-1
  (coach39, cuid39,
   'Seattle University', 'D1', 'WA',
   '4-2-3-1', 'male', ARRAY['possession', 'technical'],
   ARRAY['2027','2028'], 3.0, true,
   'Seattle U Men''s Soccer — Western Athletic Conference. Urban campus with a strong soccer identity and Pacific Northwest recruiting base.',
   'Double pivot with a creative #10. Need box-to-box midfielders and a clinical finisher. Academic excellence required.'),

  -- Coach 40 — University of Utah — UT — D1 — 4-4-2
  (coach40, cuid40,
   'University of Utah', 'D1', 'UT',
   '4-4-2', 'male', ARRAY['direct', 'balanced'],
   ARRAY['2026','2027','2028'], 2.7, true,
   'Utah Men''s Soccer — Pac-12 program in Salt Lake City. High altitude training and a passionate fan base in the Mountain West.',
   'Two-striker system with hardworking wide midfielders. Looking for athletic, versatile players who can adapt to altitude.'),

  -- Coach 41 — University of Tulsa — OK — D1 — 4-3-3
  (coach41, cuid41,
   'University of Tulsa', 'D1', 'OK',
   '4-3-3', 'male', ARRAY['counter_attack', 'high_press'],
   ARRAY['2026','2027','2028'], 2.6, true,
   'Tulsa Men''s Soccer — American Athletic Conference. D1 program in Tulsa, OK with excellent facilities and growing regional presence.',
   'Counter-attacking 4-3-3 with explosive wingers. Seeking pace on the flanks and a dominant striker. Partial scholarships available.')

ON CONFLICT (id) DO NOTHING;

-- ─── Position Requirements ────────────────────────────────────────────────────

-- Coach 32 — Denver — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach32, 'lw',  ARRAY['pace','dribbling','crossing','1v1'],                           true),
  (coach32, 'rw',  ARRAY['pace','crossing','work_rate','dribbling'],                     true),
  (coach32, 'st',  ARRAY['finishing','pressing','movement','pace'],                      true),
  (coach32, 'cm',  ARRAY['passing_range','box_to_box','press_resistance','vision'],      true),
  (coach32, 'cdm', ARRAY['defensive_awareness','positioning','distribution','passing'],  true),
  (coach32, 'cb',  ARRAY['aerial_ability','positioning','composure','passing'],          true),
  (coach32, 'gk',  ARRAY['shot_stopping','distribution','command_of_area'],              true)
ON CONFLICT DO NOTHING;

-- Coach 33 — CSU-Pueblo — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach33, 'st',  ARRAY['finishing','movement','hold_up_play','work_rate'],             true),
  (coach33, 'cam', ARRAY['creativity','vision','passing_range','dribbling'],             true),
  (coach33, 'ram', ARRAY['pace','crossing','work_rate','dribbling'],                     true),
  (coach33, 'lam', ARRAY['pace','dribbling','1v1','crossing'],                           true),
  (coach33, 'cdm', ARRAY['defensive_awareness','passing','positioning','interceptions'], true),
  (coach33, 'cb',  ARRAY['aerial_ability','positioning','leadership','composure'],       true),
  (coach33, 'gk',  ARRAY['shot_stopping','distribution','reflexes'],                    true)
ON CONFLICT DO NOTHING;

-- Coach 34 — UNM — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach34, 'lw',  ARRAY['pace','dribbling','1v1','technical_ability'],                  true),
  (coach34, 'rw',  ARRAY['pace','crossing','dribbling','technical_ability'],             true),
  (coach34, 'st',  ARRAY['finishing','movement','hold_up_play','pressing'],              true),
  (coach34, 'cm',  ARRAY['passing_range','vision','press_resistance','box_to_box'],      true),
  (coach34, 'cdm', ARRAY['defensive_awareness','distribution','positioning','passing'],  true),
  (coach34, 'cb',  ARRAY['aerial_ability','composure','passing','positioning'],          true),
  (coach34, 'gk',  ARRAY['shot_stopping','command_of_area','distribution'],              true)
ON CONFLICT DO NOTHING;

-- Coach 35 — ENMU — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach35, 'st',  ARRAY['finishing','aerial_ability','hold_up_play','pace'],            true),
  (coach35, 'cf',  ARRAY['pace','movement','finishing','pressing'],                      true),
  (coach35, 'rm',  ARRAY['pace','crossing','work_rate','stamina'],                       true),
  (coach35, 'lm',  ARRAY['pace','dribbling','crossing','work_rate'],                     true),
  (coach35, 'cm',  ARRAY['passing','box_to_box','defensive_awareness','work_rate'],      true),
  (coach35, 'cb',  ARRAY['aerial_ability','positioning','leadership','composure'],       true),
  (coach35, 'gk',  ARRAY['shot_stopping','reflexes','command_of_area'],                 true)
ON CONFLICT DO NOTHING;

-- Coach 36 — Arkansas — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach36, 'st',  ARRAY['finishing','hold_up_play','movement','pressing'],              true),
  (coach36, 'cam', ARRAY['creativity','vision','passing_range','dribbling'],             true),
  (coach36, 'ram', ARRAY['pace','crossing','work_rate','pressing'],                      true),
  (coach36, 'lam', ARRAY['pace','dribbling','1v1','work_rate'],                          true),
  (coach36, 'cdm', ARRAY['defensive_awareness','distribution','positioning','passing'],  true),
  (coach36, 'cb',  ARRAY['aerial_ability','positioning','composure','leadership'],       true),
  (coach36, 'gk',  ARRAY['shot_stopping','distribution','command_of_area'],              true)
ON CONFLICT DO NOTHING;

-- Coach 37 — Henderson State — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach37, 'lw',  ARRAY['pace','pressing','dribbling','work_rate'],                     true),
  (coach37, 'rw',  ARRAY['pace','pressing','crossing','work_rate'],                      true),
  (coach37, 'st',  ARRAY['pressing','pace','finishing','movement'],                      true),
  (coach37, 'cm',  ARRAY['work_rate','pressing','passing','box_to_box'],                 true),
  (coach37, 'cdm', ARRAY['defensive_awareness','pressing','interceptions','passing'],    true),
  (coach37, 'cb',  ARRAY['aerial_ability','positioning','composure','leadership'],       true),
  (coach37, 'gk',  ARRAY['shot_stopping','distribution','reflexes'],                    true)
ON CONFLICT DO NOTHING;

-- Coach 38 — Portland — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach38, 'lw',  ARRAY['technical_ability','dribbling','pace','crossing'],             true),
  (coach38, 'rw',  ARRAY['technical_ability','crossing','pace','work_rate'],             true),
  (coach38, 'st',  ARRAY['finishing','movement','pressing','technical_ability'],         true),
  (coach38, 'cm',  ARRAY['passing_range','vision','press_resistance','box_to_box'],      true),
  (coach38, 'cdm', ARRAY['defensive_awareness','distribution','positioning','composure'],true),
  (coach38, 'cb',  ARRAY['reading_game','passing','aerial_ability','composure'],         true),
  (coach38, 'gk',  ARRAY['shot_stopping','distribution','command_of_area'],              true)
ON CONFLICT DO NOTHING;

-- Coach 39 — Seattle U — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach39, 'st',  ARRAY['finishing','movement','pressing','technical_ability'],         true),
  (coach39, 'cam', ARRAY['creativity','vision','passing_range','dribbling'],             true),
  (coach39, 'ram', ARRAY['pace','crossing','technical_ability','work_rate'],             true),
  (coach39, 'lam', ARRAY['pace','dribbling','technical_ability','crossing'],             true),
  (coach39, 'cdm', ARRAY['defensive_awareness','distribution','positioning','passing'],  true),
  (coach39, 'cb',  ARRAY['reading_game','aerial_ability','composure','passing'],         true),
  (coach39, 'gk',  ARRAY['shot_stopping','distribution','reflexes'],                    true)
ON CONFLICT DO NOTHING;

-- Coach 40 — Utah — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach40, 'st',  ARRAY['finishing','aerial_ability','hold_up_play','work_rate'],       true),
  (coach40, 'cf',  ARRAY['pace','finishing','movement','pressing'],                      true),
  (coach40, 'rm',  ARRAY['pace','crossing','work_rate','stamina'],                       true),
  (coach40, 'lm',  ARRAY['pace','dribbling','crossing','work_rate'],                     true),
  (coach40, 'cm',  ARRAY['box_to_box','passing','defensive_awareness','stamina'],        true),
  (coach40, 'cb',  ARRAY['aerial_ability','positioning','leadership','composure'],       true),
  (coach40, 'gk',  ARRAY['shot_stopping','command_of_area','distribution'],              true)
ON CONFLICT DO NOTHING;

-- Coach 41 — Tulsa — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  (coach41, 'lw',  ARRAY['pace','dribbling','1v1','work_rate'],                          true),
  (coach41, 'rw',  ARRAY['pace','crossing','work_rate','pressing'],                      true),
  (coach41, 'st',  ARRAY['finishing','pace','movement','pressing'],                      true),
  (coach41, 'cm',  ARRAY['box_to_box','work_rate','passing','defensive_awareness'],      true),
  (coach41, 'cdm', ARRAY['defensive_awareness','positioning','interceptions','passing'], true),
  (coach41, 'cb',  ARRAY['aerial_ability','positioning','composure','leadership'],       true),
  (coach41, 'gk',  ARRAY['shot_stopping','reflexes','distribution'],                    true)
ON CONFLICT DO NOTHING;

-- ─── Roster Slots ─────────────────────────────────────────────────────────────
INSERT INTO roster_slots (coach_id, position_key, depth_order, slot_status, graduation_year) VALUES
  -- Coach 32 Denver 4-3-3
  (coach32,'lw',  1,'open',       2027), (coach32,'rw',  1,'graduating', 2026),
  (coach32,'rw',  2,'open',       2027), (coach32,'st',  1,'open',       2026),
  (coach32,'st',  2,'open',       2028), (coach32,'cm',  1,'filled',     2027),
  (coach32,'cm',  2,'open',       2027), (coach32,'cdm', 1,'open',       2027),
  (coach32,'cb',  1,'open',       2028), (coach32,'gk',  1,'graduating', 2026),

  -- Coach 33 CSU-Pueblo 4-2-3-1
  (coach33,'st',  1,'open',       2027), (coach33,'cam', 1,'graduating', 2026),
  (coach33,'cam', 2,'open',       2027), (coach33,'ram', 1,'open',       2026),
  (coach33,'lam', 1,'open',       2027), (coach33,'cdm', 1,'filled',     2026),
  (coach33,'cdm', 2,'open',       2027), (coach33,'cb',  1,'open',       2028),

  -- Coach 34 UNM 4-3-3
  (coach34,'lw',  1,'open',       2027), (coach34,'rw',  1,'open',       2026),
  (coach34,'st',  1,'graduating', 2026), (coach34,'st',  2,'open',       2027),
  (coach34,'cm',  1,'open',       2027), (coach34,'cm',  2,'filled',     2028),
  (coach34,'cdm', 1,'open',       2026), (coach34,'cb',  1,'open',       2027),
  (coach34,'gk',  1,'open',       2027),

  -- Coach 35 ENMU 4-4-2
  (coach35,'st',  1,'graduating', 2026), (coach35,'st',  2,'open',       2027),
  (coach35,'cf',  1,'open',       2026), (coach35,'rm',  1,'open',       2027),
  (coach35,'lm',  1,'open',       2026), (coach35,'cm',  1,'open',       2028),
  (coach35,'cb',  1,'open',       2027), (coach35,'gk',  1,'open',       2026),

  -- Coach 36 Arkansas 4-2-3-1
  (coach36,'st',  1,'open',       2027), (coach36,'cam', 1,'open',       2026),
  (coach36,'ram', 1,'graduating', 2026), (coach36,'ram', 2,'open',       2027),
  (coach36,'lam', 1,'open',       2027), (coach36,'cdm', 1,'filled',     2027),
  (coach36,'cdm', 2,'open',       2028), (coach36,'cb',  1,'open',       2026),

  -- Coach 37 Henderson State 4-3-3
  (coach37,'lw',  1,'open',       2026), (coach37,'rw',  1,'open',       2027),
  (coach37,'st',  1,'graduating', 2026), (coach37,'st',  2,'open',       2027),
  (coach37,'cm',  1,'open',       2026), (coach37,'cdm', 1,'open',       2027),
  (coach37,'cb',  1,'open',       2028), (coach37,'gk',  1,'open',       2026),

  -- Coach 38 Portland 4-3-3
  (coach38,'lw',  1,'open',       2027), (coach38,'rw',  1,'graduating', 2026),
  (coach38,'rw',  2,'open',       2028), (coach38,'st',  1,'open',       2027),
  (coach38,'cm',  1,'open',       2026), (coach38,'cm',  2,'filled',     2027),
  (coach38,'cdm', 1,'open',       2027), (coach38,'cb',  1,'open',       2028),

  -- Coach 39 Seattle U 4-2-3-1
  (coach39,'st',  1,'open',       2027), (coach39,'cam', 1,'open',       2028),
  (coach39,'ram', 1,'open',       2027), (coach39,'lam', 1,'graduating', 2026),
  (coach39,'lam', 2,'open',       2027), (coach39,'cdm', 1,'open',       2026),
  (coach39,'cb',  1,'open',       2027), (coach39,'gk',  1,'open',       2027),

  -- Coach 40 Utah 4-4-2
  (coach40,'st',  1,'graduating', 2026), (coach40,'st',  2,'open',       2027),
  (coach40,'cf',  1,'open',       2026), (coach40,'rm',  1,'open',       2027),
  (coach40,'lm',  1,'open',       2026), (coach40,'lm',  2,'open',       2028),
  (coach40,'cm',  1,'filled',     2027), (coach40,'cm',  2,'open',       2027),
  (coach40,'cb',  1,'open',       2028), (coach40,'gk',  1,'open',       2026),

  -- Coach 41 Tulsa 4-3-3
  (coach41,'lw',  1,'open',       2026), (coach41,'rw',  1,'open',       2027),
  (coach41,'st',  1,'graduating', 2026), (coach41,'st',  2,'open',       2027),
  (coach41,'cm',  1,'open',       2026), (coach41,'cm',  2,'open',       2028),
  (coach41,'cdm', 1,'open',       2027), (coach41,'cb',  1,'open',       2027),
  (coach41,'gk',  1,'graduating', 2026)
ON CONFLICT DO NOTHING;

END $$;

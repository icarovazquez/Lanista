-- Migration 069: Seed 11 more coaches covering all new formations
-- Adds programs for every formation available in the player search filter:
--   3-4-3, 4-5-1, 4-3-2-1, 5-3-2, 3-1-3-3, 4-1-2-3,
--   4-2-2-2, 4-3-1-2, 5-2-3, 5-2-1-2, 5-2-2-1
-- Auth users created with correct GoTrue fields (instance_id, blank tokens, provider_id = uuid)

SET search_path TO public, extensions;

DO $$
DECLARE
  -- Auth user UUIDs (21–31)
  cuid21 UUID := 'b2000000-0000-0000-0000-000000000021';
  cuid22 UUID := 'b2000000-0000-0000-0000-000000000022';
  cuid23 UUID := 'b2000000-0000-0000-0000-000000000023';
  cuid24 UUID := 'b2000000-0000-0000-0000-000000000024';
  cuid25 UUID := 'b2000000-0000-0000-0000-000000000025';
  cuid26 UUID := 'b2000000-0000-0000-0000-000000000026';
  cuid27 UUID := 'b2000000-0000-0000-0000-000000000027';
  cuid28 UUID := 'b2000000-0000-0000-0000-000000000028';
  cuid29 UUID := 'b2000000-0000-0000-0000-000000000029';
  cuid30 UUID := 'b2000000-0000-0000-0000-000000000030';
  cuid31 UUID := 'b2000000-0000-0000-0000-000000000031';

  -- Coach profile UUIDs (21–31)
  coach21 UUID := 'c3000000-0000-0000-0000-000000000021';
  coach22 UUID := 'c3000000-0000-0000-0000-000000000022';
  coach23 UUID := 'c3000000-0000-0000-0000-000000000023';
  coach24 UUID := 'c3000000-0000-0000-0000-000000000024';
  coach25 UUID := 'c3000000-0000-0000-0000-000000000025';
  coach26 UUID := 'c3000000-0000-0000-0000-000000000026';
  coach27 UUID := 'c3000000-0000-0000-0000-000000000027';
  coach28 UUID := 'c3000000-0000-0000-0000-000000000028';
  coach29 UUID := 'c3000000-0000-0000-0000-000000000029';
  coach30 UUID := 'c3000000-0000-0000-0000-000000000030';
  coach31 UUID := 'c3000000-0000-0000-0000-000000000031';

BEGIN

-- ─── Auth Users (proper GoTrue fields) ───────────────────────────────────────
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, reauthentication_token,
  email_change, email_change_token_new, email_change_token_current,
  created_at, updated_at, aud, role
) VALUES
  (cuid21, '00000000-0000-0000-0000-000000000000',
   'coach.hayes@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid22, '00000000-0000-0000-0000-000000000000',
   'coach.stone@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid23, '00000000-0000-0000-0000-000000000000',
   'coach.burns@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid24, '00000000-0000-0000-0000-000000000000',
   'coach.bell@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid25, '00000000-0000-0000-0000-000000000000',
   'coach.grant@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid26, '00000000-0000-0000-0000-000000000000',
   'coach.price@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid27, '00000000-0000-0000-0000-000000000000',
   'coach.ford@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid28, '00000000-0000-0000-0000-000000000000',
   'coach.watts@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid29, '00000000-0000-0000-0000-000000000000',
   'coach.banks@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid30, '00000000-0000-0000-0000-000000000000',
   'coach.rivers@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid31, '00000000-0000-0000-0000-000000000000',
   'coach.cross@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(),
   '{"provider":"email","providers":["email"]}', '{}',
   '', '', '', '', '', '',
   NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- ─── Auth Identities (provider_id must be the user UUID string) ──────────────
INSERT INTO auth.identities (
  id, user_id, provider_id, provider,
  identity_data, last_sign_in_at, created_at, updated_at
) VALUES
  (gen_random_uuid(), cuid21, cuid21::text, 'email',
   jsonb_build_object('sub', cuid21::text, 'email', 'coach.hayes@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid22, cuid22::text, 'email',
   jsonb_build_object('sub', cuid22::text, 'email', 'coach.stone@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid23, cuid23::text, 'email',
   jsonb_build_object('sub', cuid23::text, 'email', 'coach.burns@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid24, cuid24::text, 'email',
   jsonb_build_object('sub', cuid24::text, 'email', 'coach.bell@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid25, cuid25::text, 'email',
   jsonb_build_object('sub', cuid25::text, 'email', 'coach.grant@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid26, cuid26::text, 'email',
   jsonb_build_object('sub', cuid26::text, 'email', 'coach.price@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid27, cuid27::text, 'email',
   jsonb_build_object('sub', cuid27::text, 'email', 'coach.ford@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid28, cuid28::text, 'email',
   jsonb_build_object('sub', cuid28::text, 'email', 'coach.watts@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid29, cuid29::text, 'email',
   jsonb_build_object('sub', cuid29::text, 'email', 'coach.banks@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid30, cuid30::text, 'email',
   jsonb_build_object('sub', cuid30::text, 'email', 'coach.rivers@lanista.test'),
   NOW(), NOW(), NOW()),
  (gen_random_uuid(), cuid31, cuid31::text, 'email',
   jsonb_build_object('sub', cuid31::text, 'email', 'coach.cross@lanista.test'),
   NOW(), NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ─── Public Users ─────────────────────────────────────────────────────────────
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete)
VALUES
  (cuid21, 'coach.hayes@lanista.test',  'coach', 'Jordan',  'Hayes',   'en', true),
  (cuid22, 'coach.stone@lanista.test',  'coach', 'Melissa',  'Stone',   'en', true),
  (cuid23, 'coach.burns@lanista.test',  'coach', 'Robert',  'Burns',   'en', true),
  (cuid24, 'coach.bell@lanista.test',   'coach', 'Darius',  'Bell',    'en', true),
  (cuid25, 'coach.grant@lanista.test',  'coach', 'Cynthia', 'Grant',   'en', true),
  (cuid26, 'coach.price@lanista.test',  'coach', 'Andre',   'Price',   'en', true),
  (cuid27, 'coach.ford@lanista.test',   'coach', 'Marcus',  'Ford',    'en', true),
  (cuid28, 'coach.watts@lanista.test',  'coach', 'Diana',   'Watts',   'en', true),
  (cuid29, 'coach.banks@lanista.test',  'coach', 'Leon',    'Banks',   'en', true),
  (cuid30, 'coach.rivers@lanista.test', 'coach', 'Nadia',   'Rivers',  'es', true),
  (cuid31, 'coach.cross@lanista.test',  'coach', 'Tyler',   'Cross',   'en', true)
ON CONFLICT (id) DO NOTHING;

-- ─── Coach Profiles ───────────────────────────────────────────────────────────
INSERT INTO coaches (
  id, user_id, school_name, division, state,
  primary_formation, gender_program, playing_styles,
  recruiting_class_years, min_gpa, is_published,
  bio, recruiting_notes
) VALUES
  -- Coach 21 — Florida State — D1 — 4-5-1
  (coach21, cuid21,
   'Florida State University', 'D1', 'FL',
   '4-5-1', 'male', ARRAY['possession', 'high_press'],
   ARRAY['2026','2027','2028'], 2.8, true,
   'FSU Men''s Soccer — ACC program with strong Atlantic Coast recruiting presence and elite training facilities.',
   'Compact midfield five with a clinical target striker. Seeking disciplined wide midfielders and a dominant No. 9.'),

  -- Coach 22 — UCLA — D1 — 4-3-2-1 (Christmas Tree)
  (coach22, cuid22,
   'UCLA', 'D1', 'CA',
   '4-3-2-1', 'male', ARRAY['technical', 'possession'],
   ARRAY['2026','2027'], 3.0, true,
   'UCLA Men''s Soccer — Pac-12 program in Los Angeles with strong international recruitment and professional pathway.',
   'Christmas Tree system. Need two creative #10-style attacking mids and a clinical finisher up top.'),

  -- Coach 23 — Penn State — D1 — 5-3-2
  (coach23, cuid23,
   'Penn State University', 'D1', 'PA',
   '5-3-2', 'male', ARRAY['direct', 'balanced'],
   ARRAY['2026','2027','2028'], 2.7, true,
   'Penn State Men''s Soccer — Big Ten program with a physical, organized style of play.',
   'Five-back defensive structure with two-striker attack. Need dynamic wing-backs and a strong aerial striker.'),

  -- Coach 24 — UCF — D1 — 3-4-3
  (coach24, cuid24,
   'University of Central Florida', 'D1', 'FL',
   '3-4-3', 'male', ARRAY['high_press', 'vertical'],
   ARRAY['2027','2028'], 2.6, true,
   'UCF Men''s Soccer — AAC program in Orlando. High-energy attacking style with an emphasis on transitions.',
   'Three-back system with attacking wide midfielders and three forwards. Looking for pace, pressing, and flair.'),

  -- Coach 25 — SMU — D1 — 4-1-2-3
  (coach25, cuid25,
   'Southern Methodist University', 'D1', 'TX',
   '4-1-2-3', 'male', ARRAY['possession', 'build_from_back'],
   ARRAY['2026','2027'], 2.9, true,
   'SMU Men''s Soccer — AAC program in Dallas. Possession-focused football with a strong academic culture.',
   'Pivot DM anchoring two interior mids and three attackers. Need a distributor DM and two-footed wingers.'),

  -- Coach 26 — Charleston Southern — D2 — 3-1-3-3 (gegenpressing)
  (coach26, cuid26,
   'Charleston Southern University', 'D2', 'SC',
   '3-1-3-3', 'male', ARRAY['high_press', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.4, true,
   'Charleston Southern Men''s Soccer — Big South Conference. Aggressive, high-intensity program with scholarship availability.',
   'Modern pressing system with three forwards. Need mobile, high-energy players who can press for 90 minutes.'),

  -- Coach 27 — Rockhurst — D2 — 4-2-2-2
  (coach27, cuid27,
   'Rockhurst University', 'D2', 'MO',
   '4-2-2-2', 'male', ARRAY['balanced', 'possession'],
   ARRAY['2026','2027','2028'], 2.5, true,
   'Rockhurst Men''s Soccer — MIAA conference in Kansas City. Competitive D2 program with partial scholarship opportunities.',
   'Double pivot with two attacking mids and two strikers. Looking for versatile midfielders who can attack and defend.'),

  -- Coach 28 — Western Connecticut State — D3 — 4-3-1-2
  (coach28, cuid28,
   'Western Connecticut State University', 'D3', 'CT',
   '4-3-1-2', 'male', ARRAY['technical', 'possession'],
   ARRAY['2026','2027','2028'], 2.7, true,
   'WestConn Men''s Soccer — Little East Conference. Academically focused D3 program in the greater New York area.',
   'Classic diamond midfield with a No. 10 and two strikers. Need a creative playmaker and intelligent center forwards.'),

  -- Coach 29 — Briar Cliff — NAIA — 5-2-3
  (coach29, cuid29,
   'Briar Cliff University', 'NAIA', 'IA',
   '5-2-3', 'male', ARRAY['direct', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.3, true,
   'Briar Cliff Men''s Soccer — GPAC conference. NAIA program with full scholarship availability and Midwest recruiting network.',
   'Wing-back heavy system with three forwards. Full scholarship offers available for quality players.'),

  -- Coach 30 — Iowa Western CC — NJCAA — 5-2-1-2
  (coach30, cuid30,
   'Iowa Western Community College', 'NJCAA', 'IA',
   '5-2-1-2', 'male', ARRAY['balanced', 'direct'],
   ARRAY['2026','2027'], 2.0, true,
   'Iowa Western Men''s Soccer — NJCAA program with a strong pathway to D1/D2 four-year transfer. Nationally competitive.',
   'Structured defensive block with creative #10 and two strikers. Great transfer portal springboard for D1/D2 programs.'),

  -- Coach 31 — Bethany College — NAIA — 5-2-2-1
  (coach31, cuid31,
   'Bethany College', 'NAIA', 'WV',
   '5-2-2-1', 'male', ARRAY['possession', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.3, true,
   'Bethany Men''s Soccer — Presidents'' Athletic Conference. Small college with personal coaching and full scholarship potential.',
   'Deep defensive shape with attacking overlaps from wing-backs. Lone striker supported by two attacking mids.')
ON CONFLICT (id) DO NOTHING;

-- ─── Position Requirements ────────────────────────────────────────────────────

-- Coach 21 — FSU — 4-5-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach21, 'st',  2.8, NULL,    176, ARRAY['finishing','hold_up_play','movement','aerial_ability'],        true),
  (coach21, 'rm',  2.8, 'right', 170, ARRAY['pace','crossing','work_rate','dribbling'],                    true),
  (coach21, 'lm',  2.8, 'left',  170, ARRAY['pace','crossing','work_rate','dribbling'],                    true),
  (coach21, 'cm',  2.8, NULL,    172, ARRAY['passing_range','press_resistance','box_to_box','interceptions'], true),
  (coach21, 'cdm', 2.8, NULL,    174, ARRAY['defensive_awareness','positioning','aerial_ability','passing'], true),
  (coach21, 'cb',  2.8, NULL,    180, ARRAY['aerial_ability','positioning','leadership','passing'],          true),
  (coach21, 'gk',  2.8, NULL,    183, ARRAY['shot_stopping','distribution','command_of_area'],              true)
ON CONFLICT DO NOTHING;

-- Coach 22 — UCLA — 4-3-2-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach22, 'st',  3.0, NULL,    173, ARRAY['finishing','pressing','movement','technical_ability'],          true),
  (coach22, 'cam', 3.0, NULL,    170, ARRAY['creativity','vision','dribbling','passing_range'],              true),
  (coach22, 'cm',  3.0, NULL,    171, ARRAY['box_to_box','passing','press_resistance','vision'],             true),
  (coach22, 'cdm', 3.0, NULL,    173, ARRAY['defensive_awareness','positioning','distribution','interceptions'], true),
  (coach22, 'rb',  3.0, 'right', 170, ARRAY['pace','crossing','pressing','work_rate'],                      true),
  (coach22, 'lb',  3.0, 'left',  170, ARRAY['pace','crossing','pressing','work_rate'],                      true),
  (coach22, 'cb',  3.0, NULL,    178, ARRAY['reading_game','passing','aerial_ability','composure'],          true)
ON CONFLICT DO NOTHING;

-- Coach 23 — Penn State — 5-3-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach23, 'st',  2.7, NULL,    177, ARRAY['finishing','aerial_ability','hold_up_play','pressing'],         true),
  (coach23, 'cf',  2.7, NULL,    175, ARRAY['movement','pace','finishing','pressing'],                       true),
  (coach23, 'cm',  2.7, NULL,    172, ARRAY['passing_range','box_to_box','press_resistance','work_rate'],    true),
  (coach23, 'rb',  2.7, 'right', 174, ARRAY['pace','crossing','defensive_awareness','stamina'],              true),
  (coach23, 'lb',  2.7, 'left',  174, ARRAY['pace','crossing','defensive_awareness','stamina'],              true),
  (coach23, 'cb',  2.7, NULL,    181, ARRAY['aerial_ability','positioning','leadership','composure'],        true),
  (coach23, 'gk',  2.7, NULL,    184, ARRAY['shot_stopping','command_of_area','distribution'],               true)
ON CONFLICT DO NOTHING;

-- Coach 24 — UCF — 3-4-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach24, 'lw',  2.6, 'left',  167, ARRAY['pace','dribbling','1v1','pressing'],                           true),
  (coach24, 'rw',  2.6, 'right', 167, ARRAY['pace','crossing','dribbling','pressing'],                      true),
  (coach24, 'st',  2.6, NULL,    174, ARRAY['pace','finishing','movement','pressing'],                       true),
  (coach24, 'cm',  2.6, NULL,    171, ARRAY['box_to_box','work_rate','passing','defensive_awareness'],       true),
  (coach24, 'cb',  2.6, NULL,    179, ARRAY['aerial_ability','positioning','passing','composure'],           true),
  (coach24, 'gk',  2.6, NULL,    182, ARRAY['shot_stopping','distribution','reflexes'],                     true)
ON CONFLICT DO NOTHING;

-- Coach 25 — SMU — 4-1-2-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach25, 'lw',  2.9, 'left',  168, ARRAY['pace','dribbling','crossing','1v1'],                           true),
  (coach25, 'rw',  2.9, 'right', 168, ARRAY['pace','crossing','dribbling','work_rate'],                     true),
  (coach25, 'st',  2.9, NULL,    174, ARRAY['finishing','movement','hold_up_play','pace'],                   true),
  (coach25, 'cm',  2.9, NULL,    171, ARRAY['vision','passing_range','dribbling','press_resistance'],        true),
  (coach25, 'cdm', 2.9, NULL,    173, ARRAY['defensive_awareness','distribution','positioning','aerial_ability'], true),
  (coach25, 'cb',  2.9, NULL,    179, ARRAY['aerial_ability','passing','positioning','leadership'],          true)
ON CONFLICT DO NOTHING;

-- Coach 26 — Charleston Southern — 3-1-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach26, 'lw',  2.4, 'left',  166, ARRAY['pace','pressing','dribbling','1v1'],                           true),
  (coach26, 'rw',  2.4, 'right', 166, ARRAY['pace','pressing','crossing','work_rate'],                      true),
  (coach26, 'st',  2.4, NULL,    173, ARRAY['pressing','pace','finishing','movement'],                       true),
  (coach26, 'cm',  2.4, NULL,    170, ARRAY['work_rate','pressing','passing','box_to_box'],                  true),
  (coach26, 'cdm', 2.4, NULL,    172, ARRAY['defensive_awareness','pressing','interceptions','positioning'], true),
  (coach26, 'cb',  2.4, NULL,    178, ARRAY['aerial_ability','positioning','composure','passing'],           true)
ON CONFLICT DO NOTHING;

-- Coach 27 — Rockhurst — 4-2-2-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach27, 'st',  2.5, NULL,    175, ARRAY['finishing','movement','pressing','work_rate'],                  true),
  (coach27, 'cf',  2.5, NULL,    173, ARRAY['pace','finishing','movement','dribbling'],                      true),
  (coach27, 'cam', 2.5, NULL,    170, ARRAY['creativity','vision','passing_range','dribbling'],              true),
  (coach27, 'cdm', 2.5, NULL,    172, ARRAY['defensive_awareness','passing','positioning','interceptions'],  true),
  (coach27, 'cb',  2.5, NULL,    178, ARRAY['aerial_ability','positioning','leadership','composure'],        true),
  (coach27, 'rb',  2.5, 'right', 170, ARRAY['pace','crossing','defensive_awareness','work_rate'],           true)
ON CONFLICT DO NOTHING;

-- Coach 28 — WestConn — 4-3-1-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach28, 'st',  2.7, NULL,    175, ARRAY['finishing','movement','hold_up_play','work_rate'],              true),
  (coach28, 'cf',  2.7, NULL,    172, ARRAY['pace','dribbling','finishing','pressing'],                      true),
  (coach28, 'cam', 2.7, NULL,    169, ARRAY['creativity','vision','passing_range','technical_ability'],      true),
  (coach28, 'cm',  2.7, NULL,    171, ARRAY['passing','box_to_box','press_resistance','work_rate'],          true),
  (coach28, 'cdm', 2.7, NULL,    173, ARRAY['defensive_awareness','positioning','distribution','interceptions'], true),
  (coach28, 'cb',  2.7, NULL,    179, ARRAY['aerial_ability','positioning','composure','passing'],           true)
ON CONFLICT DO NOTHING;

-- Coach 29 — Briar Cliff — 5-2-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach29, 'lw',  2.3, 'left',  166, ARRAY['pace','dribbling','1v1','crossing'],                           true),
  (coach29, 'rw',  2.3, 'right', 166, ARRAY['pace','crossing','work_rate','dribbling'],                     true),
  (coach29, 'st',  2.3, NULL,    175, ARRAY['finishing','hold_up_play','pace','movement'],                   true),
  (coach29, 'cm',  2.3, NULL,    170, ARRAY['work_rate','passing','box_to_box','defensive_awareness'],       true),
  (coach29, 'rb',  2.3, 'right', 172, ARRAY['pace','crossing','stamina','defensive_awareness'],              true),
  (coach29, 'cb',  2.3, NULL,    178, ARRAY['aerial_ability','positioning','composure','leadership'],        true)
ON CONFLICT DO NOTHING;

-- Coach 30 — Iowa Western CC — 5-2-1-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach30, 'st',  2.0, NULL,    174, ARRAY['finishing','hold_up_play','movement','pressing'],               true),
  (coach30, 'cf',  2.0, NULL,    172, ARRAY['pace','finishing','dribbling','movement'],                      true),
  (coach30, 'cam', 2.0, NULL,    168, ARRAY['vision','creativity','passing','dribbling'],                    true),
  (coach30, 'cm',  2.0, NULL,    170, ARRAY['box_to_box','defensive_awareness','passing','work_rate'],       true),
  (coach30, 'rb',  2.0, 'right', 171, ARRAY['pace','crossing','stamina','defensive_awareness'],              true),
  (coach30, 'cb',  2.0, NULL,    177, ARRAY['aerial_ability','positioning','composure','leadership'],        true)
ON CONFLICT DO NOTHING;

-- Coach 31 — Bethany College — 5-2-2-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach31, 'st',  2.3, NULL,    176, ARRAY['hold_up_play','aerial_ability','finishing','work_rate'],        true),
  (coach31, 'cam', 2.3, NULL,    170, ARRAY['creativity','vision','passing_range','dribbling'],              true),
  (coach31, 'lm',  2.3, 'left',  168, ARRAY['pace','crossing','work_rate','pressing'],                      true),
  (coach31, 'cm',  2.3, NULL,    171, ARRAY['box_to_box','defensive_awareness','passing','work_rate'],       true),
  (coach31, 'rb',  2.3, 'right', 171, ARRAY['pace','crossing','stamina','defensive_awareness'],              true),
  (coach31, 'cb',  2.3, NULL,    178, ARRAY['aerial_ability','positioning','composure','leadership'],        true)
ON CONFLICT DO NOTHING;

-- ─── Roster Slots (open + graduating = needs_recruit=true for "Recruiting Now") ──
INSERT INTO roster_slots (coach_id, position_key, depth_order, slot_status, graduation_year) VALUES
  -- Coach 21 FSU 4-5-1
  (coach21,'st',  1, 'graduating', 2026), (coach21,'st',  2, 'open',       2027),
  (coach21,'rm',  1, 'open',       2027), (coach21,'lm',  1, 'graduating', 2026),
  (coach21,'lm',  2, 'open',       2027), (coach21,'cm',  1, 'filled',     2026),
  (coach21,'cm',  2, 'open',       2028), (coach21,'cdm', 1, 'open',       2027),
  (coach21,'cb',  1, 'open',       2027), (coach21,'gk',  1, 'open',       2026),

  -- Coach 22 UCLA 4-3-2-1
  (coach22,'st',  1, 'open',       2027), (coach22,'cam', 1, 'graduating', 2026),
  (coach22,'cam', 2, 'open',       2027), (coach22,'cm',  1, 'open',       2026),
  (coach22,'cm',  2, 'filled',     2027), (coach22,'cdm', 1, 'open',       2027),
  (coach22,'rb',  1, 'open',       2026), (coach22,'lb',  1, 'open',       2027),
  (coach22,'cb',  1, 'open',       2028),

  -- Coach 23 Penn State 5-3-2
  (coach23,'st',  1, 'graduating', 2026), (coach23,'st',  2, 'open',       2027),
  (coach23,'cf',  1, 'open',       2026), (coach23,'cm',  1, 'open',       2027),
  (coach23,'cm',  2, 'filled',     2026), (coach23,'rb',  1, 'open',       2027),
  (coach23,'lb',  1, 'graduating', 2026), (coach23,'lb',  2, 'open',       2027),
  (coach23,'cb',  1, 'open',       2028), (coach23,'gk',  1, 'open',       2026),

  -- Coach 24 UCF 3-4-3
  (coach24,'lw',  1, 'open',       2027), (coach24,'rw',  1, 'graduating', 2026),
  (coach24,'rw',  2, 'open',       2027), (coach24,'st',  1, 'open',       2026),
  (coach24,'cm',  1, 'open',       2028), (coach24,'cm',  2, 'filled',     2027),
  (coach24,'cb',  1, 'open',       2027), (coach24,'gk',  1, 'open',       2026),

  -- Coach 25 SMU 4-1-2-3
  (coach25,'lw',  1, 'graduating', 2026), (coach25,'lw',  2, 'open',       2027),
  (coach25,'rw',  1, 'open',       2026), (coach25,'st',  1, 'open',       2027),
  (coach25,'cm',  1, 'open',       2026), (coach25,'cm',  2, 'filled',     2027),
  (coach25,'cdm', 1, 'open',       2028), (coach25,'cb',  1, 'open',       2027),

  -- Coach 26 Charleston Southern 3-1-3-3
  (coach26,'lw',  1, 'open',       2026), (coach26,'rw',  1, 'open',       2026),
  (coach26,'st',  1, 'graduating', 2026), (coach26,'st',  2, 'open',       2027),
  (coach26,'cm',  1, 'open',       2027), (coach26,'cdm', 1, 'filled',     2026),
  (coach26,'cdm', 2, 'open',       2027), (coach26,'cb',  1, 'open',       2027),

  -- Coach 27 Rockhurst 4-2-2-2
  (coach27,'st',  1, 'open',       2026), (coach27,'cf',  1, 'graduating', 2026),
  (coach27,'cf',  2, 'open',       2027), (coach27,'cam', 1, 'open',       2026),
  (coach27,'cdm', 1, 'open',       2027), (coach27,'cdm', 2, 'filled',     2027),
  (coach27,'cb',  1, 'open',       2028), (coach27,'rb',  1, 'open',       2026),

  -- Coach 28 WestConn 4-3-1-2
  (coach28,'st',  1, 'graduating', 2026), (coach28,'st',  2, 'open',       2027),
  (coach28,'cf',  1, 'open',       2026), (coach28,'cam', 1, 'open',       2027),
  (coach28,'cm',  1, 'filled',     2026), (coach28,'cm',  2, 'open',       2028),
  (coach28,'cdm', 1, 'open',       2027), (coach28,'cb',  1, 'open',       2027),

  -- Coach 29 Briar Cliff 5-2-3
  (coach29,'lw',  1, 'open',       2026), (coach29,'rw',  1, 'graduating', 2026),
  (coach29,'rw',  2, 'open',       2027), (coach29,'st',  1, 'open',       2026),
  (coach29,'cm',  1, 'open',       2027), (coach29,'cm',  2, 'filled',     2026),
  (coach29,'rb',  1, 'open',       2026), (coach29,'cb',  1, 'open',       2028),

  -- Coach 30 Iowa Western CC 5-2-1-2
  (coach30,'st',  1, 'graduating', 2026), (coach30,'st',  2, 'open',       2026),
  (coach30,'cf',  1, 'open',       2027), (coach30,'cam', 1, 'open',       2026),
  (coach30,'cm',  1, 'open',       2027), (coach30,'cm',  2, 'filled',     2026),
  (coach30,'rb',  1, 'open',       2026), (coach30,'cb',  1, 'open',       2027),

  -- Coach 31 Bethany College 5-2-2-1
  (coach31,'st',  1, 'open',       2026), (coach31,'cam', 1, 'graduating', 2026),
  (coach31,'cam', 2, 'open',       2027), (coach31,'lm',  1, 'open',       2026),
  (coach31,'cm',  1, 'open',       2027), (coach31,'cm',  2, 'filled',     2026),
  (coach31,'rb',  1, 'open',       2028), (coach31,'cb',  1, 'open',       2027)
ON CONFLICT DO NOTHING;

END $$;

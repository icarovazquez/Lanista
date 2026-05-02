-- Make pgcrypto functions (gen_salt, crypt) available regardless of schema
SET search_path TO public, extensions;

-- ============================================================
-- SEED: 20 Test Coach Profiles
-- Migration 023
--
-- Creates 20 realistic coach accounts with:
--   • auth.users + public.users (role = 'coach')
--   • coaches profile (school, division, formation)
--   • coach_position_requirements (is_published = true)
--   • roster_slots (mix of open / filled / graduating)
--
-- Position keys match PlayerProfileData.positions abbreviations:
--   gk  rb  cb  lb  cdm  cm  cam  rm  lm  rw  lw  st  cf
-- ============================================================

DO $$
DECLARE
  cuid1  UUID := 'b2000000-0000-0000-0000-000000000001';
  cuid2  UUID := 'b2000000-0000-0000-0000-000000000002';
  cuid3  UUID := 'b2000000-0000-0000-0000-000000000003';
  cuid4  UUID := 'b2000000-0000-0000-0000-000000000004';
  cuid5  UUID := 'b2000000-0000-0000-0000-000000000005';
  cuid6  UUID := 'b2000000-0000-0000-0000-000000000006';
  cuid7  UUID := 'b2000000-0000-0000-0000-000000000007';
  cuid8  UUID := 'b2000000-0000-0000-0000-000000000008';
  cuid9  UUID := 'b2000000-0000-0000-0000-000000000009';
  cuid10 UUID := 'b2000000-0000-0000-0000-000000000010';
  cuid11 UUID := 'b2000000-0000-0000-0000-000000000011';
  cuid12 UUID := 'b2000000-0000-0000-0000-000000000012';
  cuid13 UUID := 'b2000000-0000-0000-0000-000000000013';
  cuid14 UUID := 'b2000000-0000-0000-0000-000000000014';
  cuid15 UUID := 'b2000000-0000-0000-0000-000000000015';
  cuid16 UUID := 'b2000000-0000-0000-0000-000000000016';
  cuid17 UUID := 'b2000000-0000-0000-0000-000000000017';
  cuid18 UUID := 'b2000000-0000-0000-0000-000000000018';
  cuid19 UUID := 'b2000000-0000-0000-0000-000000000019';
  cuid20 UUID := 'b2000000-0000-0000-0000-000000000020';

  coach1  UUID := 'c3000000-0000-0000-0000-000000000001';
  coach2  UUID := 'c3000000-0000-0000-0000-000000000002';
  coach3  UUID := 'c3000000-0000-0000-0000-000000000003';
  coach4  UUID := 'c3000000-0000-0000-0000-000000000004';
  coach5  UUID := 'c3000000-0000-0000-0000-000000000005';
  coach6  UUID := 'c3000000-0000-0000-0000-000000000006';
  coach7  UUID := 'c3000000-0000-0000-0000-000000000007';
  coach8  UUID := 'c3000000-0000-0000-0000-000000000008';
  coach9  UUID := 'c3000000-0000-0000-0000-000000000009';
  coach10 UUID := 'c3000000-0000-0000-0000-000000000010';
  coach11 UUID := 'c3000000-0000-0000-0000-000000000011';
  coach12 UUID := 'c3000000-0000-0000-0000-000000000012';
  coach13 UUID := 'c3000000-0000-0000-0000-000000000013';
  coach14 UUID := 'c3000000-0000-0000-0000-000000000014';
  coach15 UUID := 'c3000000-0000-0000-0000-000000000015';
  coach16 UUID := 'c3000000-0000-0000-0000-000000000016';
  coach17 UUID := 'c3000000-0000-0000-0000-000000000017';
  coach18 UUID := 'c3000000-0000-0000-0000-000000000018';
  coach19 UUID := 'c3000000-0000-0000-0000-000000000019';
  coach20 UUID := 'c3000000-0000-0000-0000-000000000020';

BEGIN

-- ─── Auth Users ──────────────────────────────────────────────────────────────
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) VALUES
  (cuid1,  'coach.daniels@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid2,  'coach.martinez@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid3,  'coach.osei@lanista.test',       crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid4,  'coach.nguyen@lanista.test',     crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid5,  'coach.sullivan@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid6,  'coach.reid@lanista.test',       crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid7,  'coach.patel@lanista.test',      crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid8,  'coach.foster@lanista.test',     crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid9,  'coach.diaz@lanista.test',       crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid10, 'coach.kim@lanista.test',        crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid11, 'coach.jackson@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid12, 'coach.okafor@lanista.test',     crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid13, 'coach.hernandez@lanista.test',  crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid14, 'coach.walsh@lanista.test',      crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid15, 'coach.ibrahim@lanista.test',    crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid16, 'coach.chen@lanista.test',       crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid17, 'coach.morrison@lanista.test',   crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid18, 'coach.tran@lanista.test',       crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid19, 'coach.owens@lanista.test',      crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated'),
  (cuid20, 'coach.reyes@lanista.test',      crypt('Lanista2026!', gen_salt('bf')), NOW(), '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- ─── Public Users ─────────────────────────────────────────────────────────────
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete)
VALUES
  (cuid1,  'coach.daniels@lanista.test',    'coach', 'Marcus',   'Daniels',   'en', true),
  (cuid2,  'coach.martinez@lanista.test',   'coach', 'Elena',    'Martinez',  'es', true),
  (cuid3,  'coach.osei@lanista.test',       'coach', 'Kwame',    'Osei',      'en', true),
  (cuid4,  'coach.nguyen@lanista.test',     'coach', 'David',    'Nguyen',    'en', true),
  (cuid5,  'coach.sullivan@lanista.test',   'coach', 'Patrick',  'Sullivan',  'en', true),
  (cuid6,  'coach.reid@lanista.test',       'coach', 'Alicia',   'Reid',      'en', true),
  (cuid7,  'coach.patel@lanista.test',      'coach', 'Raj',      'Patel',     'en', true),
  (cuid8,  'coach.foster@lanista.test',     'coach', 'James',    'Foster',    'en', true),
  (cuid9,  'coach.diaz@lanista.test',       'coach', 'Carlos',   'Diaz',      'es', true),
  (cuid10, 'coach.kim@lanista.test',        'coach', 'Jenny',    'Kim',       'en', true),
  (cuid11, 'coach.jackson@lanista.test',    'coach', 'Terrence', 'Jackson',   'en', true),
  (cuid12, 'coach.okafor@lanista.test',     'coach', 'Emeka',    'Okafor',    'en', true),
  (cuid13, 'coach.hernandez@lanista.test',  'coach', 'Miguel',   'Hernandez', 'es', true),
  (cuid14, 'coach.walsh@lanista.test',      'coach', 'Sean',     'Walsh',     'en', true),
  (cuid15, 'coach.ibrahim@lanista.test',    'coach', 'Tariq',    'Ibrahim',   'en', true),
  (cuid16, 'coach.chen@lanista.test',       'coach', 'William',  'Chen',      'en', true),
  (cuid17, 'coach.morrison@lanista.test',   'coach', 'Brian',    'Morrison',  'en', true),
  (cuid18, 'coach.tran@lanista.test',       'coach', 'Lisa',     'Tran',      'en', true),
  (cuid19, 'coach.owens@lanista.test',      'coach', 'Derek',    'Owens',     'en', true),
  (cuid20, 'coach.reyes@lanista.test',      'coach', 'Ana',      'Reyes',     'es', true)
ON CONFLICT (id) DO NOTHING;

-- ─── Coach Profiles ───────────────────────────────────────────────────────────
INSERT INTO coaches (
  id, user_id, school_name, division, state,
  primary_formation, gender_program, playing_styles,
  recruiting_class_years, min_gpa, is_published,
  bio, recruiting_notes
) VALUES
  -- ── D1 (8) ──────────────────────────────────────────────────────────────────
  (coach1, cuid1,
   'University of North Carolina', 'D1', 'NC',
   '4-3-3', 'male', ARRAY['possession', 'high_press'],
   ARRAY['2026','2027','2028'], 2.8, true,
   'UNC Men''s Soccer — ACC powerhouse with a rich history of developing professional players.',
   'Seeking technical wingers and a clinical striker for our high-pressing 4-3-3 system.'),

  (coach2, cuid2,
   'Stanford University', 'D1', 'CA',
   '4-2-3-1', 'male', ARRAY['possession', 'build_from_back'],
   ARRAY['2026','2027'], 3.2, true,
   'Stanford Men''s Soccer — Pac-12 program combining elite academics with top-level soccer.',
   'Academic excellence required. Seeking creative midfielders and dynamic attackers who can play in tight spaces.'),

  (coach3, cuid3,
   'Indiana University', 'D1', 'IN',
   '4-3-3', 'male', ARRAY['high_press', 'vertical'],
   ARRAY['2026','2027','2028'], 2.8, true,
   'IU Men''s Soccer — Big Ten powerhouse and US Soccer pipeline. Multiple national titles.',
   'Highly competitive recruiting environment. Looking for players who can thrive under pressure.'),

  (coach4, cuid4,
   'Wake Forest University', 'D1', 'NC',
   '4-4-2', 'male', ARRAY['possession', 'technical'],
   ARRAY['2026','2027'], 2.9, true,
   'Wake Forest Men''s Soccer — Consistently top-10 D1 program in the ACC.',
   'Two-striker system. Need goal scorers and hardworking wide midfielders.'),

  (coach5, cuid5,
   'Georgetown University', 'D1', 'DC',
   '4-2-3-1', 'male', ARRAY['possession', 'counter_attack'],
   ARRAY['2026','2027','2028'], 3.0, true,
   'Georgetown Men''s Soccer — Big East program in the heart of Washington DC.',
   'Academically strong institution. Seeking tactically intelligent players.'),

  (coach6, cuid6,
   'Clemson University', 'D1', 'SC',
   '3-5-2', 'male', ARRAY['direct', 'high_press'],
   ARRAY['2026','2027'], 2.7, true,
   'Clemson Men''s Soccer — ACC program with elite athletic facilities and strong professional pipeline.',
   'Three-back system. Need dynamic wing-backs, a dominant striker, and a controlling DM.'),

  (coach7, cuid7,
   'University of Virginia', 'D1', 'VA',
   '4-3-3', 'male', ARRAY['possession', 'patient_buildup'],
   ARRAY['2027','2028'], 3.0, true,
   'UVA Men''s Soccer — Consistent Top 25 program and national championship pedigree.',
   'Patient possession style. Looking for technical players who are comfortable on the ball under pressure.'),

  (coach8, cuid8,
   'Syracuse University', 'D1', 'NY',
   '4-1-4-1', 'male', ARRAY['counter_attack', 'direct'],
   ARRAY['2026','2027','2028'], 2.7, true,
   'Syracuse Men''s Soccer — ACC program in the Northeast with strong alumni network.',
   'Counter-attacking style. Need pace on the wings, a single dominant striker, and a solid DM anchor.'),

  -- ── D2 (6) ──────────────────────────────────────────────────────────────────
  (coach9, cuid9,
   'Grand Canyon University', 'D2', 'AZ',
   '4-4-2', 'male', ARRAY['direct', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.5, true,
   'GCU Men''s Soccer — Western Athletic Conference. Fast-paced physical soccer in a world-class facility.',
   'Athletic players with positional versatility. Strong D2 opportunity with partial scholarship availability.'),

  (coach10, cuid10,
   'Cal Poly San Luis Obispo', 'D2', 'CA',
   '4-3-3', 'male', ARRAY['possession', 'technical'],
   ARRAY['2027','2028'], 2.7, true,
   'Cal Poly SLO Men''s Soccer — Big West Conference. Beautiful Central Coast campus.',
   'Technical players who can play in a possession-based system. GPA 2.7+ preferred.'),

  (coach11, cuid11,
   'Nova Southeastern University', 'D2', 'FL',
   '4-2-3-1', 'male', ARRAY['possession', 'high_press'],
   ARRAY['2026','2027'], 2.6, true,
   'NSU Men''s Soccer — Sunshine State Conference. South Florida location with great weather year-round.',
   'Technically gifted players who press relentlessly. Large roster with scholarship opportunities.'),

  (coach12, cuid12,
   'Wheeling University', 'D2', 'WV',
   '4-3-3', 'male', ARRAY['balanced', 'possession'],
   ARRAY['2026','2027','2028'], 2.5, true,
   'Wheeling Men''s Soccer — Mountain East Conference. Small university with personal attention to athletes.',
   'Competitive D2 program with scholarship availability. Looking to develop talented players.'),

  (coach13, cuid13,
   'Lynn University', 'D2', 'FL',
   '4-4-2', 'male', ARRAY['direct', 'high_press'],
   ARRAY['2026','2027'], 2.6, true,
   'Lynn University Men''s Soccer — SSC program in Boca Raton. International soccer culture.',
   'Internationally diverse program. Bilingual communication a plus. Partial scholarships available.'),

  (coach14, cuid14,
   'Davis & Elkins College', 'D2', 'WV',
   '3-5-2', 'male', ARRAY['possession', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.4, true,
   'D&E Men''s Soccer — Mountain East Conference. Small college with strong athletic tradition.',
   'Three-back system. Need intelligent central midfielders who can play both ways.'),

  -- ── D3 (4) ──────────────────────────────────────────────────────────────────
  (coach15, cuid15,
   'Williams College', 'D3', 'MA',
   '4-3-3', 'male', ARRAY['possession', 'balanced'],
   ARRAY['2026','2027','2028'], 3.0, true,
   'Williams Men''s Soccer — NESCAC. #1 liberal arts college in the US. Highly competitive admissions.',
   'High academic bar required. Seeking well-rounded scholar-athletes who value the full college experience.'),

  (coach16, cuid16,
   'Amherst College', 'D3', 'MA',
   '4-2-3-1', 'male', ARRAY['technical', 'possession'],
   ARRAY['2026','2027'], 3.1, true,
   'Amherst Men''s Soccer — NESCAC. Elite academics meets competitive D3 soccer.',
   'Academically driven athletes only. Need technically gifted players who understand the game deeply.'),

  (coach17, cuid17,
   'Middlebury College', 'D3', 'VT',
   '4-4-2', 'male', ARRAY['balanced', 'direct'],
   ARRAY['2027','2028'], 2.9, true,
   'Middlebury Men''s Soccer — NESCAC. Stunning Vermont campus with a passionate soccer culture.',
   'Classic 4-4-2 system. Looking for hard-working, coachable players who compete for 90 minutes.'),

  (coach18, cuid18,
   'Tufts University', 'D3', 'MA',
   '4-3-3', 'male', ARRAY['high_press', 'vertical'],
   ARRAY['2026','2027','2028'], 3.0, true,
   'Tufts Men''s Soccer — NESCAC. Research university near Boston with a competitive soccer program.',
   'High-energy, pressing style. Players who can recover the ball quickly and transition fast.'),

  -- ── NAIA (2) ────────────────────────────────────────────────────────────────
  (coach19, cuid19,
   'Lindsey Wilson College', 'NAIA', 'KY',
   '4-3-3', 'male', ARRAY['direct', 'counter_attack'],
   ARRAY['2026','2027','2028'], 2.3, true,
   'Lindsey Wilson Men''s Soccer — NAIA powerhouse and multiple national championship program.',
   'Full scholarship opportunities available. One of the top NAIA programs in the country.'),

  (coach20, cuid20,
   'Benedictine University', 'NAIA', 'IL',
   '4-4-2', 'male', ARRAY['balanced', 'possession'],
   ARRAY['2026','2027'], 2.4, true,
   'Benedictine Men''s Soccer — Chicagoland Collegiate Athletic Conference. Solid NAIA program near Chicago.',
   'Scholarship availability. Seeking committed players who want to compete at the college level.')

ON CONFLICT (id) DO NOTHING;

-- ─── Position Requirements ────────────────────────────────────────────────────

-- Coach 1 — UNC — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach1, 'lw',  2.8, 'left',  168, ARRAY['pace','dribbling','1v1','crossing'],          true),
  (coach1, 'rw',  2.8, 'right', 168, ARRAY['pace','crossing','dribbling','work_rate'],     true),
  (coach1, 'st',  2.8, NULL,    175, ARRAY['finishing','movement','hold_up_play','pace'],  true),
  (coach1, 'cm',  2.8, NULL,    170, ARRAY['passing_range','press_resistance','box_to_box','vision'], true),
  (coach1, 'cb',  2.8, 'right', 180, ARRAY['aerial_ability','positioning','leadership','passing'],    true),
  (coach1, 'gk',  2.8, 'right', 182, ARRAY['shot_stopping','distribution','command_of_area'],        true)
ON CONFLICT DO NOTHING;

-- Coach 2 — Stanford — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach2, 'cam', 3.2, NULL,    170, ARRAY['creativity','vision','technical_ability','dribbling'],  true),
  (coach2, 'lw',  3.2, 'left',  165, ARRAY['pace','dribbling','pressing','crossing'],               true),
  (coach2, 'rw',  3.2, 'right', 165, ARRAY['pace','crossing','work_rate','1v1'],                    true),
  (coach2, 'cdm', 3.2, NULL,    172, ARRAY['defensive_awareness','passing','interceptions','positioning'], true),
  (coach2, 'st',  3.2, NULL,    174, ARRAY['movement','finishing','pressing','hold_up_play'],        true),
  (coach2, 'cb',  3.2, NULL,    178, ARRAY['reading_game','passing','aerial_ability','composure'],   true)
ON CONFLICT DO NOTHING;

-- Coach 3 — Indiana — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach3, 'st',  2.8, NULL,    174, ARRAY['pace','finishing','pressing','movement'],                true),
  (coach3, 'lw',  2.8, 'left',  165, ARRAY['pace','dribbling','1v1','cutting_inside'],              true),
  (coach3, 'rw',  2.8, 'right', 165, ARRAY['pace','crossing','finishing','work_rate'],              true),
  (coach3, 'cm',  2.8, NULL,    170, ARRAY['box_to_box','pressing','passing','work_rate'],           true),
  (coach3, 'cb',  2.8, 'right', 178, ARRAY['aerial_ability','strength','positioning','pace'],       true),
  (coach3, 'gk',  2.8, 'right', 183, ARRAY['shot_stopping','distribution','command_of_area','footwork'], true)
ON CONFLICT DO NOTHING;

-- Coach 4 — Wake Forest — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach4, 'st',  2.9, NULL,    174, ARRAY['finishing','aerial_ability','hold_up_play','movement'], true),
  (coach4, 'cf',  2.9, NULL,    172, ARRAY['movement','pressing','dribbling','finishing'],           true),
  (coach4, 'cm',  2.9, NULL,    170, ARRAY['passing','vision','work_rate','press_resistance'],      true),
  (coach4, 'rm',  2.9, 'right', 165, ARRAY['crossing','work_rate','pace','defending'],              true),
  (coach4, 'lm',  2.9, 'left',  165, ARRAY['crossing','work_rate','pace','dribbling'],              true),
  (coach4, 'rb',  2.9, 'right', 168, ARRAY['attacking_runs','crossing','defending','pace'],         true),
  (coach4, 'lb',  2.9, 'left',  168, ARRAY['attacking_runs','pace','defending','crossing'],         true)
ON CONFLICT DO NOTHING;

-- Coach 5 — Georgetown — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach5, 'cam', 3.0, NULL,    170, ARRAY['creativity','vision','technical_ability','leadership'], true),
  (coach5, 'lw',  3.0, 'left',  163, ARRAY['pace','dribbling','pressing','crossing'],              true),
  (coach5, 'rw',  3.0, 'right', 163, ARRAY['pace','work_rate','crossing','1v1'],                   true),
  (coach5, 'cdm', 3.0, NULL,    172, ARRAY['defensive_awareness','positioning','passing','leadership'], true),
  (coach5, 'st',  3.0, NULL,    172, ARRAY['movement','finishing','pressing','work_rate'],          true),
  (coach5, 'cb',  3.0, 'right', 178, ARRAY['aerial_ability','composure','passing','positioning'],  true)
ON CONFLICT DO NOTHING;

-- Coach 6 — Clemson — 3-5-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach6, 'st',  2.7, NULL,    176, ARRAY['pace','finishing','aerial_ability','hold_up_play'],     true),
  (coach6, 'cf',  2.7, NULL,    172, ARRAY['movement','pressing','finishing','dribbling'],           true),
  (coach6, 'cm',  2.7, NULL,    170, ARRAY['box_to_box','work_rate','passing','pressing'],           true),
  (coach6, 'cdm', 2.7, NULL,    174, ARRAY['defensive_awareness','aerial_ability','positioning','tackling'], true),
  (coach6, 'rb',  2.7, 'right', 170, ARRAY['pace','crossing','defending','attacking_runs'],         true),
  (coach6, 'lb',  2.7, 'left',  170, ARRAY['pace','crossing','work_rate','defending'],              true),
  (coach6, 'cb',  2.7, NULL,    178, ARRAY['aerial_ability','strength','positioning','leadership'], true)
ON CONFLICT DO NOTHING;

-- Coach 7 — UVA — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach7, 'lw',  3.0, 'left',  165, ARRAY['technical_ability','dribbling','composure','creativity'], true),
  (coach7, 'rw',  3.0, 'right', 165, ARRAY['technical_ability','pace','crossing','1v1'],            true),
  (coach7, 'st',  3.0, NULL,    174, ARRAY['finishing','movement','hold_up_play','pressing'],        true),
  (coach7, 'cm',  3.0, NULL,    168, ARRAY['passing_range','vision','press_resistance','work_rate'], true),
  (coach7, 'gk',  3.0, 'right', 183, ARRAY['footwork','distribution','shot_stopping','composure'],  true)
ON CONFLICT DO NOTHING;

-- Coach 8 — Syracuse — 4-1-4-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach8, 'st',  2.7, NULL,    175, ARRAY['pace','finishing','aerial_ability','hold_up_play'],      true),
  (coach8, 'lm',  2.7, 'left',  165, ARRAY['pace','work_rate','crossing','dribbling'],              true),
  (coach8, 'rm',  2.7, 'right', 165, ARRAY['pace','crossing','defending','work_rate'],              true),
  (coach8, 'cm',  2.7, NULL,    168, ARRAY['passing','creativity','vision','box_to_box'],            true),
  (coach8, 'cdm', 2.7, NULL,    174, ARRAY['defensive_awareness','tackling','positioning','passing'], true),
  (coach8, 'cb',  2.7, 'right', 178, ARRAY['aerial_ability','strength','positioning','leadership'], true)
ON CONFLICT DO NOTHING;

-- Coach 9 — Grand Canyon — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach9, 'lm',  2.5, 'left',  163, ARRAY['work_rate','pace','crossing','defending'],             true),
  (coach9, 'rm',  2.5, 'right', 163, ARRAY['work_rate','pace','crossing','dribbling'],             true),
  (coach9, 'st',  2.5, NULL,    174, ARRAY['aerial_ability','hold_up_play','finishing','pace'],     true),
  (coach9, 'cf',  2.5, NULL,    170, ARRAY['movement','pressing','pace','finishing'],               true),
  (coach9, 'cb',  2.5, NULL,    178, ARRAY['aerial_ability','strength','positioning','tackling'],   true),
  (coach9, 'gk',  2.5, 'right', 182, ARRAY['shot_stopping','distribution','command_of_area'],      true),
  (coach9, 'cdm', 2.5, NULL,    170, ARRAY['defensive_awareness','tackling','positioning','work_rate'], true)
ON CONFLICT DO NOTHING;

-- Coach 10 — Cal Poly — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach10, 'lw',  2.7, 'left',  163, ARRAY['pace','technical_ability','dribbling','crossing'],     true),
  (coach10, 'rw',  2.7, 'right', 163, ARRAY['pace','crossing','work_rate','1v1'],                   true),
  (coach10, 'st',  2.7, NULL,    172, ARRAY['finishing','movement','pressing','hold_up_play'],       true),
  (coach10, 'cm',  2.7, NULL,    168, ARRAY['passing','work_rate','positioning','press_resistance'], true),
  (coach10, 'rb',  2.7, 'right', 168, ARRAY['attacking_runs','crossing','defending','pace'],         true),
  (coach10, 'lb',  2.7, 'left',  168, ARRAY['attacking_runs','pace','defending','crossing'],         true),
  (coach10, 'cb',  2.7, NULL,    176, ARRAY['aerial_ability','composure','positioning','passing'],   true)
ON CONFLICT DO NOTHING;

-- Coach 11 — Nova Southeastern — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach11, 'cam', 2.6, NULL,    168, ARRAY['creativity','dribbling','vision','pressing'],          true),
  (coach11, 'lw',  2.6, 'left',  163, ARRAY['pace','dribbling','pressing','1v1'],                   true),
  (coach11, 'rw',  2.6, 'right', 163, ARRAY['pace','work_rate','crossing','dribbling'],             true),
  (coach11, 'st',  2.6, NULL,    172, ARRAY['finishing','pressing','movement','pace'],               true),
  (coach11, 'cb',  2.6, NULL,    175, ARRAY['aerial_ability','positioning','tackling','composure'],  true),
  (coach11, 'cdm', 2.6, NULL,    170, ARRAY['pressing','positioning','passing','defensive_awareness'], true)
ON CONFLICT DO NOTHING;

-- Coach 12 — Wheeling — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach12, 'st',  2.5, NULL,    172, ARRAY['finishing','movement','work_rate','pace'],              true),
  (coach12, 'lw',  2.5, 'left',  160, ARRAY['pace','dribbling','crossing','work_rate'],              true),
  (coach12, 'rw',  2.5, 'right', 160, ARRAY['pace','work_rate','crossing','finishing'],              true),
  (coach12, 'cm',  2.5, NULL,    165, ARRAY['passing','work_rate','box_to_box','positioning'],       true),
  (coach12, 'gk',  2.5, 'right', 178, ARRAY['shot_stopping','distribution','command_of_area'],      true),
  (coach12, 'cb',  2.5, NULL,    175, ARRAY['aerial_ability','positioning','strength','tackling'],   true)
ON CONFLICT DO NOTHING;

-- Coach 13 — Lynn University — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach13, 'rm',  2.6, 'right', 163, ARRAY['pace','crossing','work_rate','defending'],             true),
  (coach13, 'lm',  2.6, 'left',  163, ARRAY['pace','dribbling','crossing','work_rate'],             true),
  (coach13, 'st',  2.6, NULL,    172, ARRAY['finishing','aerial_ability','hold_up_play','work_rate'], true),
  (coach13, 'cf',  2.6, NULL,    168, ARRAY['movement','pressing','pace','finishing'],               true),
  (coach13, 'cb',  2.6, NULL,    175, ARRAY['aerial_ability','strength','leadership','positioning'], true),
  (coach13, 'cm',  2.6, NULL,    165, ARRAY['passing','vision','work_rate','positioning'],           true)
ON CONFLICT DO NOTHING;

-- Coach 14 — Davis & Elkins — 3-5-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach14, 'cm',  2.4, NULL,    168, ARRAY['passing','box_to_box','vision','work_rate'],           true),
  (coach14, 'cdm', 2.4, NULL,    172, ARRAY['defensive_awareness','positioning','passing','tackling'], true),
  (coach14, 'st',  2.4, NULL,    172, ARRAY['finishing','hold_up_play','aerial_ability','pace'],     true),
  (coach14, 'cf',  2.4, NULL,    168, ARRAY['movement','pressing','work_rate','finishing'],          true),
  (coach14, 'cb',  2.4, NULL,    176, ARRAY['aerial_ability','strength','positioning','leadership'], true),
  (coach14, 'rb',  2.4, 'right', 165, ARRAY['attacking_runs','crossing','defending','work_rate'],   true),
  (coach14, 'lb',  2.4, 'left',  165, ARRAY['attacking_runs','pace','defending','crossing'],        true)
ON CONFLICT DO NOTHING;

-- Coach 15 — Williams College — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach15, 'lw',  3.0, 'left',  163, ARRAY['technical_ability','intelligence','work_rate','dribbling'], true),
  (coach15, 'rw',  3.0, 'right', 163, ARRAY['technical_ability','pace','crossing','1v1'],              true),
  (coach15, 'st',  3.0, NULL,    170, ARRAY['movement','finishing','pressing','intelligence'],           true),
  (coach15, 'cb',  3.0, 'right', 178, ARRAY['reading_game','passing','aerial_ability','composure'],     true),
  (coach15, 'cm',  3.0, NULL,    168, ARRAY['vision','technique','intelligence','work_rate'],            true),
  (coach15, 'gk',  3.0, 'right', 180, ARRAY['shot_stopping','distribution','composure','footwork'],     true)
ON CONFLICT DO NOTHING;

-- Coach 16 — Amherst — 4-2-3-1
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach16, 'cam', 3.1, NULL,    168, ARRAY['creativity','vision','technical_ability','intelligence'], true),
  (coach16, 'lw',  3.1, 'left',  163, ARRAY['technical_ability','pace','dribbling','pressing'],        true),
  (coach16, 'rw',  3.1, 'right', 163, ARRAY['pace','crossing','work_rate','1v1'],                     true),
  (coach16, 'st',  3.1, NULL,    170, ARRAY['movement','pressing','finishing','intelligence'],          true),
  (coach16, 'cdm', 3.1, NULL,    170, ARRAY['positioning','passing','defensive_awareness','composure'], true),
  (coach16, 'cb',  3.1, NULL,    176, ARRAY['aerial_ability','composure','reading_game','passing'],     true)
ON CONFLICT DO NOTHING;

-- Coach 17 — Middlebury — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach17, 'st',  2.9, NULL,    172, ARRAY['finishing','aerial_ability','work_rate','movement'],   true),
  (coach17, 'cf',  2.9, NULL,    168, ARRAY['movement','pace','pressing','finishing'],               true),
  (coach17, 'cm',  2.9, NULL,    168, ARRAY['work_rate','passing','box_to_box','positioning'],      true),
  (coach17, 'gk',  2.9, 'right', 180, ARRAY['shot_stopping','command_of_area','distribution'],     true),
  (coach17, 'rm',  2.9, 'right', 163, ARRAY['work_rate','crossing','pace','defending'],             true),
  (coach17, 'lm',  2.9, 'left',  163, ARRAY['work_rate','pace','dribbling','crossing'],             true)
ON CONFLICT DO NOTHING;

-- Coach 18 — Tufts — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach18, 'lw',  3.0, 'left',  163, ARRAY['pace','pressing','dribbling','work_rate'],             true),
  (coach18, 'rw',  3.0, 'right', 163, ARRAY['pace','crossing','pressing','work_rate'],              true),
  (coach18, 'st',  3.0, NULL,    170, ARRAY['movement','pressing','finishing','pace'],               true),
  (coach18, 'cb',  3.0, NULL,    175, ARRAY['aerial_ability','positioning','strength','composure'], true),
  (coach18, 'cm',  3.0, NULL,    168, ARRAY['pressing','passing','work_rate','intelligence'],        true)
ON CONFLICT DO NOTHING;

-- Coach 19 — Lindsey Wilson — NAIA — 4-3-3
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach19, 'st',  2.3, NULL,    170, ARRAY['finishing','pace','aerial_ability','hold_up_play'],     true),
  (coach19, 'lw',  2.3, 'left',  160, ARRAY['pace','dribbling','crossing','work_rate'],              true),
  (coach19, 'rw',  2.3, 'right', 160, ARRAY['pace','work_rate','crossing','finishing'],              true),
  (coach19, 'cm',  2.3, NULL,    163, ARRAY['work_rate','box_to_box','passing','pressing'],          true),
  (coach19, 'gk',  2.3, 'right', 178, ARRAY['shot_stopping','distribution','command_of_area'],      true),
  (coach19, 'cb',  2.3, NULL,    173, ARRAY['aerial_ability','strength','positioning','tackling'],   true)
ON CONFLICT DO NOTHING;

-- Coach 20 — Benedictine — NAIA — 4-4-2
INSERT INTO coach_position_requirements (coach_id, position_key, min_gpa, preferred_foot, min_height_cm, required_qualities, is_published) VALUES
  (coach20, 'cm',  2.4, NULL,    165, ARRAY['passing','work_rate','positioning','vision'],            true),
  (coach20, 'st',  2.4, NULL,    170, ARRAY['finishing','work_rate','movement','hold_up_play'],       true),
  (coach20, 'cf',  2.4, NULL,    168, ARRAY['pace','pressing','movement','finishing'],                true),
  (coach20, 'cb',  2.4, NULL,    173, ARRAY['aerial_ability','positioning','leadership','tackling'],  true),
  (coach20, 'gk',  2.4, 'right', 178, ARRAY['shot_stopping','command_of_area','distribution'],      true),
  (coach20, 'lm',  2.4, 'left',  160, ARRAY['work_rate','pace','crossing','dribbling'],              true),
  (coach20, 'rm',  2.4, 'right', 160, ARRAY['work_rate','pace','crossing','defending'],              true)
ON CONFLICT DO NOTHING;

-- ─── Roster Slots ─────────────────────────────────────────────────────────────

INSERT INTO roster_slots (coach_id, position_key, depth_order, slot_status, graduation_year) VALUES
  -- Coach 1 UNC
  (coach1, 'lw', 1, 'open',       2027), (coach1, 'lw', 2, 'open',       2028),
  (coach1, 'rw', 1, 'open',       2027), (coach1, 'st', 1, 'graduating', 2026),
  (coach1, 'st', 2, 'open',       2027), (coach1, 'cm', 1, 'filled',     2027),
  (coach1, 'cm', 2, 'open',       2027), (coach1, 'cb', 1, 'filled',     2026),
  (coach1, 'cb', 2, 'open',       2028), (coach1, 'gk', 1, 'graduating', 2026),
  -- Coach 2 Stanford
  (coach2, 'cam',1, 'open',       2026), (coach2, 'lw', 1, 'open',       2027),
  (coach2, 'rw', 1, 'graduating', 2026), (coach2, 'rw', 2, 'open',       2027),
  (coach2, 'cdm',1, 'filled',     2027), (coach2, 'st', 1, 'open',       2026),
  (coach2, 'cb', 1, 'filled',     2027), (coach2, 'cb', 2, 'open',       2028),
  -- Coach 3 Indiana
  (coach3, 'st', 1, 'open',       2027), (coach3, 'lw', 1, 'open',       2026),
  (coach3, 'rw', 1, 'graduating', 2026), (coach3, 'rw', 2, 'open',       2027),
  (coach3, 'cm', 1, 'open',       2027), (coach3, 'cb', 1, 'filled',     2026),
  (coach3, 'cb', 2, 'open',       2028), (coach3, 'gk', 1, 'open',       2027),
  -- Coach 4 Wake Forest
  (coach4, 'st', 1, 'open',       2026), (coach4, 'cf', 1, 'open',       2027),
  (coach4, 'cm', 1, 'filled',     2026), (coach4, 'cm', 2, 'open',       2027),
  (coach4, 'rm', 1, 'open',       2026), (coach4, 'lm', 1, 'graduating', 2026),
  (coach4, 'lm', 2, 'open',       2027), (coach4, 'rb', 1, 'open',       2027),
  (coach4, 'lb', 1, 'open',       2027),
  -- Coach 5 Georgetown
  (coach5, 'cam',1, 'open',       2026), (coach5, 'lw', 1, 'open',       2027),
  (coach5, 'rw', 1, 'open',       2026), (coach5, 'st', 1, 'graduating', 2026),
  (coach5, 'st', 2, 'open',       2027), (coach5, 'cdm',1, 'filled',     2027),
  (coach5, 'cb', 1, 'open',       2027),
  -- Coach 6 Clemson
  (coach6, 'st', 1, 'open',       2026), (coach6, 'cf', 1, 'graduating', 2026),
  (coach6, 'cf', 2, 'open',       2027), (coach6, 'cm', 1, 'filled',     2026),
  (coach6, 'cm', 2, 'open',       2027), (coach6, 'cdm',1, 'open',       2027),
  (coach6, 'rb', 1, 'open',       2026), (coach6, 'lb', 1, 'graduating', 2026),
  (coach6, 'lb', 2, 'open',       2027), (coach6, 'cb', 1, 'filled',     2027),
  (coach6, 'cb', 2, 'open',       2028),
  -- Coach 7 UVA
  (coach7, 'lw', 1, 'open',       2027), (coach7, 'rw', 1, 'graduating', 2026),
  (coach7, 'rw', 2, 'open',       2027), (coach7, 'st', 1, 'open',       2028),
  (coach7, 'cm', 1, 'filled',     2026), (coach7, 'cm', 2, 'open',       2027),
  (coach7, 'gk', 1, 'open',       2027),
  -- Coach 8 Syracuse
  (coach8, 'st', 1, 'open',       2026), (coach8, 'lm', 1, 'graduating', 2026),
  (coach8, 'lm', 2, 'open',       2027), (coach8, 'rm', 1, 'open',       2026),
  (coach8, 'cm', 1, 'filled',     2027), (coach8, 'cm', 2, 'open',       2028),
  (coach8, 'cdm',1, 'open',       2027), (coach8, 'cb', 1, 'open',       2027),
  -- Coach 9 GCU
  (coach9, 'lm', 1, 'open',       2026), (coach9, 'lm', 2, 'open',       2027),
  (coach9, 'rm', 1, 'open',       2026), (coach9, 'st', 1, 'open',       2027),
  (coach9, 'st', 2, 'open',       2028), (coach9, 'cf', 1, 'graduating', 2026),
  (coach9, 'cb', 1, 'open',       2027), (coach9, 'gk', 1, 'open',       2027),
  (coach9, 'cdm',1, 'open',       2026),
  -- Coach 10 Cal Poly
  (coach10,'lw', 1, 'open',       2027), (coach10,'lw', 2, 'open',       2028),
  (coach10,'rw', 1, 'graduating', 2026), (coach10,'rw', 2, 'open',       2027),
  (coach10,'st', 1, 'open',       2027), (coach10,'cm', 1, 'filled',     2026),
  (coach10,'cm', 2, 'open',       2027), (coach10,'rb', 1, 'open',       2026),
  (coach10,'lb', 1, 'open',       2027), (coach10,'cb', 1, 'open',       2027),
  -- Coach 11 Nova
  (coach11,'cam',1, 'open',       2026), (coach11,'lw', 1, 'open',       2027),
  (coach11,'rw', 1, 'open',       2026), (coach11,'st', 1, 'graduating', 2026),
  (coach11,'st', 2, 'open',       2027), (coach11,'cb', 1, 'open',       2027),
  (coach11,'cdm',1, 'filled',     2026), (coach11,'cdm',2, 'open',       2027),
  -- Coach 12 Wheeling
  (coach12,'st', 1, 'open',       2026), (coach12,'lw', 1, 'open',       2026),
  (coach12,'rw', 1, 'open',       2027), (coach12,'cm', 1, 'graduating', 2026),
  (coach12,'cm', 2, 'open',       2027), (coach12,'gk', 1, 'open',       2026),
  (coach12,'cb', 1, 'open',       2027),
  -- Coach 13 Lynn
  (coach13,'rm', 1, 'open',       2026), (coach13,'lm', 1, 'open',       2026),
  (coach13,'st', 1, 'graduating', 2026), (coach13,'st', 2, 'open',       2027),
  (coach13,'cf', 1, 'open',       2027), (coach13,'cb', 1, 'open',       2026),
  (coach13,'cm', 1, 'open',       2027),
  -- Coach 14 D&E
  (coach14,'cm', 1, 'open',       2026), (coach14,'cdm',1, 'graduating', 2026),
  (coach14,'cdm',2, 'open',       2027), (coach14,'st', 1, 'open',       2026),
  (coach14,'cf', 1, 'open',       2027), (coach14,'cb', 1, 'filled',     2026),
  (coach14,'cb', 2, 'open',       2028), (coach14,'rb', 1, 'open',       2026),
  (coach14,'lb', 1, 'open',       2027),
  -- Coach 15 Williams
  (coach15,'lw', 1, 'graduating', 2026), (coach15,'lw', 2, 'open',       2027),
  (coach15,'rw', 1, 'open',       2026), (coach15,'st', 1, 'open',       2027),
  (coach15,'cb', 1, 'open',       2027), (coach15,'cm', 1, 'filled',     2026),
  (coach15,'cm', 2, 'open',       2028), (coach15,'gk', 1, 'open',       2026),
  -- Coach 16 Amherst
  (coach16,'cam',1, 'open',       2026), (coach16,'lw', 1, 'open',       2027),
  (coach16,'rw', 1, 'graduating', 2026), (coach16,'rw', 2, 'open',       2027),
  (coach16,'st', 1, 'open',       2026), (coach16,'cdm',1, 'filled',     2027),
  (coach16,'cb', 1, 'open',       2027),
  -- Coach 17 Middlebury
  (coach17,'st', 1, 'open',       2027), (coach17,'cf', 1, 'graduating', 2026),
  (coach17,'cf', 2, 'open',       2027), (coach17,'cm', 1, 'open',       2026),
  (coach17,'gk', 1, 'open',       2027), (coach17,'rm', 1, 'open',       2026),
  (coach17,'lm', 1, 'graduating', 2026), (coach17,'lm', 2, 'open',       2027),
  -- Coach 18 Tufts
  (coach18,'lw', 1, 'open',       2027), (coach18,'rw', 1, 'graduating', 2026),
  (coach18,'rw', 2, 'open',       2027), (coach18,'st', 1, 'open',       2026),
  (coach18,'cb', 1, 'open',       2027), (coach18,'cm', 1, 'filled',     2026),
  (coach18,'cm', 2, 'open',       2027),
  -- Coach 19 Lindsey Wilson
  (coach19,'st', 1, 'open',       2026), (coach19,'lw', 1, 'open',       2026),
  (coach19,'lw', 2, 'open',       2027), (coach19,'rw', 1, 'graduating', 2026),
  (coach19,'rw', 2, 'open',       2027), (coach19,'cm', 1, 'open',       2026),
  (coach19,'gk', 1, 'open',       2027), (coach19,'cb', 1, 'open',       2026),
  -- Coach 20 Benedictine
  (coach20,'cm', 1, 'open',       2026), (coach20,'st', 1, 'graduating', 2026),
  (coach20,'st', 2, 'open',       2027), (coach20,'cf', 1, 'open',       2026),
  (coach20,'cb', 1, 'open',       2027), (coach20,'gk', 1, 'open',       2026),
  (coach20,'lm', 1, 'open',       2026), (coach20,'rm', 1, 'graduating', 2026),
  (coach20,'rm', 2, 'open',       2027)
ON CONFLICT DO NOTHING;

END $$;

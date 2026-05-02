-- Migration 075: Seed coaches for remaining 25 states with no programs
-- Covers: AL, AK, DE, GA, HI, ID, KS, LA, ME, MD, MI, MN, MS, MT,
--         NE, NV, NH, NJ, ND, OH, RI, SD, TN, WI, WY
-- Every US state now has at least one soccer program in the app.

SET search_path TO public, extensions;

DO $$
DECLARE
  -- Auth user UUIDs (42–66)
  cuid42 UUID := 'b2000000-0000-0000-0000-000000000042';
  cuid43 UUID := 'b2000000-0000-0000-0000-000000000043';
  cuid44 UUID := 'b2000000-0000-0000-0000-000000000044';
  cuid45 UUID := 'b2000000-0000-0000-0000-000000000045';
  cuid46 UUID := 'b2000000-0000-0000-0000-000000000046';
  cuid47 UUID := 'b2000000-0000-0000-0000-000000000047';
  cuid48 UUID := 'b2000000-0000-0000-0000-000000000048';
  cuid49 UUID := 'b2000000-0000-0000-0000-000000000049';
  cuid50 UUID := 'b2000000-0000-0000-0000-000000000050';
  cuid51 UUID := 'b2000000-0000-0000-0000-000000000051';
  cuid52 UUID := 'b2000000-0000-0000-0000-000000000052';
  cuid53 UUID := 'b2000000-0000-0000-0000-000000000053';
  cuid54 UUID := 'b2000000-0000-0000-0000-000000000054';
  cuid55 UUID := 'b2000000-0000-0000-0000-000000000055';
  cuid56 UUID := 'b2000000-0000-0000-0000-000000000056';
  cuid57 UUID := 'b2000000-0000-0000-0000-000000000057';
  cuid58 UUID := 'b2000000-0000-0000-0000-000000000058';
  cuid59 UUID := 'b2000000-0000-0000-0000-000000000059';
  cuid60 UUID := 'b2000000-0000-0000-0000-000000000060';
  cuid61 UUID := 'b2000000-0000-0000-0000-000000000061';
  cuid62 UUID := 'b2000000-0000-0000-0000-000000000062';
  cuid63 UUID := 'b2000000-0000-0000-0000-000000000063';
  cuid64 UUID := 'b2000000-0000-0000-0000-000000000064';
  cuid65 UUID := 'b2000000-0000-0000-0000-000000000065';
  cuid66 UUID := 'b2000000-0000-0000-0000-000000000066';

  -- Coach profile UUIDs (42–66)
  coach42 UUID := 'c3000000-0000-0000-0000-000000000042';
  coach43 UUID := 'c3000000-0000-0000-0000-000000000043';
  coach44 UUID := 'c3000000-0000-0000-0000-000000000044';
  coach45 UUID := 'c3000000-0000-0000-0000-000000000045';
  coach46 UUID := 'c3000000-0000-0000-0000-000000000046';
  coach47 UUID := 'c3000000-0000-0000-0000-000000000047';
  coach48 UUID := 'c3000000-0000-0000-0000-000000000048';
  coach49 UUID := 'c3000000-0000-0000-0000-000000000049';
  coach50 UUID := 'c3000000-0000-0000-0000-000000000050';
  coach51 UUID := 'c3000000-0000-0000-0000-000000000051';
  coach52 UUID := 'c3000000-0000-0000-0000-000000000052';
  coach53 UUID := 'c3000000-0000-0000-0000-000000000053';
  coach54 UUID := 'c3000000-0000-0000-0000-000000000054';
  coach55 UUID := 'c3000000-0000-0000-0000-000000000055';
  coach56 UUID := 'c3000000-0000-0000-0000-000000000056';
  coach57 UUID := 'c3000000-0000-0000-0000-000000000057';
  coach58 UUID := 'c3000000-0000-0000-0000-000000000058';
  coach59 UUID := 'c3000000-0000-0000-0000-000000000059';
  coach60 UUID := 'c3000000-0000-0000-0000-000000000060';
  coach61 UUID := 'c3000000-0000-0000-0000-000000000061';
  coach62 UUID := 'c3000000-0000-0000-0000-000000000062';
  coach63 UUID := 'c3000000-0000-0000-0000-000000000063';
  coach64 UUID := 'c3000000-0000-0000-0000-000000000064';
  coach65 UUID := 'c3000000-0000-0000-0000-000000000065';
  coach66 UUID := 'c3000000-0000-0000-0000-000000000066';

BEGIN

-- ─── Auth Users ───────────────────────────────────────────────────────────────
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, reauthentication_token,
  email_change, email_change_token_new, email_change_token_current,
  created_at, updated_at, aud, role
) VALUES
  (cuid42,'00000000-0000-0000-0000-000000000000','coach.bishop@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid43,'00000000-0000-0000-0000-000000000000','coach.garrett@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid44,'00000000-0000-0000-0000-000000000000','coach.payne@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid45,'00000000-0000-0000-0000-000000000000','coach.shaw@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid46,'00000000-0000-0000-0000-000000000000','coach.howell@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid47,'00000000-0000-0000-0000-000000000000','coach.barton@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid48,'00000000-0000-0000-0000-000000000000','coach.mcbride@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid49,'00000000-0000-0000-0000-000000000000','coach.dominguez@lanista.test',crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid50,'00000000-0000-0000-0000-000000000000','coach.vance@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid51,'00000000-0000-0000-0000-000000000000','coach.norton@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid52,'00000000-0000-0000-0000-000000000000','coach.hammond@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid53,'00000000-0000-0000-0000-000000000000','coach.wolfe@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid54,'00000000-0000-0000-0000-000000000000','coach.porter@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid55,'00000000-0000-0000-0000-000000000000','coach.golden@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid56,'00000000-0000-0000-0000-000000000000','coach.sparks@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid57,'00000000-0000-0000-0000-000000000000','coach.malone@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid58,'00000000-0000-0000-0000-000000000000','coach.douglas@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid59,'00000000-0000-0000-0000-000000000000','coach.griffin@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid60,'00000000-0000-0000-0000-000000000000','coach.horton@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid61,'00000000-0000-0000-0000-000000000000','coach.harmon@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid62,'00000000-0000-0000-0000-000000000000','coach.mcgee@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid63,'00000000-0000-0000-0000-000000000000','coach.bowers@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid64,'00000000-0000-0000-0000-000000000000','coach.byrd@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid65,'00000000-0000-0000-0000-000000000000','coach.frost@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated'),
  (cuid66,'00000000-0000-0000-0000-000000000000','coach.soto@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}','','','','','','',NOW(),NOW(),'authenticated','authenticated')
ON CONFLICT (id) DO NOTHING;

-- ─── Auth Identities ──────────────────────────────────────────────────────────
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at) VALUES
  (gen_random_uuid(),cuid42,cuid42::text,'email',jsonb_build_object('sub',cuid42::text,'email','coach.bishop@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid43,cuid43::text,'email',jsonb_build_object('sub',cuid43::text,'email','coach.garrett@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid44,cuid44::text,'email',jsonb_build_object('sub',cuid44::text,'email','coach.payne@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid45,cuid45::text,'email',jsonb_build_object('sub',cuid45::text,'email','coach.shaw@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid46,cuid46::text,'email',jsonb_build_object('sub',cuid46::text,'email','coach.howell@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid47,cuid47::text,'email',jsonb_build_object('sub',cuid47::text,'email','coach.barton@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid48,cuid48::text,'email',jsonb_build_object('sub',cuid48::text,'email','coach.mcbride@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid49,cuid49::text,'email',jsonb_build_object('sub',cuid49::text,'email','coach.dominguez@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid50,cuid50::text,'email',jsonb_build_object('sub',cuid50::text,'email','coach.vance@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid51,cuid51::text,'email',jsonb_build_object('sub',cuid51::text,'email','coach.norton@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid52,cuid52::text,'email',jsonb_build_object('sub',cuid52::text,'email','coach.hammond@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid53,cuid53::text,'email',jsonb_build_object('sub',cuid53::text,'email','coach.wolfe@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid54,cuid54::text,'email',jsonb_build_object('sub',cuid54::text,'email','coach.porter@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid55,cuid55::text,'email',jsonb_build_object('sub',cuid55::text,'email','coach.golden@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid56,cuid56::text,'email',jsonb_build_object('sub',cuid56::text,'email','coach.sparks@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid57,cuid57::text,'email',jsonb_build_object('sub',cuid57::text,'email','coach.malone@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid58,cuid58::text,'email',jsonb_build_object('sub',cuid58::text,'email','coach.douglas@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid59,cuid59::text,'email',jsonb_build_object('sub',cuid59::text,'email','coach.griffin@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid60,cuid60::text,'email',jsonb_build_object('sub',cuid60::text,'email','coach.horton@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid61,cuid61::text,'email',jsonb_build_object('sub',cuid61::text,'email','coach.harmon@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid62,cuid62::text,'email',jsonb_build_object('sub',cuid62::text,'email','coach.mcgee@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid63,cuid63::text,'email',jsonb_build_object('sub',cuid63::text,'email','coach.bowers@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid64,cuid64::text,'email',jsonb_build_object('sub',cuid64::text,'email','coach.byrd@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid65,cuid65::text,'email',jsonb_build_object('sub',cuid65::text,'email','coach.frost@lanista.test'),NOW(),NOW(),NOW()),
  (gen_random_uuid(),cuid66,cuid66::text,'email',jsonb_build_object('sub',cuid66::text,'email','coach.soto@lanista.test'),NOW(),NOW(),NOW())
ON CONFLICT DO NOTHING;

-- ─── Public Users ─────────────────────────────────────────────────────────────
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete) VALUES
  (cuid42,'coach.bishop@lanista.test',  'coach','Kevin',  'Bishop',   'en',true),  -- AL
  (cuid43,'coach.garrett@lanista.test', 'coach','Brian',  'Garrett',  'en',true),  -- AK
  (cuid44,'coach.payne@lanista.test',   'coach','Sandra', 'Payne',    'en',true),  -- DE
  (cuid45,'coach.shaw@lanista.test',    'coach','Marcus', 'Shaw',     'en',true),  -- GA
  (cuid46,'coach.howell@lanista.test',  'coach','Lani',   'Howell',   'en',true),  -- HI
  (cuid47,'coach.barton@lanista.test',  'coach','Trevor', 'Barton',   'en',true),  -- ID
  (cuid48,'coach.mcbride@lanista.test', 'coach','Scott',  'McBride',  'en',true),  -- KS
  (cuid49,'coach.dominguez@lanista.test','coach','Rosa',  'Dominguez','es',true),  -- LA
  (cuid50,'coach.vance@lanista.test',   'coach','Greg',   'Vance',    'en',true),  -- ME
  (cuid51,'coach.norton@lanista.test',  'coach','Alicia', 'Norton',   'en',true),  -- MD
  (cuid52,'coach.hammond@lanista.test', 'coach','Derek',  'Hammond',  'en',true),  -- MI
  (cuid53,'coach.wolfe@lanista.test',   'coach','Rachel', 'Wolfe',    'en',true),  -- MN
  (cuid54,'coach.porter@lanista.test',  'coach','Damon',  'Porter',   'en',true),  -- MS
  (cuid55,'coach.golden@lanista.test',  'coach','Jake',   'Golden',   'en',true),  -- MT
  (cuid56,'coach.sparks@lanista.test',  'coach','Tina',   'Sparks',   'en',true),  -- NE
  (cuid57,'coach.malone@lanista.test',  'coach','Steve',  'Malone',   'en',true),  -- NV
  (cuid58,'coach.douglas@lanista.test', 'coach','Wendy',  'Douglas',  'en',true),  -- NH
  (cuid59,'coach.griffin@lanista.test', 'coach','Omar',   'Griffin',  'en',true),  -- NJ
  (cuid60,'coach.horton@lanista.test',  'coach','Linda',  'Horton',   'en',true),  -- ND
  (cuid61,'coach.harmon@lanista.test',  'coach','Paul',   'Harmon',   'en',true),  -- OH
  (cuid62,'coach.mcgee@lanista.test',   'coach','Claire', 'McGee',    'en',true),  -- RI
  (cuid63,'coach.bowers@lanista.test',  'coach','Roy',    'Bowers',   'en',true),  -- SD
  (cuid64,'coach.byrd@lanista.test',    'coach','Nina',   'Byrd',     'en',true),  -- TN
  (cuid65,'coach.frost@lanista.test',   'coach','Chris',  'Frost',    'en',true),  -- WI
  (cuid66,'coach.soto@lanista.test',    'coach','Isabel', 'Soto',     'es',true)   -- WY
ON CONFLICT (id) DO NOTHING;

-- ─── Coach Profiles ───────────────────────────────────────────────────────────
INSERT INTO coaches (id, user_id, school_name, division, state, primary_formation, gender_program, playing_styles, recruiting_class_years, min_gpa, is_published, bio, recruiting_notes) VALUES

  -- AL — University of Alabama
  (coach42,cuid42,'University of Alabama','D1','AL','4-3-3','male',ARRAY['possession','high_press'],ARRAY['2026','2027','2028'],2.7,true,
   'Alabama Men''s Soccer — Sun Belt Conference. Growing D1 program with SEC-level facilities and strong regional recruiting.',
   'High-pressing 4-3-3. Looking for dynamic wingers and a clinical striker. Strong scholarship packages available.'),

  -- AK — University of Alaska Anchorage
  (coach43,cuid43,'University of Alaska Anchorage','D2','AK','4-4-2','male',ARRAY['direct','balanced'],ARRAY['2026','2027','2028'],2.3,true,
   'UAA Men''s Soccer — Great Northwest Athletic Conference. Unique opportunity to play soccer in Alaska. International recruiting focus.',
   'Physical, direct style. Full scholarship opportunities available. International players encouraged to apply.'),

  -- DE — University of Delaware
  (coach44,cuid44,'University of Delaware','D1','DE','4-2-3-1','male',ARRAY['possession','build_from_back'],ARRAY['2026','2027'],2.8,true,
   'Delaware Men''s Soccer — CAA Conference. Mid-Atlantic location with proximity to Philadelphia and New York recruiting corridors.',
   'Double pivot possession system. Seeking technical players with strong positioning. Excellent academic reputation.'),

  -- GA — Georgia Southern University
  (coach45,cuid45,'Georgia Southern University','D1','GA','4-3-3','male',ARRAY['high_press','vertical'],ARRAY['2026','2027','2028'],2.6,true,
   'Georgia Southern Men''s Soccer — Sun Belt Conference. Fast-paced program in Statesboro with strong Southeast recruiting.',
   'Vertical, attacking 4-3-3. Need pace in all forward positions and a dominant center back. Partial scholarships available.'),

  -- HI — University of Hawaii
  (coach46,cuid46,'University of Hawaii','D1','HI','4-3-3','male',ARRAY['technical','possession'],ARRAY['2026','2027','2028'],2.7,true,
   'Hawaii Men''s Soccer — Big West Conference. Unique Pacific location with strong international and West Coast recruiting pipeline.',
   'Technical possession football. Seeking skillful players who thrive in a warm-weather, high-energy environment.'),

  -- ID — Boise State University
  (coach47,cuid47,'Boise State University','D1','ID','4-2-3-1','male',ARRAY['counter_attack','direct'],ARRAY['2026','2027','2028'],2.5,true,
   'Boise State Men''s Soccer — Mountain West Conference. Growing program in the Pacific Northwest with strong Idaho recruiting base.',
   'Counter-attacking double pivot system. Looking for athletic, quick players who can transition quickly. Scholarships available.'),

  -- KS — University of Kansas
  (coach48,cuid48,'University of Kansas','D1','KS','4-3-3','male',ARRAY['possession','build_from_back'],ARRAY['2026','2027'],2.7,true,
   'Kansas Men''s Soccer — Big 12 Conference. Power Five program with excellent facilities and Midwest recruiting network.',
   'Ball-playing 4-3-3. Seeking technically sound midfielders and composed defenders. Big 12 competition level.'),

  -- LA — Tulane University
  (coach49,cuid49,'Tulane University','D1','LA','4-2-3-1','male',ARRAY['possession','technical'],ARRAY['2026','2027','2028'],2.9,true,
   'Tulane Men''s Soccer — American Athletic Conference in New Orleans. Strong bilingual recruiting and vibrant campus culture.',
   'Possession-based with two pivots. Need creative players who can control the tempo. Bilingual Spanish/English preferred.'),

  -- ME — University of Maine
  (coach50,cuid50,'University of Maine','D1','ME','4-4-2','male',ARRAY['direct','balanced'],ARRAY['2026','2027','2028'],2.5,true,
   'Maine Men''s Soccer — America East Conference. Scenic New England campus with a strong regional recruiting tradition.',
   'Two-striker direct style. Hardworking, athletic players who can handle cold-weather conditions. Aid available.'),

  -- MD — University of Maryland
  (coach51,cuid51,'University of Maryland','D1','MD','4-3-3','male',ARRAY['possession','high_press'],ARRAY['2026','2027'],3.0,true,
   'Maryland Men''s Soccer — Big Ten powerhouse. Perennial Top 10 program and consistent national championship contender.',
   'High-pressing technical 4-3-3. Elite competition level. Seeking players with D1 pedigree and 3.0+ GPA.'),

  -- MI — Michigan State University
  (coach52,cuid52,'Michigan State University','D1','MI','4-2-3-1','male',ARRAY['possession','build_from_back'],ARRAY['2026','2027','2028'],2.8,true,
   'Michigan State Men''s Soccer — Big Ten Conference. Established Midwest program with strong alumni network and elite facilities.',
   'Possession-based double pivot. Looking for technical midfielders, creative #10, and a target striker.'),

  -- MN — University of Minnesota
  (coach53,cuid53,'University of Minnesota','D1','MN','4-3-3','male',ARRAY['balanced','counter_attack'],ARRAY['2026','2027','2028'],2.7,true,
   'Minnesota Men''s Soccer — Big Ten Conference in Minneapolis. Strong Midwest recruiting with growing soccer culture in the region.',
   'Balanced 4-3-3 with counter-attacking principles. Need versatile players who can adapt to various systems.'),

  -- MS — Mississippi State University
  (coach54,cuid54,'Mississippi State University','D1','MS','4-4-2','male',ARRAY['direct','high_press'],ARRAY['2026','2027','2028'],2.5,true,
   'Mississippi State Men''s Soccer — SEC program in Starkville. Physical, direct style with strong Southeast recruiting.',
   'Direct two-striker system. Athletic players with strong aerial ability preferred. Scholarship opportunities available.'),

  -- MT — Montana State University
  (coach55,cuid55,'Montana State University','D1','MT','4-3-3','male',ARRAY['direct','balanced'],ARRAY['2026','2027','2028'],2.4,true,
   'Montana State Men''s Soccer — Big Sky Conference in Bozeman. Unique Mountain West location with outdoor culture and close-knit team environment.',
   'Straightforward 4-3-3 with work-rate emphasis. Looking for fit, coachable players. Aid packages available.'),

  -- NE — Creighton University
  (coach56,cuid56,'Creighton University','D1','NE','4-3-3','male',ARRAY['possession','technical'],ARRAY['2026','2027'],2.8,true,
   'Creighton Men''s Soccer — Big East powerhouse in Omaha. Consistently Top 5 nationally. Elite academic and soccer culture.',
   'Technical possession football. Extremely competitive roster. Seeking elite-level players with strong academics.'),

  -- NV — University of Nevada Las Vegas
  (coach57,cuid57,'University of Nevada Las Vegas','D1','NV','4-2-3-1','male',ARRAY['counter_attack','direct'],ARRAY['2026','2027','2028'],2.4,true,
   'UNLV Men''s Soccer — Mountain West Conference in Las Vegas. Sun Belt location with warm-weather training year-round.',
   'Counter-attacking double pivot. Need athletic, quick players who can exploit space on transitions. Aid available.'),

  -- NH — University of New Hampshire
  (coach58,cuid58,'University of New Hampshire','D1','NH','4-3-3','male',ARRAY['possession','build_from_back'],ARRAY['2026','2027','2028'],2.6,true,
   'UNH Men''s Soccer — America East Conference. New England program with strong academic culture and growing soccer tradition.',
   'Build-from-back 4-3-3. Need composed defenders, a distributing goalkeeper, and creative wide forwards.'),

  -- NJ — Seton Hall University
  (coach59,cuid59,'Seton Hall University','D1','NJ','4-2-3-1','male',ARRAY['possession','technical'],ARRAY['2026','2027'],2.9,true,
   'Seton Hall Men''s Soccer — Big East Conference near New York City. Strong metro recruiting base and professional pathway.',
   'Technical possession system. Proximity to NYC creates excellent exposure. Need technically gifted players.'),

  -- ND — North Dakota State University
  (coach60,cuid60,'North Dakota State University','D1','ND','4-4-2','male',ARRAY['direct','balanced'],ARRAY['2026','2027','2028'],2.4,true,
   'NDSU Men''s Soccer — Summit League in Fargo. Competitive D1 with strong academic culture and Midwest work ethic.',
   'Direct 4-4-2. Physical, hard-working players preferred. Good financial aid packages for student-athletes.'),

  -- OH — Ohio State University
  (coach61,cuid61,'Ohio State University','D1','OH','4-3-3','male',ARRAY['possession','high_press'],ARRAY['2026','2027'],2.8,true,
   'Ohio State Men''s Soccer — Big Ten Conference. One of the most recognized universities in the country with growing soccer program.',
   'Possession-based 4-3-3 with high press. Seeking technical, tactically intelligent players. Elite Big Ten competition.'),

  -- RI — Providence College
  (coach62,cuid62,'Providence College','D1','RI','4-2-3-1','male',ARRAY['possession','technical'],ARRAY['2026','2027','2028'],3.0,true,
   'Providence Men''s Soccer — Big East Conference. Small Catholic university with an elite soccer tradition and strong academic culture.',
   'Technical double pivot system. High GPA required. Looking for smart, technically gifted players who fit our culture.'),

  -- SD — South Dakota State University
  (coach63,cuid63,'South Dakota State University','D1','SD','4-3-3','male',ARRAY['balanced','direct'],ARRAY['2026','2027','2028'],2.3,true,
   'SDSU Men''s Soccer — Summit League in Brookings. Competitive D1 with generous scholarship packages and strong Plains recruiting.',
   'Balanced 4-3-3. Athletic players with versatility preferred. Full scholarship potential for quality recruits.'),

  -- TN — Vanderbilt University
  (coach64,cuid64,'Vanderbilt University','D1','TN','4-2-3-1','male',ARRAY['possession','build_from_back'],ARRAY['2026','2027'],3.2,true,
   'Vanderbilt Men''s Soccer — SEC Conference. Elite academic institution with a strong commitment to developing total student-athletes.',
   'Possession-based system. Very high academic standards. Seeking players who excel in the classroom and on the field.'),

  -- WI — University of Wisconsin
  (coach65,cuid65,'University of Wisconsin','D1','WI','4-3-3','male',ARRAY['possession','high_press'],ARRAY['2026','2027','2028'],2.8,true,
   'Wisconsin Men''s Soccer — Big Ten Conference in Madison. Passionate soccer culture with excellent facilities and Midwest recruiting.',
   'High-pressing 4-3-3. Need tenacious wide players and a press-resistant midfield. Strong Big Ten environment.'),

  -- WY — University of Wyoming
  (coach66,cuid66,'University of Wyoming','D2','WY','4-4-2','male',ARRAY['direct','balanced'],ARRAY['2026','2027','2028'],2.3,true,
   'Wyoming Men''s Soccer — Mountain West D2 program in Laramie. High-altitude training (7,200 ft) builds elite fitness levels.',
   'Direct 4-4-2 at altitude. Athletic, physically fit players who can handle the elevation. Full scholarships available.')

ON CONFLICT (id) DO NOTHING;

-- ─── Position Requirements (one INSERT per coach for readability) ─────────────

INSERT INTO coach_position_requirements (coach_id, position_key, required_qualities, is_published) VALUES
  -- AL — Alabama 4-3-3
  (coach42,'lw',ARRAY['pace','dribbling','crossing','work_rate'],true),
  (coach42,'rw',ARRAY['pace','crossing','work_rate','pressing'],true),
  (coach42,'st',ARRAY['finishing','pressing','movement','pace'],true),
  (coach42,'cm',ARRAY['passing_range','box_to_box','press_resistance','work_rate'],true),
  (coach42,'cdm',ARRAY['defensive_awareness','positioning','distribution','passing'],true),
  (coach42,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach42,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- AK — UAA 4-4-2
  (coach43,'st',ARRAY['finishing','aerial_ability','hold_up_play','work_rate'],true),
  (coach43,'cf',ARRAY['pace','finishing','movement','pressing'],true),
  (coach43,'rm',ARRAY['pace','crossing','work_rate','stamina'],true),
  (coach43,'lm',ARRAY['pace','dribbling','crossing','work_rate'],true),
  (coach43,'cm',ARRAY['passing','box_to_box','defensive_awareness','stamina'],true),
  (coach43,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach43,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true),
  -- DE — Delaware 4-2-3-1
  (coach44,'st',ARRAY['finishing','movement','hold_up_play','work_rate'],true),
  (coach44,'cam',ARRAY['creativity','vision','passing_range','dribbling'],true),
  (coach44,'ram',ARRAY['pace','crossing','work_rate','dribbling'],true),
  (coach44,'lam',ARRAY['pace','dribbling','1v1','crossing'],true),
  (coach44,'cdm',ARRAY['defensive_awareness','passing','positioning','interceptions'],true),
  (coach44,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach44,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- GA — Georgia Southern 4-3-3
  (coach45,'lw',ARRAY['pace','pressing','dribbling','1v1'],true),
  (coach45,'rw',ARRAY['pace','pressing','crossing','work_rate'],true),
  (coach45,'st',ARRAY['pressing','pace','finishing','movement'],true),
  (coach45,'cm',ARRAY['work_rate','pressing','passing','box_to_box'],true),
  (coach45,'cdm',ARRAY['defensive_awareness','positioning','passing','interceptions'],true),
  (coach45,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach45,'gk',ARRAY['shot_stopping','distribution','reflexes'],true),
  -- HI — Hawaii 4-3-3
  (coach46,'lw',ARRAY['technical_ability','dribbling','pace','crossing'],true),
  (coach46,'rw',ARRAY['technical_ability','crossing','pace','work_rate'],true),
  (coach46,'st',ARRAY['finishing','movement','technical_ability','pressing'],true),
  (coach46,'cm',ARRAY['passing_range','vision','press_resistance','box_to_box'],true),
  (coach46,'cdm',ARRAY['defensive_awareness','distribution','positioning','composure'],true),
  (coach46,'cb',ARRAY['reading_game','passing','aerial_ability','composure'],true),
  (coach46,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- ID — Boise State 4-2-3-1
  (coach47,'st',ARRAY['finishing','pace','movement','work_rate'],true),
  (coach47,'cam',ARRAY['creativity','vision','passing_range','dribbling'],true),
  (coach47,'ram',ARRAY['pace','crossing','work_rate','pressing'],true),
  (coach47,'lam',ARRAY['pace','dribbling','1v1','work_rate'],true),
  (coach47,'cdm',ARRAY['defensive_awareness','positioning','distribution','passing'],true),
  (coach47,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach47,'gk',ARRAY['shot_stopping','reflexes','distribution'],true),
  -- KS — Kansas 4-3-3
  (coach48,'lw',ARRAY['pace','dribbling','crossing','technical_ability'],true),
  (coach48,'rw',ARRAY['pace','crossing','technical_ability','work_rate'],true),
  (coach48,'st',ARRAY['finishing','movement','hold_up_play','pressing'],true),
  (coach48,'cm',ARRAY['passing_range','vision','press_resistance','box_to_box'],true),
  (coach48,'cdm',ARRAY['defensive_awareness','distribution','positioning','passing'],true),
  (coach48,'cb',ARRAY['aerial_ability','composure','passing','positioning'],true),
  (coach48,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true),
  -- LA — Tulane 4-2-3-1
  (coach49,'st',ARRAY['finishing','hold_up_play','movement','pressing'],true),
  (coach49,'cam',ARRAY['creativity','vision','passing_range','technical_ability'],true),
  (coach49,'ram',ARRAY['pace','crossing','work_rate','pressing'],true),
  (coach49,'lam',ARRAY['pace','dribbling','1v1','technical_ability'],true),
  (coach49,'cdm',ARRAY['defensive_awareness','distribution','positioning','passing'],true),
  (coach49,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach49,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- ME — Maine 4-4-2
  (coach50,'st',ARRAY['finishing','aerial_ability','hold_up_play','work_rate'],true),
  (coach50,'cf',ARRAY['pace','movement','finishing','pressing'],true),
  (coach50,'rm',ARRAY['pace','crossing','work_rate','stamina'],true),
  (coach50,'lm',ARRAY['pace','dribbling','crossing','work_rate'],true),
  (coach50,'cm',ARRAY['passing','box_to_box','defensive_awareness','work_rate'],true),
  (coach50,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach50,'gk',ARRAY['shot_stopping','reflexes','command_of_area'],true),
  -- MD — Maryland 4-3-3
  (coach51,'lw',ARRAY['pace','dribbling','1v1','technical_ability'],true),
  (coach51,'rw',ARRAY['pace','crossing','technical_ability','work_rate'],true),
  (coach51,'st',ARRAY['finishing','pressing','movement','technical_ability'],true),
  (coach51,'cm',ARRAY['passing_range','vision','press_resistance','box_to_box'],true),
  (coach51,'cdm',ARRAY['defensive_awareness','distribution','positioning','composure'],true),
  (coach51,'cb',ARRAY['reading_game','aerial_ability','composure','passing'],true),
  (coach51,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- MI — Michigan State 4-2-3-1
  (coach52,'st',ARRAY['finishing','hold_up_play','movement','pressing'],true),
  (coach52,'cam',ARRAY['creativity','vision','passing_range','dribbling'],true),
  (coach52,'ram',ARRAY['pace','crossing','work_rate','technical_ability'],true),
  (coach52,'lam',ARRAY['pace','dribbling','technical_ability','crossing'],true),
  (coach52,'cdm',ARRAY['defensive_awareness','distribution','positioning','passing'],true),
  (coach52,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach52,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- MN — Minnesota 4-3-3
  (coach53,'lw',ARRAY['pace','dribbling','crossing','work_rate'],true),
  (coach53,'rw',ARRAY['pace','crossing','work_rate','pressing'],true),
  (coach53,'st',ARRAY['finishing','movement','pace','work_rate'],true),
  (coach53,'cm',ARRAY['box_to_box','passing','defensive_awareness','stamina'],true),
  (coach53,'cdm',ARRAY['defensive_awareness','positioning','distribution','passing'],true),
  (coach53,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach53,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true),
  -- MS — Mississippi State 4-4-2
  (coach54,'st',ARRAY['finishing','aerial_ability','hold_up_play','pace'],true),
  (coach54,'cf',ARRAY['pace','pressing','movement','finishing'],true),
  (coach54,'rm',ARRAY['pace','crossing','work_rate','stamina'],true),
  (coach54,'lm',ARRAY['pace','dribbling','crossing','pressing'],true),
  (coach54,'cm',ARRAY['box_to_box','defensive_awareness','passing','work_rate'],true),
  (coach54,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach54,'gk',ARRAY['shot_stopping','command_of_area','reflexes'],true),
  -- MT — Montana State 4-3-3
  (coach55,'lw',ARRAY['pace','work_rate','dribbling','crossing'],true),
  (coach55,'rw',ARRAY['pace','work_rate','crossing','pressing'],true),
  (coach55,'st',ARRAY['finishing','work_rate','movement','pressing'],true),
  (coach55,'cm',ARRAY['box_to_box','work_rate','passing','stamina'],true),
  (coach55,'cdm',ARRAY['defensive_awareness','positioning','passing','work_rate'],true),
  (coach55,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach55,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true),
  -- NE — Creighton 4-3-3
  (coach56,'lw',ARRAY['technical_ability','pace','dribbling','1v1'],true),
  (coach56,'rw',ARRAY['technical_ability','pace','crossing','work_rate'],true),
  (coach56,'st',ARRAY['finishing','movement','technical_ability','pressing'],true),
  (coach56,'cm',ARRAY['passing_range','vision','press_resistance','technical_ability'],true),
  (coach56,'cdm',ARRAY['defensive_awareness','distribution','positioning','composure'],true),
  (coach56,'cb',ARRAY['reading_game','aerial_ability','passing','composure'],true),
  (coach56,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- NV — UNLV 4-2-3-1
  (coach57,'st',ARRAY['finishing','pace','movement','work_rate'],true),
  (coach57,'cam',ARRAY['creativity','vision','dribbling','passing_range'],true),
  (coach57,'ram',ARRAY['pace','crossing','work_rate','pressing'],true),
  (coach57,'lam',ARRAY['pace','dribbling','1v1','work_rate'],true),
  (coach57,'cdm',ARRAY['defensive_awareness','positioning','passing','interceptions'],true),
  (coach57,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach57,'gk',ARRAY['shot_stopping','reflexes','distribution'],true),
  -- NH — UNH 4-3-3
  (coach58,'lw',ARRAY['pace','dribbling','crossing','technical_ability'],true),
  (coach58,'rw',ARRAY['pace','crossing','technical_ability','work_rate'],true),
  (coach58,'st',ARRAY['finishing','movement','hold_up_play','pressing'],true),
  (coach58,'cm',ARRAY['passing_range','vision','box_to_box','press_resistance'],true),
  (coach58,'cdm',ARRAY['defensive_awareness','distribution','positioning','passing'],true),
  (coach58,'cb',ARRAY['aerial_ability','composure','passing','positioning'],true),
  (coach58,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- NJ — Seton Hall 4-2-3-1
  (coach59,'st',ARRAY['finishing','movement','technical_ability','pressing'],true),
  (coach59,'cam',ARRAY['creativity','vision','passing_range','technical_ability'],true),
  (coach59,'ram',ARRAY['pace','crossing','technical_ability','work_rate'],true),
  (coach59,'lam',ARRAY['pace','dribbling','technical_ability','1v1'],true),
  (coach59,'cdm',ARRAY['defensive_awareness','distribution','positioning','passing'],true),
  (coach59,'cb',ARRAY['reading_game','aerial_ability','composure','passing'],true),
  (coach59,'gk',ARRAY['shot_stopping','distribution','reflexes'],true),
  -- ND — NDSU 4-4-2
  (coach60,'st',ARRAY['finishing','aerial_ability','hold_up_play','work_rate'],true),
  (coach60,'cf',ARRAY['pace','movement','finishing','pressing'],true),
  (coach60,'rm',ARRAY['pace','crossing','stamina','work_rate'],true),
  (coach60,'lm',ARRAY['pace','dribbling','work_rate','stamina'],true),
  (coach60,'cm',ARRAY['box_to_box','passing','defensive_awareness','work_rate'],true),
  (coach60,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach60,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true),
  -- OH — Ohio State 4-3-3
  (coach61,'lw',ARRAY['pace','dribbling','crossing','pressing'],true),
  (coach61,'rw',ARRAY['pace','crossing','pressing','work_rate'],true),
  (coach61,'st',ARRAY['finishing','pressing','movement','technical_ability'],true),
  (coach61,'cm',ARRAY['passing_range','press_resistance','vision','box_to_box'],true),
  (coach61,'cdm',ARRAY['defensive_awareness','positioning','distribution','composure'],true),
  (coach61,'cb',ARRAY['aerial_ability','positioning','composure','passing'],true),
  (coach61,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- RI — Providence 4-2-3-1
  (coach62,'st',ARRAY['finishing','movement','technical_ability','pressing'],true),
  (coach62,'cam',ARRAY['creativity','vision','passing_range','technical_ability'],true),
  (coach62,'ram',ARRAY['pace','crossing','technical_ability','work_rate'],true),
  (coach62,'lam',ARRAY['pace','dribbling','technical_ability','crossing'],true),
  (coach62,'cdm',ARRAY['defensive_awareness','distribution','positioning','composure'],true),
  (coach62,'cb',ARRAY['reading_game','aerial_ability','passing','composure'],true),
  (coach62,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- SD — SDSU 4-3-3
  (coach63,'lw',ARRAY['pace','dribbling','crossing','work_rate'],true),
  (coach63,'rw',ARRAY['pace','crossing','work_rate','pressing'],true),
  (coach63,'st',ARRAY['finishing','movement','pace','work_rate'],true),
  (coach63,'cm',ARRAY['box_to_box','passing','defensive_awareness','stamina'],true),
  (coach63,'cdm',ARRAY['defensive_awareness','positioning','passing','distribution'],true),
  (coach63,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach63,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true),
  -- TN — Vanderbilt 4-2-3-1
  (coach64,'st',ARRAY['finishing','hold_up_play','movement','technical_ability'],true),
  (coach64,'cam',ARRAY['creativity','vision','passing_range','technical_ability'],true),
  (coach64,'ram',ARRAY['pace','crossing','technical_ability','work_rate'],true),
  (coach64,'lam',ARRAY['pace','dribbling','technical_ability','1v1'],true),
  (coach64,'cdm',ARRAY['defensive_awareness','distribution','positioning','composure'],true),
  (coach64,'cb',ARRAY['reading_game','aerial_ability','passing','composure'],true),
  (coach64,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- WI — Wisconsin 4-3-3
  (coach65,'lw',ARRAY['pace','dribbling','pressing','1v1'],true),
  (coach65,'rw',ARRAY['pace','crossing','pressing','work_rate'],true),
  (coach65,'st',ARRAY['finishing','pressing','movement','pace'],true),
  (coach65,'cm',ARRAY['passing_range','press_resistance','box_to_box','vision'],true),
  (coach65,'cdm',ARRAY['defensive_awareness','positioning','distribution','passing'],true),
  (coach65,'cb',ARRAY['aerial_ability','positioning','composure','leadership'],true),
  (coach65,'gk',ARRAY['shot_stopping','distribution','command_of_area'],true),
  -- WY — Wyoming 4-4-2
  (coach66,'st',ARRAY['finishing','aerial_ability','hold_up_play','stamina'],true),
  (coach66,'cf',ARRAY['pace','finishing','movement','stamina'],true),
  (coach66,'rm',ARRAY['pace','crossing','work_rate','stamina'],true),
  (coach66,'lm',ARRAY['pace','dribbling','crossing','stamina'],true),
  (coach66,'cm',ARRAY['box_to_box','passing','defensive_awareness','stamina'],true),
  (coach66,'cb',ARRAY['aerial_ability','positioning','leadership','composure'],true),
  (coach66,'gk',ARRAY['shot_stopping','command_of_area','distribution'],true)
ON CONFLICT DO NOTHING;

-- ─── Roster Slots ─────────────────────────────────────────────────────────────
INSERT INTO roster_slots (coach_id, position_key, depth_order, slot_status, graduation_year) VALUES
  -- AL Alabama
  (coach42,'lw',1,'open',2027),(coach42,'rw',1,'graduating',2026),(coach42,'rw',2,'open',2027),
  (coach42,'st',1,'open',2026),(coach42,'cm',1,'open',2027),(coach42,'cdm',1,'open',2027),
  (coach42,'cb',1,'open',2028),(coach42,'gk',1,'graduating',2026),
  -- AK UAA
  (coach43,'st',1,'open',2027),(coach43,'cf',1,'graduating',2026),(coach43,'rm',1,'open',2027),
  (coach43,'lm',1,'open',2026),(coach43,'cm',1,'open',2028),(coach43,'cb',1,'open',2027),
  -- DE Delaware
  (coach44,'st',1,'open',2027),(coach44,'cam',1,'graduating',2026),(coach44,'cam',2,'open',2027),
  (coach44,'ram',1,'open',2026),(coach44,'lam',1,'open',2027),(coach44,'cb',1,'open',2028),
  -- GA Georgia Southern
  (coach45,'lw',1,'open',2026),(coach45,'rw',1,'open',2027),(coach45,'st',1,'graduating',2026),
  (coach45,'st',2,'open',2027),(coach45,'cm',1,'open',2027),(coach45,'cb',1,'open',2028),
  -- HI Hawaii
  (coach46,'lw',1,'open',2027),(coach46,'rw',1,'graduating',2026),(coach46,'rw',2,'open',2028),
  (coach46,'st',1,'open',2027),(coach46,'cm',1,'open',2026),(coach46,'gk',1,'open',2027),
  -- ID Boise State
  (coach47,'st',1,'open',2027),(coach47,'cam',1,'open',2026),(coach47,'ram',1,'open',2027),
  (coach47,'lam',1,'graduating',2026),(coach47,'lam',2,'open',2027),(coach47,'cb',1,'open',2028),
  -- KS Kansas
  (coach48,'lw',1,'open',2027),(coach48,'rw',1,'graduating',2026),(coach48,'rw',2,'open',2027),
  (coach48,'st',1,'open',2026),(coach48,'cm',1,'open',2028),(coach48,'cdm',1,'open',2027),
  -- LA Tulane
  (coach49,'st',1,'open',2027),(coach49,'cam',1,'open',2026),(coach49,'ram',1,'graduating',2026),
  (coach49,'ram',2,'open',2027),(coach49,'lam',1,'open',2027),(coach49,'cb',1,'open',2028),
  -- ME Maine
  (coach50,'st',1,'graduating',2026),(coach50,'st',2,'open',2027),(coach50,'rm',1,'open',2026),
  (coach50,'lm',1,'open',2027),(coach50,'cm',1,'open',2028),(coach50,'gk',1,'open',2026),
  -- MD Maryland
  (coach51,'lw',1,'open',2027),(coach51,'rw',1,'open',2026),(coach51,'st',1,'graduating',2026),
  (coach51,'st',2,'open',2027),(coach51,'cm',1,'filled',2027),(coach51,'cm',2,'open',2028),
  (coach51,'cdm',1,'open',2027),(coach51,'gk',1,'open',2026),
  -- MI Michigan State
  (coach52,'st',1,'open',2027),(coach52,'cam',1,'graduating',2026),(coach52,'cam',2,'open',2027),
  (coach52,'ram',1,'open',2026),(coach52,'lam',1,'open',2027),(coach52,'cb',1,'open',2028),
  -- MN Minnesota
  (coach53,'lw',1,'open',2027),(coach53,'rw',1,'open',2026),(coach53,'st',1,'open',2027),
  (coach53,'cm',1,'graduating',2026),(coach53,'cm',2,'open',2027),(coach53,'cdm',1,'open',2028),
  -- MS Mississippi State
  (coach54,'st',1,'graduating',2026),(coach54,'st',2,'open',2027),(coach54,'rm',1,'open',2026),
  (coach54,'lm',1,'open',2027),(coach54,'cm',1,'open',2028),(coach54,'cb',1,'open',2027),
  -- MT Montana State
  (coach55,'lw',1,'open',2026),(coach55,'rw',1,'open',2027),(coach55,'st',1,'graduating',2026),
  (coach55,'st',2,'open',2027),(coach55,'cm',1,'open',2028),(coach55,'gk',1,'open',2026),
  -- NE Creighton
  (coach56,'lw',1,'open',2027),(coach56,'rw',1,'graduating',2026),(coach56,'rw',2,'open',2028),
  (coach56,'st',1,'open',2027),(coach56,'cm',1,'filled',2026),(coach56,'cm',2,'open',2027),
  (coach56,'gk',1,'open',2026),
  -- NV UNLV
  (coach57,'st',1,'open',2027),(coach57,'cam',1,'open',2026),(coach57,'ram',1,'graduating',2026),
  (coach57,'ram',2,'open',2027),(coach57,'lam',1,'open',2027),(coach57,'cb',1,'open',2028),
  -- NH UNH
  (coach58,'lw',1,'open',2027),(coach58,'rw',1,'open',2026),(coach58,'st',1,'open',2027),
  (coach58,'cm',1,'graduating',2026),(coach58,'cm',2,'open',2027),(coach58,'cdm',1,'open',2028),
  -- NJ Seton Hall
  (coach59,'st',1,'open',2027),(coach59,'cam',1,'graduating',2026),(coach59,'cam',2,'open',2027),
  (coach59,'ram',1,'open',2026),(coach59,'lam',1,'open',2028),(coach59,'cb',1,'open',2027),
  -- ND NDSU
  (coach60,'st',1,'graduating',2026),(coach60,'st',2,'open',2027),(coach60,'rm',1,'open',2026),
  (coach60,'lm',1,'open',2027),(coach60,'cm',1,'open',2028),(coach60,'gk',1,'open',2026),
  -- OH Ohio State
  (coach61,'lw',1,'open',2027),(coach61,'rw',1,'graduating',2026),(coach61,'rw',2,'open',2027),
  (coach61,'st',1,'open',2026),(coach61,'cm',1,'filled',2027),(coach61,'cm',2,'open',2027),
  (coach61,'cdm',1,'open',2028),(coach61,'gk',1,'open',2026),
  -- RI Providence
  (coach62,'st',1,'open',2028),(coach62,'cam',1,'graduating',2026),(coach62,'cam',2,'open',2027),
  (coach62,'ram',1,'open',2027),(coach62,'lam',1,'open',2026),(coach62,'cb',1,'open',2027),
  -- SD SDSU
  (coach63,'lw',1,'open',2026),(coach63,'rw',1,'open',2027),(coach63,'st',1,'graduating',2026),
  (coach63,'st',2,'open',2027),(coach63,'cm',1,'open',2028),(coach63,'gk',1,'open',2026),
  -- TN Vanderbilt
  (coach64,'st',1,'open',2027),(coach64,'cam',1,'open',2026),(coach64,'ram',1,'graduating',2026),
  (coach64,'ram',2,'open',2027),(coach64,'lam',1,'open',2028),(coach64,'cb',1,'open',2027),
  -- WI Wisconsin
  (coach65,'lw',1,'open',2027),(coach65,'rw',1,'graduating',2026),(coach65,'rw',2,'open',2027),
  (coach65,'st',1,'open',2026),(coach65,'cm',1,'open',2028),(coach65,'cdm',1,'open',2027),
  (coach65,'cb',1,'open',2027),(coach65,'gk',1,'graduating',2026),
  -- WY Wyoming
  (coach66,'st',1,'graduating',2026),(coach66,'st',2,'open',2027),(coach66,'rm',1,'open',2026),
  (coach66,'lm',1,'open',2027),(coach66,'cm',1,'open',2028),(coach66,'gk',1,'open',2026)
ON CONFLICT DO NOTHING;

END $$;

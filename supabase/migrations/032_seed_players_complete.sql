SET search_path TO public, extensions;

-- ─────────────────────────────────────────────────────────────────────────────
-- 032_seed_players_complete.sql
-- • Seeds 13 soccer positions + 30 colleges
-- • Adds missing ECNL Boys / NPL clubs to league_clubs
-- • Fills missing data for existing 12 players (positions, videos, schedule,
--   target schools, club affiliations, SAT/ACT/major/DOB)
-- • Adds 25 new players with complete profiles
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Positions ──────────────────────────────────────────────────────────────

INSERT INTO positions (id, sport_id, name, name_es, abbreviation, position_type) VALUES
  ('40000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','Goalkeeper',           'Portero',                 'GK',  'goalkeeper'),
  ('40000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','Right Back',           'Lateral Derecho',         'RB',  'defender'),
  ('40000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','Center Back',          'Defensa Central',         'CB',  'defender'),
  ('40000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','Left Back',            'Lateral Izquierdo',       'LB',  'defender'),
  ('40000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000001','Defensive Midfielder', 'Mediocampista Defensivo',  'CDM', 'midfielder'),
  ('40000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000001','Central Midfielder',   'Mediocampista Central',   'CM',  'midfielder'),
  ('40000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000001','Attacking Midfielder', 'Mediocampista Ofensivo',   'CAM', 'midfielder'),
  ('40000000-0000-0000-0000-000000000008','00000000-0000-0000-0000-000000000001','Right Midfielder',     'Mediocampista Derecho',   'RM',  'midfielder'),
  ('40000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000001','Left Midfielder',      'Mediocampista Izquierdo',  'LM',  'midfielder'),
  ('40000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000001','Right Winger',         'Extremo Derecho',         'RW',  'forward'),
  ('40000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','Left Winger',          'Extremo Izquierdo',       'LW',  'forward'),
  ('40000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000001','Striker',              'Delantero Centro',        'ST',  'forward'),
  ('40000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000001','Center Forward',       'Centro Delantero',        'CF',  'forward')
ON CONFLICT (id) DO NOTHING;

-- ── 2. Colleges (30 programs: D1 × 18, D2 × 6, D3 × 4, NAIA × 2) ────────────

INSERT INTO colleges (id, name, city, state, division_id, acceptance_rate, avg_sat, total_enrollment, campus_type, website_url) VALUES
  -- D1
  ('50000000-0000-0000-0000-000000000001','Penn State',              'State College',   'PA','30000000-0000-0000-0000-000000000001',0.54,1210,47000,'suburban','https://gopsu.com'),
  ('50000000-0000-0000-0000-000000000002','Duke University',         'Durham',          'NC','30000000-0000-0000-0000-000000000001',0.08,1500,17000,'suburban','https://goduke.com'),
  ('50000000-0000-0000-0000-000000000003','Stanford University',     'Stanford',        'CA','30000000-0000-0000-0000-000000000001',0.04,1520,17000,'suburban','https://gostanford.com'),
  ('50000000-0000-0000-0000-000000000004','UCLA',                    'Los Angeles',     'CA','30000000-0000-0000-0000-000000000001',0.11,1380,46000,'urban',   'https://uclabruins.com'),
  ('50000000-0000-0000-0000-000000000005','Wake Forest University',  'Winston-Salem',   'NC','30000000-0000-0000-0000-000000000001',0.28,1390,8000, 'suburban','https://godeacs.com'),
  ('50000000-0000-0000-0000-000000000006','Georgetown University',   'Washington',      'DC','30000000-0000-0000-0000-000000000001',0.15,1430,20000,'urban',   'https://guhoyas.com'),
  ('50000000-0000-0000-0000-000000000007','Indiana University',      'Bloomington',     'IN','30000000-0000-0000-0000-000000000001',0.80,1210,47000,'suburban','https://iuhoosiers.com'),
  ('50000000-0000-0000-0000-000000000008','University of Virginia',  'Charlottesville', 'VA','30000000-0000-0000-0000-000000000001',0.23,1390,25000,'suburban','https://virginiasports.com'),
  ('50000000-0000-0000-0000-000000000009','Notre Dame',              'South Bend',      'IN','30000000-0000-0000-0000-000000000001',0.13,1480,12000,'suburban','https://und.com'),
  ('50000000-0000-0000-0000-000000000010','University of Maryland',  'College Park',    'MD','30000000-0000-0000-0000-000000000001',0.44,1310,40000,'suburban','https://umterps.com'),
  ('50000000-0000-0000-0000-000000000011','Syracuse University',     'Syracuse',        'NY','30000000-0000-0000-0000-000000000001',0.62,1200,23000,'urban',   'https://cuse.com'),
  ('50000000-0000-0000-0000-000000000012','Creighton University',    'Omaha',           'NE','30000000-0000-0000-0000-000000000001',0.70,1240,9000, 'urban',   'https://gocreighton.com'),
  ('50000000-0000-0000-0000-000000000013','Providence College',      'Providence',      'RI','30000000-0000-0000-0000-000000000001',0.60,1180,4500, 'suburban','https://friars.com'),
  ('50000000-0000-0000-0000-000000000014','Gonzaga University',      'Spokane',         'WA','30000000-0000-0000-0000-000000000001',0.68,1270,9000, 'suburban','https://gozags.com'),
  ('50000000-0000-0000-0000-000000000015','University of Portland',  'Portland',        'OR','30000000-0000-0000-0000-000000000001',0.80,1180,4200, 'urban',   'https://portlandpilots.com'),
  ('50000000-0000-0000-0000-000000000016','UNC Chapel Hill',         'Chapel Hill',     'NC','30000000-0000-0000-0000-000000000001',0.18,1380,32000,'suburban','https://goheels.com'),
  ('50000000-0000-0000-0000-000000000017','NC State University',     'Raleigh',         'NC','30000000-0000-0000-0000-000000000001',0.47,1250,37000,'suburban','https://gopack.com'),
  ('50000000-0000-0000-0000-000000000018','Boston College',          'Chestnut Hill',   'MA','30000000-0000-0000-0000-000000000001',0.19,1420,14500,'suburban','https://bceagles.com'),
  -- D2
  ('50000000-0000-0000-0000-000000000019','University of Tampa',     'Tampa',           'FL','30000000-0000-0000-0000-000000000002',0.74,1080,11000,'urban',   'https://ut.edu/athletics'),
  ('50000000-0000-0000-0000-000000000020','Lynn University',         'Boca Raton',      'FL','30000000-0000-0000-0000-000000000002',0.80,1020,3500, 'suburban','https://lynnfighting.com'),
  ('50000000-0000-0000-0000-000000000021','Colorado School of Mines','Golden',          'CO','30000000-0000-0000-0000-000000000002',0.47,1380,7500, 'suburban','https://minesathletics.com'),
  ('50000000-0000-0000-0000-000000000022','Grand Canyon University', 'Phoenix',         'AZ','30000000-0000-0000-0000-000000000002',0.78,1100,25000,'urban',   'https://gcuathletics.com'),
  ('50000000-0000-0000-0000-000000000023','Adelphi University',      'Garden City',     'NY','30000000-0000-0000-0000-000000000002',0.72,1110,8000, 'suburban','https://athletics.adelphi.edu'),
  ('50000000-0000-0000-0000-000000000024','Florida Tech',            'Melbourne',       'FL','30000000-0000-0000-0000-000000000002',0.60,1180,7000, 'suburban','https://floridatechsports.com'),
  -- D3
  ('50000000-0000-0000-0000-000000000025','Trinity College',         'Hartford',        'CT','30000000-0000-0000-0000-000000000003',0.32,1350,2300, 'urban',   'https://bantams.com'),
  ('50000000-0000-0000-0000-000000000026','Williams College',        'Williamstown',    'MA','30000000-0000-0000-0000-000000000003',0.09,1490,2200, 'rural',   'https://ephsports.com'),
  ('50000000-0000-0000-0000-000000000027','Pomona-Pitzer',           'Claremont',       'CA','30000000-0000-0000-0000-000000000003',0.09,1500,1800, 'suburban','https://sagehens.com'),
  ('50000000-0000-0000-0000-000000000028','Middlebury College',      'Middlebury',      'VT','30000000-0000-0000-0000-000000000003',0.14,1430,2800, 'rural',   'https://athletics.middlebury.edu'),
  -- NAIA
  ('50000000-0000-0000-0000-000000000029','Benedictine University',  'Lisle',           'IL','30000000-0000-0000-0000-000000000004',0.71,1020,3500, 'suburban','https://buathletics.com'),
  ('50000000-0000-0000-0000-000000000030','Lindsey Wilson College',  'Columbia',        'KY','30000000-0000-0000-0000-000000000004',0.72,980, 3200, 'rural',   'https://athletics.lindsey.edu')
ON CONFLICT (id) DO NOTHING;

-- ── 3. Missing league_clubs (ECNL Boys + NPL) ─────────────────────────────────

INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  ('ecnl', 'Ohio Premier',       'Columbus',  'OH', 'Midwest',   'male'),
  ('ecnl', 'Vardar SC',          'Wayne',     'PA', 'Northeast', 'male'),
  ('ecnl', 'Solar Soccer Club',  'Dallas',    'TX', 'South',     'male'),
  ('npl',  'Dallas Texans',      'Dallas',    'TX', 'South',     'male'),
  ('npl',  'Space Coast United', 'Melbourne', 'FL', 'South',     'male');

-- ── 4. Update existing 12 players: SAT / ACT / major / DOB ───────────────────

UPDATE players SET sat_score=1340, act_score=29, intended_major='Kinesiology',        date_of_birth='2008-04-12' FROM users WHERE players.user_id=users.id AND users.email='kieran.ross@lanista.test';
UPDATE players SET sat_score=1120, act_score=24, intended_major='Business',            date_of_birth='2008-09-03' FROM users WHERE players.user_id=users.id AND users.email='marcus.delgado@lanista.test';
UPDATE players SET sat_score=1280, act_score=28, intended_major='Sports Management',   date_of_birth='2009-06-21' FROM users WHERE players.user_id=users.id AND users.email='jaylen.brooks@lanista.test';
UPDATE players SET sat_score=1010, act_score=22, intended_major='Communications',      date_of_birth='2007-11-14' FROM users WHERE players.user_id=users.id AND users.email='santiago.vega@lanista.test';
UPDATE players SET sat_score=1420, act_score=32, intended_major='Computer Science',    date_of_birth='2008-02-28' FROM users WHERE players.user_id=users.id AND users.email='noah.chen@lanista.test';
UPDATE players SET sat_score=1150, act_score=25, intended_major='Business Administration', date_of_birth='2008-07-07' FROM users WHERE players.user_id=users.id AND users.email='elias.okonkwo@lanista.test';
UPDATE players SET sat_score=1260, act_score=27, intended_major='Engineering',         date_of_birth='2009-01-18' FROM users WHERE players.user_id=users.id AND users.email='luca.ferrari@lanista.test';
UPDATE players SET sat_score=1090, act_score=23, intended_major='Marketing',           date_of_birth='2007-08-25' FROM users WHERE players.user_id=users.id AND users.email='omar.hassan@lanista.test';
UPDATE players SET sat_score=1310, act_score=29, intended_major='Biology',             date_of_birth='2008-05-15' FROM users WHERE players.user_id=users.id AND users.email='lucy.kim@lanista.test';
UPDATE players SET sat_score=1170, act_score=25, intended_major='Psychology',          date_of_birth='2008-10-02' FROM users WHERE players.user_id=users.id AND users.email='sofia.ramirez@lanista.test';
UPDATE players SET sat_score=1240, act_score=26, intended_major='Pre-Medicine',        date_of_birth='2009-03-10' FROM users WHERE players.user_id=users.id AND users.email='maya.johnson@lanista.test';
UPDATE players SET sat_score=1130, act_score=24, intended_major='Communications',      date_of_birth='2007-12-05' FROM users WHERE players.user_id=users.id AND users.email='isabela.santos@lanista.test';

-- ── 5. Player Positions — existing 12 players ────────────────────────────────
-- (primary pos + 1 secondary)

INSERT INTO player_positions (player_id, position_id, is_primary, proficiency)
SELECT p.id, v.pos_id::uuid, v.is_primary, v.proficiency
FROM (VALUES
  -- Kieran Ross — ST primary, CF secondary
  ('kieran.ross@lanista.test',    '40000000-0000-0000-0000-000000000012', true,  9),
  ('kieran.ross@lanista.test',    '40000000-0000-0000-0000-000000000013', false, 7),
  -- Marcus Delgado — CM primary, CAM secondary
  ('marcus.delgado@lanista.test', '40000000-0000-0000-0000-000000000006', true,  8),
  ('marcus.delgado@lanista.test', '40000000-0000-0000-0000-000000000007', false, 7),
  -- Jaylen Brooks — CB primary, CDM secondary
  ('jaylen.brooks@lanista.test',  '40000000-0000-0000-0000-000000000003', true,  8),
  ('jaylen.brooks@lanista.test',  '40000000-0000-0000-0000-000000000005', false, 6),
  -- Santiago Vega — LW primary, RW secondary
  ('santiago.vega@lanista.test',  '40000000-0000-0000-0000-000000000011', true,  10),
  ('santiago.vega@lanista.test',  '40000000-0000-0000-0000-000000000010', false, 8),
  -- Noah Chen — GK (only)
  ('noah.chen@lanista.test',      '40000000-0000-0000-0000-000000000001', true,  9),
  -- Elias Okonkwo — RB primary, RM secondary
  ('elias.okonkwo@lanista.test',  '40000000-0000-0000-0000-000000000002', true,  8),
  ('elias.okonkwo@lanista.test',  '40000000-0000-0000-0000-000000000008', false, 6),
  -- Luca Ferrari — CDM primary, CM secondary
  ('luca.ferrari@lanista.test',   '40000000-0000-0000-0000-000000000005', true,  8),
  ('luca.ferrari@lanista.test',   '40000000-0000-0000-0000-000000000006', false, 7),
  -- Omar Hassan — ST primary, CF secondary
  ('omar.hassan@lanista.test',    '40000000-0000-0000-0000-000000000012', true,  7),
  ('omar.hassan@lanista.test',    '40000000-0000-0000-0000-000000000013', false, 6),
  -- Lucy Kim — CM primary, CAM secondary
  ('lucy.kim@lanista.test',       '40000000-0000-0000-0000-000000000006', true,  8),
  ('lucy.kim@lanista.test',       '40000000-0000-0000-0000-000000000007', false, 7),
  -- Sofía Ramírez — ST primary, LW secondary
  ('sofia.ramirez@lanista.test',  '40000000-0000-0000-0000-000000000012', true,  9),
  ('sofia.ramirez@lanista.test',  '40000000-0000-0000-0000-000000000011', false, 7),
  -- Maya Johnson — CB primary, LB secondary
  ('maya.johnson@lanista.test',   '40000000-0000-0000-0000-000000000003', true,  8),
  ('maya.johnson@lanista.test',   '40000000-0000-0000-0000-000000000004', false, 6),
  -- Isabela Santos — RM primary, RW secondary
  ('isabela.santos@lanista.test', '40000000-0000-0000-0000-000000000008', true,  8),
  ('isabela.santos@lanista.test', '40000000-0000-0000-0000-000000000010', false, 7)
) AS v(email, pos_id, is_primary, proficiency)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id
ON CONFLICT (player_id, position_id) DO NOTHING;

-- ── 6. Player Highlight Videos — existing 12 players ─────────────────────────

INSERT INTO player_videos (player_id, title, source, external_url, is_primary, analysis_status)
SELECT p.id, v.title, v.source, v.url, true, 'pending'
FROM (VALUES
  ('kieran.ross@lanista.test',    '2025-26 Highlights – Kieran Ross',    'hudl', 'https://www.hudl.com/video/3/14203812/kieran-ross-striker'),
  ('marcus.delgado@lanista.test', '2025-26 Highlights – Marcus Delgado', 'hudl', 'https://www.hudl.com/video/3/14203813/marcus-delgado-cm'),
  ('jaylen.brooks@lanista.test',  '2025-26 Highlights – Jaylen Brooks',  'hudl', 'https://www.hudl.com/video/3/14203814/jaylen-brooks-cb'),
  ('santiago.vega@lanista.test',  '2025-26 Highlights – Santiago Vega',  'hudl', 'https://www.hudl.com/video/3/14203815/santiago-vega-lw'),
  ('noah.chen@lanista.test',      '2025-26 Highlights – Noah Chen',      'hudl', 'https://www.hudl.com/video/3/14203816/noah-chen-gk'),
  ('elias.okonkwo@lanista.test',  '2025-26 Highlights – Elias Okonkwo',  'hudl', 'https://www.hudl.com/video/3/14203817/elias-okonkwo-rb'),
  ('luca.ferrari@lanista.test',   '2025-26 Highlights – Luca Ferrari',   'hudl', 'https://www.hudl.com/video/3/14203818/luca-ferrari-cdm'),
  ('omar.hassan@lanista.test',    '2025-26 Highlights – Omar Hassan',    'hudl', 'https://www.hudl.com/video/3/14203819/omar-hassan-st'),
  ('lucy.kim@lanista.test',       '2025-26 Highlights – Lucy Kim',       'hudl', 'https://www.hudl.com/video/3/14203820/lucy-kim-cm'),
  ('sofia.ramirez@lanista.test',  '2025-26 Highlights – Sofía Ramírez',  'hudl', 'https://www.hudl.com/video/3/14203821/sofia-ramirez-st'),
  ('maya.johnson@lanista.test',   '2025-26 Highlights – Maya Johnson',   'hudl', 'https://www.hudl.com/video/3/14203822/maya-johnson-cb'),
  ('isabela.santos@lanista.test', '2025-26 Highlights – Isabela Santos', 'hudl', 'https://www.hudl.com/video/3/14203823/isabela-santos-rm')
) AS v(email, title, source, url)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id;

-- ── 7. Player Schedule — existing 12 players ─────────────────────────────────

-- MLS Next players: Spring Showcase + home league game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'MLS Next Spring Showcase', '2026-03-21', 'Mesa, AZ', 'MLS Next', 'U18/U19 bracket'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('kieran.ross@lanista.test','marcus.delgado@lanista.test','santiago.vega@lanista.test','elias.okonkwo@lanista.test');

INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs FC Dallas Academy', '2026-03-08', 'Los Angeles, CA', 'MLS Next', 'Home — Stub Hub Center grass'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'kieran.ross@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs LA Galaxy Academy', '2026-03-08', 'Frisco, TX', 'MLS Next', 'Home — Pizza Hut Park'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'marcus.delgado@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs NYCFC Academy', '2026-03-15', 'Los Angeles, CA', 'MLS Next', 'Home — LA Galaxy training facility'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'santiago.vega@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Chicago Fire Academy', '2026-03-14', 'New York, NY', 'MLS Next', 'Away — Red Bull Arena turf'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'elias.okonkwo@lanista.test';

-- ECNL Boys players: Phoenix Showcase + game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECNL Boys Phoenix Showcase', '2026-03-20', 'Phoenix, AZ', 'ECNL Boys', 'U17/U18 bracket — Reach 11'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('jaylen.brooks@lanista.test','noah.chen@lanista.test');
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs De Anza Force', '2026-03-07', 'Columbus, OH', 'ECNL Boys', 'Home — Ohio Premier facility'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'jaylen.brooks@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Ohio Premier', '2026-03-07', 'Cupertino, CA', 'ECNL Boys', 'Home — De Anza Force complex'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'noah.chen@lanista.test';

-- ECRL + NPL players
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECRL Northeast Regional Showcase', '2026-04-18', 'Fredericksburg, VA', 'ECRL', 'U17 bracket — Reach Soccer Complex'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'luca.ferrari@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Columbus Crew Academy', '2026-03-14', 'Columbus, OH', 'ECRL', 'Away — OhioHealth Neuroscience Center'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'luca.ferrari@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Lonestar SC', '2026-03-14', 'Dallas, TX', 'NPL Boys', 'Home — FC Dallas Youth complex'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'omar.hassan@lanista.test';

-- ECNL Girls players: Phoenix Showcase + game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECNL Phoenix Showcase', '2026-03-20', 'Phoenix, AZ', 'ECNL Girls', 'U18/U19 bracket — Reach 11 Sports Complex'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('lucy.kim@lanista.test','sofia.ramirez@lanista.test','isabela.santos@lanista.test');
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs LAFC Slammers', '2026-03-07', 'San Diego, CA', 'ECNL Girls', 'Home — Surf Cup Sports Park'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'lucy.kim@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Tampa Bay United', '2026-03-07', 'Orlando, FL', 'ECNL Girls', 'Home — FESA fields'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'sofia.ramirez@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Concorde Fire', '2026-03-07', 'San Diego, CA', 'ECNL Girls', 'Home — Surf Cup Sports Park'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'isabela.santos@lanista.test';

-- Girls Academy: Events + game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECNL Phoenix Showcase', '2026-03-20', 'Phoenix, AZ', 'Girls Academy', 'U17 bracket — Reach 11 Sports Complex'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'maya.johnson@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs SoCal Blues', '2026-03-08', 'Orlando, FL', 'Girls Academy', 'Home — FESA main field'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'maya.johnson@lanista.test';

-- MLS Next Fest for top D1 male prospects
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'MLS Next Fest 2026', '2026-04-24', 'Cary, NC', 'MLS Next', 'Flagship showcase — U18 — WakeMed Soccer Park'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('kieran.ross@lanista.test','marcus.delgado@lanista.test','santiago.vega@lanista.test');

-- ── 8. Target Schools — existing 12 players ──────────────────────────────────

INSERT INTO player_target_schools (player_id, college_id, priority, status)
SELECT p.id, v.college_id::uuid, v.priority, v.status
FROM (VALUES
  -- Kieran Ross D1
  ('kieran.ross@lanista.test',    '50000000-0000-0000-0000-000000000004', 1, 'interested'), -- UCLA
  ('kieran.ross@lanista.test',    '50000000-0000-0000-0000-000000000005', 2, 'interested'), -- Wake Forest
  -- Marcus Delgado D1
  ('marcus.delgado@lanista.test', '50000000-0000-0000-0000-000000000002', 1, 'interested'), -- Duke
  ('marcus.delgado@lanista.test', '50000000-0000-0000-0000-000000000007', 2, 'contacted'),  -- Indiana
  -- Jaylen Brooks D1
  ('jaylen.brooks@lanista.test',  '50000000-0000-0000-0000-000000000001', 1, 'interested'), -- Penn State
  ('jaylen.brooks@lanista.test',  '50000000-0000-0000-0000-000000000008', 2, 'interested'), -- UVA
  -- Santiago Vega D1
  ('santiago.vega@lanista.test',  '50000000-0000-0000-0000-000000000003', 1, 'interested'), -- Stanford
  ('santiago.vega@lanista.test',  '50000000-0000-0000-0000-000000000004', 2, 'contacted'),  -- UCLA
  -- Noah Chen D1
  ('noah.chen@lanista.test',      '50000000-0000-0000-0000-000000000007', 1, 'visited'),    -- Indiana
  ('noah.chen@lanista.test',      '50000000-0000-0000-0000-000000000012', 2, 'contacted'),  -- Creighton
  -- Elias Okonkwo D2
  ('elias.okonkwo@lanista.test',  '50000000-0000-0000-0000-000000000023', 1, 'interested'), -- Adelphi
  ('elias.okonkwo@lanista.test',  '50000000-0000-0000-0000-000000000019', 2, 'interested'), -- Tampa
  -- Luca Ferrari D2
  ('luca.ferrari@lanista.test',   '50000000-0000-0000-0000-000000000021', 1, 'interested'), -- Mines
  ('luca.ferrari@lanista.test',   '50000000-0000-0000-0000-000000000022', 2, 'contacted'),  -- GCU
  -- Omar Hassan D3
  ('omar.hassan@lanista.test',    '50000000-0000-0000-0000-000000000025', 1, 'interested'), -- Trinity
  ('omar.hassan@lanista.test',    '50000000-0000-0000-0000-000000000026', 2, 'interested'), -- Williams
  -- Lucy Kim D2
  ('lucy.kim@lanista.test',       '50000000-0000-0000-0000-000000000019', 1, 'contacted'),  -- Tampa
  ('lucy.kim@lanista.test',       '50000000-0000-0000-0000-000000000023', 2, 'interested'), -- Adelphi
  -- Sofía Ramírez D1
  ('sofia.ramirez@lanista.test',  '50000000-0000-0000-0000-000000000001', 1, 'interested'), -- Penn State
  ('sofia.ramirez@lanista.test',  '50000000-0000-0000-0000-000000000006', 2, 'contacted'),  -- Georgetown
  -- Maya Johnson D1
  ('maya.johnson@lanista.test',   '50000000-0000-0000-0000-000000000002', 1, 'interested'), -- Duke
  ('maya.johnson@lanista.test',   '50000000-0000-0000-0000-000000000016', 2, 'interested'), -- UNC
  -- Isabela Santos D2
  ('isabela.santos@lanista.test', '50000000-0000-0000-0000-000000000019', 1, 'interested'), -- Tampa
  ('isabela.santos@lanista.test', '50000000-0000-0000-0000-000000000020', 2, 'contacted')   -- Lynn
) AS v(email, college_id, priority, status)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id
ON CONFLICT (player_id, college_id) DO NOTHING;

-- ── 9. Club Affiliations — existing 12 players ────────────────────────────────

INSERT INTO player_club_affiliations (player_id, club_id, age_group, season, jersey_number, is_active)
SELECT p.id, lc.id, v.age_group, '2025-2026', v.jersey, true
FROM (VALUES
  ('kieran.ross@lanista.test',    'LA Galaxy Academy',         'mlsnext', 'U18', 10),
  ('marcus.delgado@lanista.test', 'FC Dallas Academy',         'mlsnext', 'U18', 8),
  ('jaylen.brooks@lanista.test',  'Ohio Premier',              'ecnl',    'U17', 4),
  ('santiago.vega@lanista.test',  'LA Galaxy Academy',         'mlsnext', 'U19', 11),
  ('noah.chen@lanista.test',      'De Anza Force',             'mlsnext', 'U18', 1),
  ('elias.okonkwo@lanista.test',  'New York City FC Academy',  'mlsnext', 'U18', 2),
  ('luca.ferrari@lanista.test',   'Ohio Premier',              'ecrl',    'U17', 6),
  ('omar.hassan@lanista.test',    'Dallas Texans',             'npl',     'U19', 9),
  ('lucy.kim@lanista.test',       'San Diego Surf',            'ecnl',    'U18', 10),
  ('sofia.ramirez@lanista.test',  'Tampa Bay United',          'ecnl',    'U18', 7),
  ('maya.johnson@lanista.test',   'Tampa Bay United',          'ecnl',    'U17', 5),
  ('isabela.santos@lanista.test', 'San Diego Surf',            'ecnl',    'U19', 14)
) AS v(email, club_name, league, age_group, jersey)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id
JOIN league_clubs lc ON lc.club_name = v.club_name AND lc.league = v.league
ON CONFLICT (player_id, club_id, season) DO NOTHING;

-- ═════════════════════════════════════════════════════════════════════════════
-- 10. New Players: auth + public + player profiles
-- ═════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  sport_id UUID := '00000000-0000-0000-0000-000000000001';
  mlsnext  UUID := '10000000-0000-0000-0000-000000000001';
  ecnlb    UUID := '10000000-0000-0000-0000-000000000002';  -- ECNL Boys
  ecnlg    UUID := '10000000-0000-0000-0000-000000000003';  -- ECNL Girls
  ga       UUID := '10000000-0000-0000-0000-000000000004';  -- Girls Academy
  ecrl     UUID := '10000000-0000-0000-0000-000000000005';  -- ECRL
  -- legacy club shortcuts (only used for players with matching old club)
  club_sea UUID := '20000000-0000-0000-0000-000000000005';  -- Seattle Sounders Acad
  club_daz UUID := '20000000-0000-0000-0000-000000000008';  -- De Anza Force
  club_chi UUID := '20000000-0000-0000-0000-000000000003';  -- Chicago Fire Acad
  club_ohi UUID := '20000000-0000-0000-0000-000000000007';  -- Ohio Premier FC

  uid13 UUID := 'a1000000-0000-0000-0000-000000000013';
  uid14 UUID := 'a1000000-0000-0000-0000-000000000014';
  uid15 UUID := 'a1000000-0000-0000-0000-000000000015';
  uid16 UUID := 'a1000000-0000-0000-0000-000000000016';
  uid17 UUID := 'a1000000-0000-0000-0000-000000000017';
  uid18 UUID := 'a1000000-0000-0000-0000-000000000018';
  uid19 UUID := 'a1000000-0000-0000-0000-000000000019';
  uid20 UUID := 'a1000000-0000-0000-0000-000000000020';
  uid21 UUID := 'a1000000-0000-0000-0000-000000000021';
  uid22 UUID := 'a1000000-0000-0000-0000-000000000022';
  uid23 UUID := 'a1000000-0000-0000-0000-000000000023';
  uid24 UUID := 'a1000000-0000-0000-0000-000000000024';
  uid25 UUID := 'a1000000-0000-0000-0000-000000000025';
  uid26 UUID := 'a1000000-0000-0000-0000-000000000026';
  uid27 UUID := 'a1000000-0000-0000-0000-000000000027';
  uid28 UUID := 'a1000000-0000-0000-0000-000000000028';
  uid29 UUID := 'a1000000-0000-0000-0000-000000000029';
  uid30 UUID := 'a1000000-0000-0000-0000-000000000030';
  uid31 UUID := 'a1000000-0000-0000-0000-000000000031';
  uid32 UUID := 'a1000000-0000-0000-0000-000000000032';
  uid33 UUID := 'a1000000-0000-0000-0000-000000000033';
  uid34 UUID := 'a1000000-0000-0000-0000-000000000034';
  uid35 UUID := 'a1000000-0000-0000-0000-000000000035';
  uid36 UUID := 'a1000000-0000-0000-0000-000000000036';
  uid37 UUID := 'a1000000-0000-0000-0000-000000000037';
BEGIN

-- Auth users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES
  (uid13,'tyler.nguyen@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid14,'dante.williams@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid15,'kai.matagi@lanista.test',      crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid16,'rodrigo.mendoza@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid17,'aiden.park@lanista.test',      crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid18,'mateo.torres@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid19,'xavier.bell@lanista.test',     crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid20,'connor.murphy@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid21,'jalen.carter@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid22,'paulo.ferreira@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid23,'nico.alvarez@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid24,'adrian.kowalski@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid25,'declan.obrien@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid26,'samuel.asante@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid27,'victor.castillo@lanista.test', crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid28,'aria.thompson@lanista.test',   crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid29,'camila.ortiz@lanista.test',    crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid30,'emma.walsh@lanista.test',      crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid31,'priya.patel@lanista.test',     crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid32,'jade.martin@lanista.test',     crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid33,'riley.thompson@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid34,'valentina.cruz@lanista.test',  crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid35,'zara.hassan@lanista.test',     crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid36,'morgan.lee@lanista.test',      crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated'),
  (uid37,'elena.russo@lanista.test',     crypt('Lanista2026!',gen_salt('bf')),NOW(),'{"provider":"email","providers":["email"]}','{}',NOW(),NOW(),'authenticated','authenticated')
ON CONFLICT (id) DO NOTHING;

-- Public users
INSERT INTO users (id, email, role, first_name, last_name, language, onboarding_complete) VALUES
  (uid13,'tyler.nguyen@lanista.test',    'player','Tyler',    'Nguyen',   'en',true),
  (uid14,'dante.williams@lanista.test',  'player','Dante',    'Williams', 'en',true),
  (uid15,'kai.matagi@lanista.test',      'player','Kai',      'Matagi',   'en',true),
  (uid16,'rodrigo.mendoza@lanista.test', 'player','Rodrigo',  'Mendoza',  'es',true),
  (uid17,'aiden.park@lanista.test',      'player','Aiden',    'Park',     'en',true),
  (uid18,'mateo.torres@lanista.test',    'player','Mateo',    'Torres',   'es',true),
  (uid19,'xavier.bell@lanista.test',     'player','Xavier',   'Bell',     'en',true),
  (uid20,'connor.murphy@lanista.test',   'player','Connor',   'Murphy',   'en',true),
  (uid21,'jalen.carter@lanista.test',    'player','Jalen',    'Carter',   'en',true),
  (uid22,'paulo.ferreira@lanista.test',  'player','Paulo',    'Ferreira', 'es',true),
  (uid23,'nico.alvarez@lanista.test',    'player','Nico',     'Álvarez',  'es',true),
  (uid24,'adrian.kowalski@lanista.test', 'player','Adrian',   'Kowalski', 'en',true),
  (uid25,'declan.obrien@lanista.test',   'player','Declan',   'O''Brien', 'en',true),
  (uid26,'samuel.asante@lanista.test',   'player','Samuel',   'Asante',   'en',true),
  (uid27,'victor.castillo@lanista.test', 'player','Victor',   'Castillo', 'es',true),
  (uid28,'aria.thompson@lanista.test',   'player','Aria',     'Thompson', 'en',true),
  (uid29,'camila.ortiz@lanista.test',    'player','Camila',   'Ortiz',    'es',true),
  (uid30,'emma.walsh@lanista.test',      'player','Emma',     'Walsh',    'en',true),
  (uid31,'priya.patel@lanista.test',     'player','Priya',    'Patel',    'en',true),
  (uid32,'jade.martin@lanista.test',     'player','Jade',     'Martin',   'en',true),
  (uid33,'riley.thompson@lanista.test',  'player','Riley',    'Thompson', 'en',true),
  (uid34,'valentina.cruz@lanista.test',  'player','Valentina','Cruz',     'es',true),
  (uid35,'zara.hassan@lanista.test',     'player','Zara',     'Hassan',   'en',true),
  (uid36,'morgan.lee@lanista.test',      'player','Morgan',   'Lee',      'en',true),
  (uid37,'elena.russo@lanista.test',     'player','Elena',    'Russo',    'en',true)
ON CONFLICT (id) DO NOTHING;

-- Player profiles — Male (15)
INSERT INTO players (user_id, sport_id, gender, grade, graduation_year, height_cm, weight_kg,
  dominant_foot, speed_rating, gpa, sat_score, act_score, intended_major,
  target_division, is_discoverable, leadership_rating, league_id, club_id,
  date_of_birth, bio, character_description)
VALUES
  -- Tyler Nguyen | RW | MLS Next | Bay Area Surf | 2027 | D1
  (uid13,sport_id,'male',10,2027,175,70,'right',9,3.5,1240,27,'Kinesiology',
   'D1',true,4,mlsnext,NULL,'2008-06-15',
   'Explosive right winger with elite change of pace. 11 goals + 9 assists in MLS Next Southwest this season.',
   'Team-first mentality. Sprints back defensively without being asked. Raises intensity of everyone around him.'),

  -- Dante Williams | CM | ECNL Boys | Eclipse Select SC | 2026 | D1
  (uid14,sport_id,'male',11,2026,177,73,'right',8,3.0,1120,24,'Business Administration',
   'D1',true,4,ecnlb,NULL,'2007-09-22',
   'Press-resistant CM with elite vision and a killer short pass. Shields possession under pressure.',
   'Vocal leader in the midfield. Calls for the ball even in tight moments. Demands excellence from teammates.'),

  -- Kai Matagi | CB | MLS Next | Seattle Sounders Acad | 2027 | D1
  (uid15,sport_id,'male',10,2027,186,82,'right',7,3.6,1310,29,'Sports Science',
   'D1',true,5,mlsnext,club_sea,'2008-03-30',
   'Commanding 6''1" CB with elite aerial ability and excellent 1v1 defending. Strong out of the back.',
   'Natural organizer. Communicates constantly with the back line. First on the field, last to leave.'),

  -- Rodrigo Mendoza | ST | MLS Next | Pateadores | 2028 | D1
  (uid16,sport_id,'male',9,2028,180,77,'right',9,2.8,1050,22,'Undecided',
   'D1',true,3,mlsnext,NULL,'2009-07-04',
   'Technically gifted No. 9 with deceptive first step. Lethal finisher — clinical from inside 18.',
   'Raw but supremely talented. Working hard to improve discipline off the ball. High upside.'),

  -- Aiden Park | GK | ECNL Boys | De Anza Force | 2027 | D2
  (uid17,sport_id,'male',10,2027,190,84,'right',6,3.9,1410,31,'Pre-Law',
   'D2',true,5,ecnlb,club_daz,'2008-01-12',
   'Tall, athletic goalkeeper with outstanding shot-stopping reflexes. Distributes confidently with both feet.',
   'Brilliant student who brings the same precision to the pitch that he brings to the classroom. Smart under pressure.'),

  -- Mateo Torres | LW | MLS Next | Real Colorado | 2026 | D1
  (uid18,sport_id,'male',11,2026,173,68,'left',10,3.2,1150,25,'Communications',
   'D1',true,4,mlsnext,NULL,'2007-12-19',
   'Left-footed winger with the fastest first step in the league. Beats defenders wide and delivers dangerous crosses.',
   'Fearless competitor. Relishes 1v1 duels. Brings energy that shifts momentum.'),

  -- Xavier Bell | CDM | ECNL Boys | Eclipse Select SC | 2028 | D2
  (uid19,sport_id,'male',9,2028,183,79,'right',7,3.4,1180,26,'Exercise Science',
   'D2',true,4,ecnlb,NULL,'2009-04-08',
   'Disciplined CDM who reads passing lanes before the ball is played. Breaks up counters efficiently.',
   'Coachable and competitive. Watches film proactively. Understands the game beyond his years.'),

  -- Connor Murphy | RB | MLS Next | Delco SC | 2026 | D2
  (uid20,sport_id,'male',11,2026,176,72,'right',8,3.1,1090,23,'Marketing',
   'D2',true,3,mlsnext,NULL,'2007-10-31',
   'Attack-minded fullback who overlaps relentlessly. Registered 7 assists from right back this season.',
   'Motor never stops. Works both ends of the pitch without complaint. Great teammate.'),

  -- Jalen Carter | ST | MLS Next | Solar Soccer Club | 2027 | D1
  (uid21,sport_id,'male',10,2027,183,78,'right',9,3.3,1180,26,'Business',
   'D1',true,4,mlsnext,NULL,'2008-08-03',
   'Physical striker with elite hold-up play and powerful shot. Wins headers, brings teammates into play.',
   'Competitive fire you can''t teach. Holds himself to high standards and pulls teammates up with him.'),

  -- Paulo Ferreira | LB | MLS Next | Weston FC | 2026 | D1
  (uid22,sport_id,'male',11,2026,178,74,'left',8,3.0,1100,23,'Psychology',
   'D1',true,3,mlsnext,NULL,'2007-11-25',
   'Left-footed LB with great defensive positioning and ability to build from the back. Composed under pressure.',
   'Quiet intensity. Consistently one of the most reliable defenders on the field. Earns trust immediately.'),

  -- Nico Álvarez | CAM | ECRL | Ohio Premier | 2028 | D3
  (uid23,sport_id,'male',9,2028,172,67,'right',7,3.7,1280,28,'Computer Science',
   'D3',true,3,ecrl,club_ohi,'2009-02-14',
   'Creative attacking midfielder with exceptional dribbling in tight spaces. Vision to find teammates in dangerous zones.',
   'Plays with joy. Technical ability paired with high academic drive. D3 program to get both soccer and academics.'),

  -- Adrian Kowalski | CB | MLS Next | Chicago Magic PSG | 2027 | D1
  (uid24,sport_id,'male',10,2027,185,81,'right',7,3.2,1160,25,'Architecture',
   'D1',true,4,mlsnext,club_chi,'2008-05-20',
   'Left-footed CB who reads the game exceptionally well. Excellent first pass and comfortable under pressure.',
   'Calm and intelligent. Never panics on the ball. Leads by example and commands respect.'),

  -- Declan O''Brien | CM | MLS Next | Richmond Strikers | 2026 | D2
  (uid25,sport_id,'male',11,2026,179,75,'right',8,3.5,1210,27,'History',
   'D2',true,4,mlsnext,NULL,'2007-08-18',
   'High-IQ central midfielder who controls tempo and presses intelligently. Strong defensive contribution.',
   'Student of the game. Understands tactical systems deeply. Will be a coach someday.'),

  -- Samuel Asante | RW | MLS Next | Concorde Fire | 2027 | D1
  (uid26,sport_id,'male',10,2027,176,71,'right',10,3.1,1190,25,'Sports Management',
   'D1',true,4,mlsnext,NULL,'2008-07-09',
   'Electric right winger from Atlanta. Fastest player in the Southeast region. Clinical 1v1.',
   'High energy. Uses pace as a weapon. Continues to add technical refinement to his natural gifts.'),

  -- Victor Castillo | GK | MLS Next | Lonestar SC | 2028 | D1
  (uid27,sport_id,'male',9,2028,188,83,'right',6,3.6,1290,28,'Biomedical Engineering',
   'D1',true,5,mlsnext,NULL,'2009-09-14',
   'Technically elite GK with outstanding footwork. Initiates attacks through the back line with precision distribution.',
   'Composed beyond his years. Rarely rattled. Organizes the defense as if he has played 10 more years.')
ON CONFLICT (user_id) DO NOTHING;

-- Player profiles — Female (10)
INSERT INTO players (user_id, sport_id, gender, grade, graduation_year, height_cm, weight_kg,
  dominant_foot, speed_rating, gpa, sat_score, act_score, intended_major,
  target_division, is_discoverable, leadership_rating, league_id, club_id,
  date_of_birth, bio, character_description)
VALUES
  -- Aria Thompson | ST | ECNL Girls | Carolina FC | 2027 | D1
  (uid28,sport_id,'female',10,2027,168,61,'right',9,3.8,1380,30,'Biology',
   'D1',true,5,ecnlg,NULL,'2008-04-22',
   'Clinical finisher with exceptional movement off the ball. Led ECNL Southeast region in goals.',
   'Natural leader in the locker room. One of those players coaches love — high achiever on and off the field.'),

  -- Camila Ortiz | CAM | ECNL Girls | Solar Soccer Club | 2026 | D1
  (uid29,sport_id,'female',11,2026,165,58,'right',8,3.4,1210,26,'International Relations',
   'D1',true,4,ecnlg,NULL,'2007-10-11',
   'Technically gifted No. 10 who orchestrates attacks with creativity and precision. Bilingual communication asset.',
   'Mature and composed. Plays with confidence that elevates teammates. Bilingual — leads in both English and Spanish.'),

  -- Emma Walsh | GK | ECNL Girls | Crossfire Premier | 2027 | D1
  (uid30,sport_id,'female',10,2027,173,64,'right',7,3.9,1430,33,'Neuroscience',
   'D1',true,5,ecnlg,NULL,'2008-02-07',
   'Elite shot-stopper who commands her box with authority. Comfortable sweeping high crosses and distributing long.',
   'Academic All-American mentality. One of the top students in her class. Sets the tone through work ethic.'),

  -- Priya Patel | CM | ECNL Girls | Michigan Hawks | 2028 | D2
  (uid31,sport_id,'female',9,2028,163,57,'right',7,3.7,1350,30,'Chemistry',
   'D2',true,4,ecnlg,NULL,'2009-01-30',
   'Technically precise midfielder with excellent press resistance. Plays short and long with equal confidence.',
   'Driven by academics as much as soccer. D2 athlete-scholar profile. Brings professionalism everywhere she goes.'),

  -- Jade Martin | LB | ECNL Girls | Concorde Fire | 2026 | D2
  (uid32,sport_id,'female',11,2026,167,60,'left',8,3.2,1090,23,'Criminal Justice',
   'D2',true,3,ecnlg,NULL,'2007-09-05',
   'Left-footed LB who consistently wins defensive duels and overlaps effectively into attack.',
   'Tough and fearless. Relishes physical battles. Will always be one of the hardest workers on the field.'),

  -- Riley Thompson | RW | ECNL Girls | Colorado Rush | 2027 | D1
  (uid33,sport_id,'female',10,2027,164,56,'right',9,3.5,1240,27,'Environmental Science',
   'D1',true,4,ecnlg,NULL,'2008-06-24',
   'Speedy right winger who stretches defenses and converts from wide areas. 10 goals from the right flank.',
   'Energetic and coachable. Sprints every ball, wins every 50/50. High-character competitor.'),

  -- Valentina Cruz | CB | ECNL Girls | Real Colorado | 2027 | D1
  (uid34,sport_id,'female',10,2027,170,62,'right',7,3.3,1170,25,'Political Science',
   'D1',true,4,ecnlg,NULL,'2008-11-16',
   'Composed CB who wins headers and reads danger early. Excellent under pressure with the ball at her feet.',
   'Calm and authoritative. Organizes the back line in Spanish and English. Future team captain.'),

  -- Zara Hassan | CM | ECNL Girls | Bethesda SC | 2026 | D1
  (uid35,sport_id,'female',11,2026,162,55,'right',8,3.6,1330,29,'Pre-Medicine',
   'D1',true,5,ecnlg,NULL,'2007-07-19',
   'High-energy central midfielder who presses relentlessly and plays quick 1-2s in tight spaces.',
   'Fierce competitor with excellent character. Combines elite academics with top-level soccer drive.'),

  -- Morgan Lee | ST | ECNL Girls | Tampa Bay United | 2028 | D2
  (uid36,sport_id,'female',9,2028,169,63,'right',8,3.4,1160,25,'Exercise Physiology',
   'D2',true,4,ecnlg,NULL,'2009-03-28',
   'Athletic striker with clever movement and ability to score in traffic. Strong finisher in the air.',
   'Hard-working and coachable. Responds to feedback and applies it immediately. Great teammate.'),

  -- Elena Russo | LW | ECNL Girls | De Anza Force | 2027 | D1
  (uid37,sport_id,'female',10,2027,164,57,'left',9,3.8,1380,31,'Architecture',
   'D1',true,4,ecnlg,NULL,'2008-09-03',
   'Left-footed winger with elite technique. Dangerous in 1v1 and delivers pinpoint crosses from the left.',
   'Artistic and technically gifted. Plays with joy and creativity that draws crowds. Great attitude.')
ON CONFLICT (user_id) DO NOTHING;

END $$;

-- ── 11. Positions — new 25 players ───────────────────────────────────────────

INSERT INTO player_positions (player_id, position_id, is_primary, proficiency)
SELECT p.id, v.pos_id::uuid, v.is_primary, v.proficiency
FROM (VALUES
  ('tyler.nguyen@lanista.test',    '40000000-0000-0000-0000-000000000010', true,  9),   -- RW
  ('tyler.nguyen@lanista.test',    '40000000-0000-0000-0000-000000000011', false, 7),   -- LW
  ('dante.williams@lanista.test',  '40000000-0000-0000-0000-000000000006', true,  8),   -- CM
  ('dante.williams@lanista.test',  '40000000-0000-0000-0000-000000000007', false, 7),   -- CAM
  ('kai.matagi@lanista.test',      '40000000-0000-0000-0000-000000000003', true,  9),   -- CB
  ('kai.matagi@lanista.test',      '40000000-0000-0000-0000-000000000004', false, 6),   -- LB
  ('rodrigo.mendoza@lanista.test', '40000000-0000-0000-0000-000000000012', true,  9),   -- ST
  ('rodrigo.mendoza@lanista.test', '40000000-0000-0000-0000-000000000013', false, 7),   -- CF
  ('aiden.park@lanista.test',      '40000000-0000-0000-0000-000000000001', true,  9),   -- GK
  ('mateo.torres@lanista.test',    '40000000-0000-0000-0000-000000000011', true,  10),  -- LW
  ('mateo.torres@lanista.test',    '40000000-0000-0000-0000-000000000010', false, 7),   -- RW
  ('xavier.bell@lanista.test',     '40000000-0000-0000-0000-000000000005', true,  8),   -- CDM
  ('xavier.bell@lanista.test',     '40000000-0000-0000-0000-000000000006', false, 7),   -- CM
  ('connor.murphy@lanista.test',   '40000000-0000-0000-0000-000000000002', true,  8),   -- RB
  ('connor.murphy@lanista.test',   '40000000-0000-0000-0000-000000000008', false, 6),   -- RM
  ('jalen.carter@lanista.test',    '40000000-0000-0000-0000-000000000012', true,  9),   -- ST
  ('jalen.carter@lanista.test',    '40000000-0000-0000-0000-000000000013', false, 7),   -- CF
  ('paulo.ferreira@lanista.test',  '40000000-0000-0000-0000-000000000004', true,  8),   -- LB
  ('paulo.ferreira@lanista.test',  '40000000-0000-0000-0000-000000000009', false, 6),   -- LM
  ('nico.alvarez@lanista.test',    '40000000-0000-0000-0000-000000000007', true,  8),   -- CAM
  ('nico.alvarez@lanista.test',    '40000000-0000-0000-0000-000000000006', false, 7),   -- CM
  ('adrian.kowalski@lanista.test', '40000000-0000-0000-0000-000000000003', true,  8),   -- CB
  ('adrian.kowalski@lanista.test', '40000000-0000-0000-0000-000000000005', false, 6),   -- CDM
  ('declan.obrien@lanista.test',   '40000000-0000-0000-0000-000000000006', true,  8),   -- CM
  ('declan.obrien@lanista.test',   '40000000-0000-0000-0000-000000000005', false, 7),   -- CDM
  ('samuel.asante@lanista.test',   '40000000-0000-0000-0000-000000000010', true,  10),  -- RW
  ('samuel.asante@lanista.test',   '40000000-0000-0000-0000-000000000012', false, 7),   -- ST
  ('victor.castillo@lanista.test', '40000000-0000-0000-0000-000000000001', true,  9),   -- GK
  ('aria.thompson@lanista.test',   '40000000-0000-0000-0000-000000000012', true,  9),   -- ST
  ('aria.thompson@lanista.test',   '40000000-0000-0000-0000-000000000010', false, 7),   -- RW
  ('camila.ortiz@lanista.test',    '40000000-0000-0000-0000-000000000007', true,  9),   -- CAM
  ('camila.ortiz@lanista.test',    '40000000-0000-0000-0000-000000000006', false, 7),   -- CM
  ('emma.walsh@lanista.test',      '40000000-0000-0000-0000-000000000001', true,  9),   -- GK
  ('priya.patel@lanista.test',     '40000000-0000-0000-0000-000000000006', true,  8),   -- CM
  ('priya.patel@lanista.test',     '40000000-0000-0000-0000-000000000005', false, 6),   -- CDM
  ('jade.martin@lanista.test',     '40000000-0000-0000-0000-000000000004', true,  8),   -- LB
  ('jade.martin@lanista.test',     '40000000-0000-0000-0000-000000000009', false, 6),   -- LM
  ('riley.thompson@lanista.test',  '40000000-0000-0000-0000-000000000010', true,  9),   -- RW
  ('riley.thompson@lanista.test',  '40000000-0000-0000-0000-000000000011', false, 7),   -- LW
  ('valentina.cruz@lanista.test',  '40000000-0000-0000-0000-000000000003', true,  8),   -- CB
  ('valentina.cruz@lanista.test',  '40000000-0000-0000-0000-000000000004', false, 6),   -- LB
  ('zara.hassan@lanista.test',     '40000000-0000-0000-0000-000000000006', true,  9),   -- CM
  ('zara.hassan@lanista.test',     '40000000-0000-0000-0000-000000000007', false, 7),   -- CAM
  ('morgan.lee@lanista.test',      '40000000-0000-0000-0000-000000000012', true,  8),   -- ST
  ('morgan.lee@lanista.test',      '40000000-0000-0000-0000-000000000013', false, 6),   -- CF
  ('elena.russo@lanista.test',     '40000000-0000-0000-0000-000000000011', true,  9),   -- LW
  ('elena.russo@lanista.test',     '40000000-0000-0000-0000-000000000010', false, 7)    -- RW
) AS v(email, pos_id, is_primary, proficiency)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id
ON CONFLICT (player_id, position_id) DO NOTHING;

-- ── 12. Target Schools — new 25 players ──────────────────────────────────────

INSERT INTO player_target_schools (player_id, college_id, priority, status)
SELECT p.id, v.college_id::uuid, v.priority, v.status
FROM (VALUES
  -- Tyler Nguyen D1
  ('tyler.nguyen@lanista.test',    '50000000-0000-0000-0000-000000000004', 1, 'interested'), -- UCLA
  ('tyler.nguyen@lanista.test',    '50000000-0000-0000-0000-000000000003', 2, 'interested'), -- Stanford
  -- Dante Williams D1
  ('dante.williams@lanista.test',  '50000000-0000-0000-0000-000000000007', 1, 'contacted'),  -- Indiana
  ('dante.williams@lanista.test',  '50000000-0000-0000-0000-000000000005', 2, 'interested'), -- Wake Forest
  -- Kai Matagi D1
  ('kai.matagi@lanista.test',      '50000000-0000-0000-0000-000000000001', 1, 'visited'),    -- Penn State
  ('kai.matagi@lanista.test',      '50000000-0000-0000-0000-000000000008', 2, 'contacted'),  -- UVA
  -- Rodrigo Mendoza D1
  ('rodrigo.mendoza@lanista.test', '50000000-0000-0000-0000-000000000004', 1, 'interested'), -- UCLA
  ('rodrigo.mendoza@lanista.test', '50000000-0000-0000-0000-000000000015', 2, 'interested'), -- Portland
  -- Aiden Park D2
  ('aiden.park@lanista.test',      '50000000-0000-0000-0000-000000000023', 1, 'contacted'),  -- Adelphi
  ('aiden.park@lanista.test',      '50000000-0000-0000-0000-000000000021', 2, 'interested'), -- Mines
  -- Mateo Torres D1
  ('mateo.torres@lanista.test',    '50000000-0000-0000-0000-000000000009', 1, 'interested'), -- Notre Dame
  ('mateo.torres@lanista.test',    '50000000-0000-0000-0000-000000000005', 2, 'contacted'),  -- Wake Forest
  -- Xavier Bell D2
  ('xavier.bell@lanista.test',     '50000000-0000-0000-0000-000000000022', 1, 'interested'), -- GCU
  ('xavier.bell@lanista.test',     '50000000-0000-0000-0000-000000000019', 2, 'interested'), -- Tampa
  -- Connor Murphy D2
  ('connor.murphy@lanista.test',   '50000000-0000-0000-0000-000000000023', 1, 'contacted'),  -- Adelphi
  ('connor.murphy@lanista.test',   '50000000-0000-0000-0000-000000000024', 2, 'interested'), -- Florida Tech
  -- Jalen Carter D1
  ('jalen.carter@lanista.test',    '50000000-0000-0000-0000-000000000002', 1, 'interested'), -- Duke
  ('jalen.carter@lanista.test',    '50000000-0000-0000-0000-000000000005', 2, 'contacted'),  -- Wake Forest
  -- Paulo Ferreira D1
  ('paulo.ferreira@lanista.test',  '50000000-0000-0000-0000-000000000009', 1, 'interested'), -- Notre Dame
  ('paulo.ferreira@lanista.test',  '50000000-0000-0000-0000-000000000007', 2, 'interested'), -- Indiana
  -- Nico Álvarez D3
  ('nico.alvarez@lanista.test',    '50000000-0000-0000-0000-000000000026', 1, 'interested'), -- Williams
  ('nico.alvarez@lanista.test',    '50000000-0000-0000-0000-000000000025', 2, 'interested'), -- Trinity
  -- Adrian Kowalski D1
  ('adrian.kowalski@lanista.test', '50000000-0000-0000-0000-000000000001', 1, 'visited'),    -- Penn State
  ('adrian.kowalski@lanista.test', '50000000-0000-0000-0000-000000000010', 2, 'contacted'),  -- Maryland
  -- Declan O'Brien D2
  ('declan.obrien@lanista.test',   '50000000-0000-0000-0000-000000000019', 1, 'interested'), -- Tampa
  ('declan.obrien@lanista.test',   '50000000-0000-0000-0000-000000000024', 2, 'contacted'),  -- Florida Tech
  -- Samuel Asante D1
  ('samuel.asante@lanista.test',   '50000000-0000-0000-0000-000000000002', 1, 'interested'), -- Duke
  ('samuel.asante@lanista.test',   '50000000-0000-0000-0000-000000000016', 2, 'interested'), -- UNC
  -- Victor Castillo D1
  ('victor.castillo@lanista.test', '50000000-0000-0000-0000-000000000009', 1, 'interested'), -- Notre Dame
  ('victor.castillo@lanista.test', '50000000-0000-0000-0000-000000000007', 2, 'interested'), -- Indiana
  -- Aria Thompson D1
  ('aria.thompson@lanista.test',   '50000000-0000-0000-0000-000000000016', 1, 'contacted'),  -- UNC
  ('aria.thompson@lanista.test',   '50000000-0000-0000-0000-000000000002', 2, 'interested'), -- Duke
  -- Camila Ortiz D1
  ('camila.ortiz@lanista.test',    '50000000-0000-0000-0000-000000000006', 1, 'contacted'),  -- Georgetown
  ('camila.ortiz@lanista.test',    '50000000-0000-0000-0000-000000000005', 2, 'interested'), -- Wake Forest
  -- Emma Walsh D1
  ('emma.walsh@lanista.test',      '50000000-0000-0000-0000-000000000003', 1, 'interested'), -- Stanford
  ('emma.walsh@lanista.test',      '50000000-0000-0000-0000-000000000009', 2, 'visited'),    -- Notre Dame
  -- Priya Patel D2
  ('priya.patel@lanista.test',     '50000000-0000-0000-0000-000000000019', 1, 'interested'), -- Tampa
  ('priya.patel@lanista.test',     '50000000-0000-0000-0000-000000000023', 2, 'contacted'),  -- Adelphi
  -- Jade Martin D2
  ('jade.martin@lanista.test',     '50000000-0000-0000-0000-000000000022', 1, 'interested'), -- GCU
  ('jade.martin@lanista.test',     '50000000-0000-0000-0000-000000000021', 2, 'interested'), -- Mines
  -- Riley Thompson D1
  ('riley.thompson@lanista.test',  '50000000-0000-0000-0000-000000000009', 1, 'interested'), -- Notre Dame
  ('riley.thompson@lanista.test',  '50000000-0000-0000-0000-000000000014', 2, 'contacted'),  -- Gonzaga
  -- Valentina Cruz D1
  ('valentina.cruz@lanista.test',  '50000000-0000-0000-0000-000000000006', 1, 'interested'), -- Georgetown
  ('valentina.cruz@lanista.test',  '50000000-0000-0000-0000-000000000001', 2, 'interested'), -- Penn State
  -- Zara Hassan D1
  ('zara.hassan@lanista.test',     '50000000-0000-0000-0000-000000000002', 1, 'contacted'),  -- Duke
  ('zara.hassan@lanista.test',     '50000000-0000-0000-0000-000000000006', 2, 'interested'), -- Georgetown
  -- Morgan Lee D2
  ('morgan.lee@lanista.test',      '50000000-0000-0000-0000-000000000019', 1, 'interested'), -- Tampa
  ('morgan.lee@lanista.test',      '50000000-0000-0000-0000-000000000024', 2, 'interested'), -- Florida Tech
  -- Elena Russo D1
  ('elena.russo@lanista.test',     '50000000-0000-0000-0000-000000000003', 1, 'interested'), -- Stanford
  ('elena.russo@lanista.test',     '50000000-0000-0000-0000-000000000004', 2, 'contacted')   -- UCLA
) AS v(email, college_id, priority, status)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id
ON CONFLICT (player_id, college_id) DO NOTHING;

-- ── 13. Highlight Videos — new 25 players ────────────────────────────────────

INSERT INTO player_videos (player_id, title, source, external_url, is_primary, analysis_status)
SELECT p.id, v.title, 'hudl', v.url, true, 'pending'
FROM (VALUES
  ('tyler.nguyen@lanista.test',    '2025-26 Highlights – Tyler Nguyen',    'https://www.hudl.com/video/3/14203830/tyler-nguyen-rw'),
  ('dante.williams@lanista.test',  '2025-26 Highlights – Dante Williams',  'https://www.hudl.com/video/3/14203831/dante-williams-cm'),
  ('kai.matagi@lanista.test',      '2025-26 Highlights – Kai Matagi',      'https://www.hudl.com/video/3/14203832/kai-matagi-cb'),
  ('rodrigo.mendoza@lanista.test', '2025-26 Highlights – Rodrigo Mendoza', 'https://www.hudl.com/video/3/14203833/rodrigo-mendoza-st'),
  ('aiden.park@lanista.test',      '2025-26 Highlights – Aiden Park',      'https://www.hudl.com/video/3/14203834/aiden-park-gk'),
  ('mateo.torres@lanista.test',    '2025-26 Highlights – Mateo Torres',    'https://www.hudl.com/video/3/14203835/mateo-torres-lw'),
  ('xavier.bell@lanista.test',     '2025-26 Highlights – Xavier Bell',     'https://www.hudl.com/video/3/14203836/xavier-bell-cdm'),
  ('connor.murphy@lanista.test',   '2025-26 Highlights – Connor Murphy',   'https://www.hudl.com/video/3/14203837/connor-murphy-rb'),
  ('jalen.carter@lanista.test',    '2025-26 Highlights – Jalen Carter',    'https://www.hudl.com/video/3/14203838/jalen-carter-st'),
  ('paulo.ferreira@lanista.test',  '2025-26 Highlights – Paulo Ferreira',  'https://www.hudl.com/video/3/14203839/paulo-ferreira-lb'),
  ('nico.alvarez@lanista.test',    '2025-26 Highlights – Nico Álvarez',    'https://www.hudl.com/video/3/14203840/nico-alvarez-cam'),
  ('adrian.kowalski@lanista.test', '2025-26 Highlights – Adrian Kowalski', 'https://www.hudl.com/video/3/14203841/adrian-kowalski-cb'),
  ('declan.obrien@lanista.test',   '2025-26 Highlights – Declan O''Brien', 'https://www.hudl.com/video/3/14203842/declan-obrien-cm'),
  ('samuel.asante@lanista.test',   '2025-26 Highlights – Samuel Asante',   'https://www.hudl.com/video/3/14203843/samuel-asante-rw'),
  ('victor.castillo@lanista.test', '2025-26 Highlights – Victor Castillo', 'https://www.hudl.com/video/3/14203844/victor-castillo-gk'),
  ('aria.thompson@lanista.test',   '2025-26 Highlights – Aria Thompson',   'https://www.hudl.com/video/3/14203845/aria-thompson-st'),
  ('camila.ortiz@lanista.test',    '2025-26 Highlights – Camila Ortiz',    'https://www.hudl.com/video/3/14203846/camila-ortiz-cam'),
  ('emma.walsh@lanista.test',      '2025-26 Highlights – Emma Walsh',      'https://www.hudl.com/video/3/14203847/emma-walsh-gk'),
  ('priya.patel@lanista.test',     '2025-26 Highlights – Priya Patel',     'https://www.hudl.com/video/3/14203848/priya-patel-cm'),
  ('jade.martin@lanista.test',     '2025-26 Highlights – Jade Martin',     'https://www.hudl.com/video/3/14203849/jade-martin-lb'),
  ('riley.thompson@lanista.test',  '2025-26 Highlights – Riley Thompson',  'https://www.hudl.com/video/3/14203850/riley-thompson-rw'),
  ('valentina.cruz@lanista.test',  '2025-26 Highlights – Valentina Cruz',  'https://www.hudl.com/video/3/14203851/valentina-cruz-cb'),
  ('zara.hassan@lanista.test',     '2025-26 Highlights – Zara Hassan',     'https://www.hudl.com/video/3/14203852/zara-hassan-cm'),
  ('morgan.lee@lanista.test',      '2025-26 Highlights – Morgan Lee',      'https://www.hudl.com/video/3/14203853/morgan-lee-st'),
  ('elena.russo@lanista.test',     '2025-26 Highlights – Elena Russo',     'https://www.hudl.com/video/3/14203854/elena-russo-lw')
) AS v(email, title, url)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id;

-- ── 14. Schedule — new 25 players ────────────────────────────────────────────

-- MLS Next boys: Spring Showcase + MLS Next Fest + individual game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'MLS Next Spring Showcase', '2026-03-21', 'Mesa, AZ', 'MLS Next', 'U18 bracket'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('tyler.nguyen@lanista.test','rodrigo.mendoza@lanista.test','mateo.torres@lanista.test',
                  'jalen.carter@lanista.test','paulo.ferreira@lanista.test','adrian.kowalski@lanista.test',
                  'declan.obrien@lanista.test','samuel.asante@lanista.test','victor.castillo@lanista.test');

INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'MLS Next Fest 2026', '2026-04-24', 'Cary, NC', 'MLS Next', 'Flagship showcase — top bracket — WakeMed'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('tyler.nguyen@lanista.test','kai.matagi@lanista.test','jalen.carter@lanista.test',
                  'samuel.asante@lanista.test');

INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', v.opp, v.gdate::date, v.loc, 'MLS Next', NULL
FROM (VALUES
  ('tyler.nguyen@lanista.test',    'vs Pateadores',          '2026-03-08', 'Pleasanton, CA'),
  ('rodrigo.mendoza@lanista.test', 'vs LA Galaxy Academy',   '2026-03-08', 'Mission Hills, CA'),
  ('mateo.torres@lanista.test',    'vs Colorado Rapids Acad','2026-03-14', 'Thornton, CO'),
  ('connor.murphy@lanista.test',   'vs Penn Fusion SA',      '2026-03-07', 'Springfield, PA'),
  ('jalen.carter@lanista.test',    'vs Houston Dynamo Acad', '2026-03-14', 'Dallas, TX'),
  ('paulo.ferreira@lanista.test',  'vs Orlando City Acad',   '2026-03-07', 'Weston, FL'),
  ('adrian.kowalski@lanista.test', 'vs Eclipse Select SC',   '2026-03-07', 'Oswego, IL'),
  ('declan.obrien@lanista.test',   'vs Bethesda SC',         '2026-03-07', 'Richmond, VA'),
  ('samuel.asante@lanista.test',   'vs Atlanta United Acad', '2026-03-08', 'Atlanta, GA'),
  ('victor.castillo@lanista.test', 'vs Solar Soccer Club',   '2026-03-07', 'Austin, TX')
) AS v(email, opp, gdate, loc)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id;

-- ECNL Boys players: Phoenix Showcase + game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECNL Boys Phoenix Showcase', '2026-03-20', 'Phoenix, AZ', 'ECNL Boys', 'U17/U18 bracket — Reach 11'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('dante.williams@lanista.test','aiden.park@lanista.test','xavier.bell@lanista.test');

INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', v.opp, v.gdate::date, v.loc, 'ECNL Boys', NULL
FROM (VALUES
  ('dante.williams@lanista.test', 'vs Chicago Magic PSG',  '2026-03-07', 'Oswego, IL'),
  ('aiden.park@lanista.test',     'vs Ohio Premier',       '2026-03-07', 'Cupertino, CA'),
  ('xavier.bell@lanista.test',    'vs Michigan Hawks',     '2026-03-07', 'Cary, NC')
) AS v(email, opp, gdate, loc)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id;

-- ECRL player: showcase + game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECRL Northeast Regional Showcase', '2026-04-18', 'Fredericksburg, VA', 'ECRL', 'U17 bracket'
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'nico.alvarez@lanista.test';
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', 'vs Pittsburgh Riverhounds Acad', '2026-03-14', 'Columbus, OH', 'ECRL', NULL
FROM players p JOIN users u ON p.user_id = u.id WHERE u.email = 'nico.alvarez@lanista.test';

-- ECNL Girls: Phoenix Showcase + San Diego Showcase + individual game
INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECNL Phoenix Showcase', '2026-03-20', 'Phoenix, AZ', 'ECNL Girls', 'Reach 11 Sports Complex'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('aria.thompson@lanista.test','camila.ortiz@lanista.test','emma.walsh@lanista.test',
                  'jade.martin@lanista.test','riley.thompson@lanista.test','valentina.cruz@lanista.test',
                  'zara.hassan@lanista.test','elena.russo@lanista.test');

INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'showcase', 'ECNL San Diego Showcase', '2026-04-03', 'San Diego, CA', 'ECNL Girls', 'Surf Cup Sports Park'
FROM players p JOIN users u ON p.user_id = u.id
WHERE u.email IN ('aria.thompson@lanista.test','emma.walsh@lanista.test','riley.thompson@lanista.test',
                  'priya.patel@lanista.test','morgan.lee@lanista.test');

INSERT INTO player_schedule (player_id, event_type, title, event_date, location, competition, notes)
SELECT p.id, 'game', v.opp, v.gdate::date, v.loc, 'ECNL Girls', NULL
FROM (VALUES
  ('aria.thompson@lanista.test',   'vs LAFC Slammers',      '2026-03-07', 'Cary, NC'),
  ('camila.ortiz@lanista.test',    'vs Concorde Fire',       '2026-03-07', 'Dallas, TX'),
  ('emma.walsh@lanista.test',      'vs Eastside FC',         '2026-03-07', 'Redmond, WA'),
  ('priya.patel@lanista.test',     'vs Eclipse Select SC',   '2026-03-07', 'Ann Arbor, MI'),
  ('jade.martin@lanista.test',     'vs Solar Soccer Club',   '2026-03-07', 'Atlanta, GA'),
  ('riley.thompson@lanista.test',  'vs Utah Royals Acad',    '2026-03-07', 'Denver, CO'),
  ('valentina.cruz@lanista.test',  'vs Colorado Rush',       '2026-03-08', 'Thornton, CO'),
  ('zara.hassan@lanista.test',     'vs PDA',                 '2026-03-07', 'Bethesda, MD'),
  ('morgan.lee@lanista.test',      'vs Space Coast United',  '2026-03-07', 'Tampa, FL'),
  ('elena.russo@lanista.test',     'vs West Coast FC',       '2026-03-07', 'Cupertino, CA')
) AS v(email, opp, gdate, loc)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id;

-- ── 15. Club Affiliations — new 25 players ────────────────────────────────────

INSERT INTO player_club_affiliations (player_id, club_id, age_group, season, jersey_number, is_active)
SELECT p.id, lc.id, v.age_group, '2025-2026', v.jersey, true
FROM (VALUES
  ('tyler.nguyen@lanista.test',    'Bay Area Surf',         'mlsnext', 'U18', 7),
  ('dante.williams@lanista.test',  'Eclipse Select SC',     'ecnl',    'U19', 8),
  ('kai.matagi@lanista.test',      'Seattle Sounders Academy','mlsnext','U18', 4),
  ('rodrigo.mendoza@lanista.test', 'Pateadores',            'mlsnext', 'U17', 9),
  ('aiden.park@lanista.test',      'De Anza Force',         'mlsnext', 'U18', 1),
  ('mateo.torres@lanista.test',    'Real Colorado',         'mlsnext', 'U19', 11),
  ('xavier.bell@lanista.test',     'Eclipse Select SC',     'ecnl',    'U17', 6),
  ('connor.murphy@lanista.test',   'Delco SC',              'mlsnext', 'U19', 2),
  ('jalen.carter@lanista.test',    'Solar Soccer Club',     'mlsnext', 'U18', 9),
  ('paulo.ferreira@lanista.test',  'Weston FC',             'mlsnext', 'U19', 3),
  ('nico.alvarez@lanista.test',    'Ohio Premier',          'ecrl',    'U17', 10),
  ('adrian.kowalski@lanista.test', 'Chicago Magic PSG',     'mlsnext', 'U18', 5),
  ('declan.obrien@lanista.test',   'Richmond Strikers',     'mlsnext', 'U19', 8),
  ('samuel.asante@lanista.test',   'Concorde Fire',         'mlsnext', 'U18', 7),
  ('victor.castillo@lanista.test', 'Lonestar SC',           'mlsnext', 'U17', 1),
  ('aria.thompson@lanista.test',   'Carolina FC',           'ecnl',    'U18', 10),
  ('camila.ortiz@lanista.test',    'Solar Soccer Club',     'ecnl',    'U19', 10),
  ('emma.walsh@lanista.test',      'Crossfire Premier',     'ecnl',    'U18', 1),
  ('priya.patel@lanista.test',     'Michigan Hawks',        'ecnl',    'U17', 8),
  ('jade.martin@lanista.test',     'Concorde Fire',         'ecnl',    'U19', 3),
  ('riley.thompson@lanista.test',  'Colorado Rush',         'ecnl',    'U18', 11),
  ('valentina.cruz@lanista.test',  'Real Colorado',         'ecnl',    'U18', 4),
  ('zara.hassan@lanista.test',     'Bethesda SC',           'ecnl',    'U19', 6),
  ('morgan.lee@lanista.test',      'Tampa Bay United',      'ecnl',    'U17', 9),
  ('elena.russo@lanista.test',     'De Anza Force',         'ecnl',    'U18', 7)
) AS v(email, club_name, league, age_group, jersey)
JOIN users u ON u.email = v.email
JOIN players p ON p.user_id = u.id
JOIN league_clubs lc ON lc.club_name = v.club_name AND lc.league = v.league
ON CONFLICT (player_id, club_id, season) DO NOTHING;

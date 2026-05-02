-- Migration 058: Full 2025-26 ECNL (Boys & Girls) and MLS NEXT event schedules.
-- Replaces the inaccurate placeholder data seeded in migration 030.
-- Source: theecnl.com/sports/ecnl-boys/schedule/2025-26
--         theecnl.com/sports/ecnl-girls/schedule/2025-26
--         mlssoccer.com/mlsnext (official announcements)

-- ─────────────────────────────────────────────────────────────
-- Step 1: Remove existing mlsnext and ecnl events (had wrong dates/venues)
-- ─────────────────────────────────────────────────────────────
DELETE FROM league_events WHERE league IN ('mlsnext', 'ecnl');


-- ─────────────────────────────────────────────────────────────
-- Step 2: MLS NEXT major events 2025-26 (4 national events)
-- ─────────────────────────────────────────────────────────────
INSERT INTO league_events (
  league, event_name, event_type,
  start_date, end_date,
  venue_name, city, state,
  gender, age_groups,
  description, website_url
) VALUES

  ('mlsnext', 'MLS NEXT Fest 2025', 'showcase',
   '2025-12-04', '2025-12-15',
   'Arizona Athletic Grounds & Reach 11 Sports Complex', 'Mesa', 'AZ',
   'both', ARRAY['U13','U14','U15','U16','U17','U18','U19'],
   'The largest youth soccer scouting and recruiting event in North America. 1,000+ teams from 200+ clubs competing in 1,850 matches. Provides qualification pathway to Generation adidas Cup.',
   'https://www.mlssoccer.com/mlsnext/events/fest/'),

  ('mlsnext', 'Generation adidas Cup 2026', 'showcase',
   '2026-03-27', '2026-04-04',
   'IMG Academy', 'Bradenton', 'FL',
   'both', ARRAY['U13','U14','U15','U16','U17','U18','U19'],
   'Prestigious tournament featuring MLS academies competing against top international club academies. Includes second edition of Girls Division in 2026.',
   'https://www.mlssoccer.com/mlsnext/events/generation-adidas-cup/'),

  ('mlsnext', 'MLS NEXT Flex 2026', 'playoff',
   '2026-04-23', '2026-04-28',
   'Toyota Soccer Complex', 'Frisco', 'TX',
   'both', ARRAY['U15','U16','U17','U18','U19'],
   'Final qualifying competition for MLS NEXT Cup. Group winners automatically qualify for MLS NEXT Cup.',
   'https://www.mlssoccer.com/mlsnext/schedule/all/'),

  ('mlsnext', 'MLS NEXT Cup 2026', 'championship',
   '2026-05-23', '2026-05-31',
   'Regional Athletics Complex / America First Field', 'Salt Lake City', 'UT',
   'both', ARRAY['U13','U14','U15','U16','U17','U18','U19'],
   'MLS NEXT Championship event. Championship matches at Real Salt Lake''s America First Field. Age groups U13-U19.',
   'https://www.mlssoccer.com/mlsnext/events/cup/');


-- ─────────────────────────────────────────────────────────────
-- Step 3: ECNL Boys national events 2025-26 (17 events)
-- Source: theecnl.com/sports/ecnl-boys/schedule/2025-26
-- ─────────────────────────────────────────────────────────────
INSERT INTO league_events (
  league, event_name, event_type,
  start_date, end_date,
  venue_name, city, state,
  gender, age_groups,
  description, website_url
) VALUES

  -- Aug 22-24: ECNL New Jersey (Boys) — Somerset, NJ
  ('ecnl', 'ECNL New Jersey 2025 (Boys)', 'showcase',
   '2025-08-22', '2025-08-24',
   'PDA Soccer Complex', 'Somerset', 'NJ',
   'male', ARRAY['U11','U12','U13','U14'],
   'ECNL Boys national showcase. Season opener event featuring Spotlight Games.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Sep 12-14: ECNL Atlanta (Boys) — Atlanta, GA
  ('ecnl', 'ECNL Atlanta 2025 (Boys)', 'showcase',
   '2025-09-12', '2025-09-14',
   NULL, 'Atlanta', 'GA',
   'male', ARRAY['U12','U13','U14'],
   'ECNL Boys national showcase. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Sep 12-14: ECNL St. Louis (Boys) — St. Louis, MO
  ('ecnl', 'ECNL St. Louis 2025 (Boys)', 'showcase',
   '2025-09-12', '2025-09-14',
   NULL, 'St. Louis', 'MO',
   'male', ARRAY['U13','U14'],
   'ECNL Boys national showcase. Spotlight Games format. Expanded to include Regional League teams this season.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Oct 11-13: ECNL San Diego (Boys) — San Diego, CA
  ('ecnl', 'ECNL San Diego 2025 (Boys)', 'showcase',
   '2025-10-11', '2025-10-13',
   'Surf Sports Park', 'San Diego', 'CA',
   'male', ARRAY['U13','U14','U15'],
   'ECNL Boys national showcase at Surf Sports Park. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Oct 17-19: ECNL North Carolina Fall (Boys) — Wilmington, NC
  ('ecnl', 'ECNL North Carolina Fall 2025 (Boys)', 'showcase',
   '2025-10-17', '2025-10-19',
   NULL, 'Wilmington', 'NC',
   'male', ARRAY['U11','U12','U13','U14'],
   'ECNL Boys national showcase. New younger boys event added for 2025-26 season. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Nov 21-23: ECNL Phoenix (Boys) — Phoenix, AZ
  ('ecnl', 'ECNL Phoenix 2025 (Boys)', 'showcase',
   '2025-11-21', '2025-11-23',
   NULL, 'Phoenix', 'AZ',
   'male', ARRAY['U16','U17','U18','U19'],
   'ECNL Boys national showcase. ECNL TV broadcast. Older age groups U16-U18/19.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Nov 28-30: ECNL West Coast Super Cup (Boys) — San Diego, CA
  ('ecnl', 'ECNL West Coast Super Cup 2025 (Boys)', 'showcase',
   '2025-11-28', '2025-11-30',
   NULL, 'San Diego', 'CA',
   'male', ARRAY['U14','U15','U16','U17','U18','U19'],
   'ECNL Boys West Coast Super Cup. ECNL TV broadcast. Elite competition format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Dec 5-7: ECNL South Carolina (Boys) — Greer, SC
  ('ecnl', 'ECNL South Carolina 2025 (Boys)', 'showcase',
   '2025-12-05', '2025-12-07',
   NULL, 'Greer', 'SC',
   'male', ARRAY['U16','U17','U18','U19'],
   'ECNL Boys national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Dec 12-14: ECNL East Coast & Central Super Cup (Boys) — Raleigh, NC
  ('ecnl', 'ECNL East Coast & Central Super Cup 2025 (Boys)', 'showcase',
   '2025-12-12', '2025-12-14',
   NULL, 'Raleigh', 'NC',
   'male', ARRAY['U14','U15','U16','U17','U18','U19'],
   'ECNL Boys East Coast & Central Super Cup. ECNL TV broadcast. Elite competition format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Jan 3-5: ECNL Florida (Boys) — Lakewood Ranch, FL
  ('ecnl', 'ECNL Florida 2026 (Boys)', 'showcase',
   '2026-01-03', '2026-01-05',
   NULL, 'Lakewood Ranch', 'FL',
   'male', ARRAY['U16','U17','U18','U19'],
   'ECNL Boys national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Jan 23-25: ECNL Las Vegas (Boys) — Las Vegas, NV
  ('ecnl', 'ECNL Las Vegas 2026 (Boys)', 'showcase',
   '2026-01-23', '2026-01-25',
   NULL, 'Las Vegas', 'NV',
   'male', ARRAY['U15','U16','U17','U18','U19'],
   'ECNL Boys national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Apr 10-12: ECNL Indianapolis (Boys) — Westfield, IN
  ('ecnl', 'ECNL Indianapolis 2026 (Boys)', 'showcase',
   '2026-04-10', '2026-04-12',
   'Grand Park', 'Westfield', 'IN',
   'male', ARRAY['U15','U16','U17','U18','U19'],
   'ECNL Boys major recruitable event at Grand Park, one of the most impressive facilities in the country. ECNL TV broadcast. New event added for 2025-26.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Apr 24-26: ECNL Texas (Boys) — Round Rock, TX
  ('ecnl', 'ECNL Texas 2026 (Boys)', 'showcase',
   '2026-04-24', '2026-04-26',
   NULL, 'Round Rock', 'TX',
   'male', ARRAY['U11','U12','U13','U14'],
   'ECNL Boys national showcase. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- May 8-10: ECNL North Carolina Spring (Boys) — Matthews, NC
  ('ecnl', 'ECNL North Carolina Spring 2026 (Boys)', 'showcase',
   '2026-05-08', '2026-05-10',
   NULL, 'Matthews', 'NC',
   'male', ARRAY['U13','U14'],
   'ECNL Boys national showcase. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- May 23-25: ECNL Virginia (Boys) — Midlothian, VA
  ('ecnl', 'ECNL Virginia 2026 (Boys)', 'showcase',
   '2026-05-23', '2026-05-25',
   NULL, 'Midlothian', 'VA',
   'male', ARRAY['U15','U16','U17'],
   'ECNL Boys national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Jun 25-Jul 2: ECNL Playoffs (Boys) — San Diego, CA
  ('ecnl', 'ECNL National Playoffs 2026 (Boys)', 'playoff',
   '2026-06-25', '2026-07-02',
   'Surf Sports Park', 'San Diego', 'CA',
   'male', ARRAY['U13','U14','U15','U16','U17','U18','U19'],
   'ECNL Boys National Playoffs. All age groups U13-U18/19.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26'),

  -- Jul 17-19: ECNL Finals (Boys) — Richmond, VA
  ('ecnl', 'ECNL National Finals 2026 (Boys)', 'championship',
   '2026-07-17', '2026-07-19',
   NULL, 'Richmond', 'VA',
   'male', ARRAY['U13','U14','U15','U16','U17'],
   'ECNL Boys National Finals for U13-U17.',
   'https://theecnl.com/sports/ecnl-boys/schedule/2025-26');


-- ─────────────────────────────────────────────────────────────
-- Step 4: ECNL Girls national events 2025-26 (14 events)
-- Source: theecnl.com/sports/ecnl-girls/schedule/2025-26
-- ─────────────────────────────────────────────────────────────
INSERT INTO league_events (
  league, event_name, event_type,
  start_date, end_date,
  venue_name, city, state,
  gender, age_groups,
  description, website_url
) VALUES

  -- Aug 22-24: ECNL New Jersey (Girls) — Somerset, NJ
  ('ecnl', 'ECNL New Jersey 2025 (Girls)', 'showcase',
   '2025-08-22', '2025-08-24',
   'PDA Soccer Complex', 'Somerset', 'NJ',
   'female', ARRAY['U11','U12','U13','U14'],
   'ECNL Girls national showcase. Season opener event featuring Spotlight Games.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Sep 12-14: ECNL St. Louis (Girls) — St. Louis, MO
  ('ecnl', 'ECNL St. Louis 2025 (Girls)', 'showcase',
   '2025-09-12', '2025-09-14',
   NULL, 'St. Louis', 'MO',
   'female', ARRAY['U13','U14'],
   'ECNL Girls national showcase. Spotlight Games format. Expanded to include Regional League teams this season.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Oct 11-13: ECNL San Diego (Girls) — Del Mar, CA
  ('ecnl', 'ECNL San Diego 2025 (Girls)', 'showcase',
   '2025-10-11', '2025-10-13',
   'Surf Sports Park', 'Del Mar', 'CA',
   'female', ARRAY['U12','U13','U14','U15'],
   'ECNL Girls national showcase at Surf Sports Park. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Oct 11-13: ECNL North Carolina Fall (Girls) — Wilmington, NC
  ('ecnl', 'ECNL North Carolina Fall 2025 (Girls)', 'showcase',
   '2025-10-11', '2025-10-13',
   NULL, 'Wilmington', 'NC',
   'female', ARRAY['U11','U12','U13','U14'],
   'ECNL Girls national showcase. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Nov 14-16: ECNL Phoenix Fall (Girls) — Phoenix, AZ
  ('ecnl', 'ECNL Phoenix Fall 2025 (Girls)', 'showcase',
   '2025-11-14', '2025-11-16',
   NULL, 'Phoenix', 'AZ',
   'female', ARRAY['U16','U17','U18','U19'],
   'ECNL Girls national showcase. ECNL TV broadcast. Older age groups U16-U18/19.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Dec 6-8: ECNL Kansas City (Girls) — Kansas City, MO
  ('ecnl', 'ECNL Kansas City 2025 (Girls)', 'showcase',
   '2025-12-06', '2025-12-08',
   NULL, 'Kansas City', 'MO',
   'female', ARRAY['U15','U16','U17','U18','U19'],
   'ECNL Girls national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Jan 10-12: ECNL Florida Winter (Girls) — Lakewood Ranch, FL
  ('ecnl', 'ECNL Florida Winter 2026 (Girls)', 'showcase',
   '2026-01-10', '2026-01-12',
   NULL, 'Lakewood Ranch', 'FL',
   'female', ARRAY['U16','U17','U18','U19'],
   'ECNL Girls national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Feb 14-16: ECNL Texas (Girls) — Dallas, TX
  ('ecnl', 'ECNL Texas 2026 (Girls)', 'showcase',
   '2026-02-14', '2026-02-16',
   NULL, 'Dallas', 'TX',
   'female', ARRAY['U14','U15','U16','U17','U18','U19'],
   'ECNL Girls national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Feb 27-Mar 1: ECNL Florida Spring (Girls) — Lakewood Ranch, FL
  ('ecnl', 'ECNL Florida Spring 2026 (Girls)', 'showcase',
   '2026-02-27', '2026-03-01',
   NULL, 'Lakewood Ranch', 'FL',
   'female', ARRAY['U15','U16','U17','U18','U19'],
   'ECNL Girls national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Mar 27-29: ECNL Phoenix Spring (Girls) — Phoenix, AZ
  ('ecnl', 'ECNL Phoenix Spring 2026 (Girls)', 'showcase',
   '2026-03-27', '2026-03-29',
   NULL, 'Phoenix', 'AZ',
   'female', ARRAY['U12','U13','U14','U15','U16','U17'],
   'ECNL Girls national showcase. ECNL TV broadcast. New California experiential event added this season.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- May 8-10: ECNL South Carolina (Girls) — Greer, SC
  ('ecnl', 'ECNL South Carolina 2026 (Girls)', 'showcase',
   '2026-05-08', '2026-05-10',
   NULL, 'Greer', 'SC',
   'female', ARRAY['U13','U14','U15'],
   'ECNL Girls national showcase. Spotlight Games format.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- May 30-Jun 1: ECNL North Carolina Spring (Girls) — Greensboro, NC
  ('ecnl', 'ECNL North Carolina Spring 2026 (Girls)', 'showcase',
   '2026-05-30', '2026-06-01',
   NULL, 'Greensboro', 'NC',
   'female', ARRAY['U15','U16','U17'],
   'ECNL Girls national showcase. ECNL TV broadcast.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Jun 24-27: ECNL Girls Finals U18/19 — St. Louis, MO
  ('ecnl', 'ECNL Girls Finals U18/19 2026', 'championship',
   '2026-06-24', '2026-06-27',
   NULL, 'St. Louis', 'MO',
   'female', ARRAY['U18','U19'],
   'ECNL Girls National Finals for U18/U19 age groups.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26'),

  -- Jul 11-18: ECNL Girls Playoffs & Finals — Seattle, WA
  ('ecnl', 'ECNL Girls Playoffs & Finals 2026', 'playoff',
   '2026-07-11', '2026-07-18',
   NULL, 'Seattle', 'WA',
   'female', ARRAY['U13','U14','U15','U16','U17'],
   'ECNL Girls National Playoffs & Finals for U13-U17.',
   'https://theecnl.com/sports/ecnl-girls/schedule/2025-26');

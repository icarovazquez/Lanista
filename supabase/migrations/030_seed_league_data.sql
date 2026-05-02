-- ── Seed: League Clubs ───────────────────────────────────────────────────────

-- MLS Next clubs (boys)
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  ('mlsnext', 'Philadelphia Union Academy',   'Philadelphia',   'PA', 'Northeast', 'male'),
  ('mlsnext', 'New York City FC Academy',     'New York',       'NY', 'Northeast', 'male'),
  ('mlsnext', 'New England Revolution Academy','Boston',        'MA', 'Northeast', 'male'),
  ('mlsnext', 'Chicago Fire Academy',         'Chicago',        'IL', 'Midwest',   'male'),
  ('mlsnext', 'Sporting Kansas City Academy', 'Kansas City',    'MO', 'Midwest',   'male'),
  ('mlsnext', 'Columbus Crew Academy',        'Columbus',       'OH', 'Midwest',   'male'),
  ('mlsnext', 'Atlanta United Academy',       'Atlanta',        'GA', 'South',     'male'),
  ('mlsnext', 'FC Dallas Academy',            'Dallas',         'TX', 'South',     'male'),
  ('mlsnext', 'Houston Dynamo Academy',       'Houston',        'TX', 'South',     'male'),
  ('mlsnext', 'LA Galaxy Academy',            'Los Angeles',    'CA', 'West',      'male'),
  ('mlsnext', 'Seattle Sounders Academy',     'Seattle',        'WA', 'West',      'male'),
  ('mlsnext', 'Portland Timbers Academy',     'Portland',       'OR', 'West',      'male'),
  ('mlsnext', 'San Jose Earthquakes Academy', 'San Jose',       'CA', 'West',      'male'),
  ('mlsnext', 'Real Salt Lake Academy',       'Salt Lake City', 'UT', 'West',      'male'),
  ('mlsnext', 'Colorado Rapids Academy',      'Denver',         'CO', 'West',      'male'),
  ('mlsnext', 'D.C. United Academy',          'Washington',     'DC', 'Northeast', 'male'),
  ('mlsnext', 'Orlando City Academy',         'Orlando',        'FL', 'South',     'male'),
  ('mlsnext', 'Inter Miami CF Academy',       'Miami',          'FL', 'South',     'male'),
  ('mlsnext', 'Toronto FC Academy',           'Toronto',        'ON', 'Northeast', 'male'),
  ('mlsnext', 'Vancouver Whitecaps Academy',  'Vancouver',      'BC', 'West',      'male');

-- ECNL clubs (girls)
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  ('ecnl', 'San Diego Surf',              'San Diego',      'CA', 'West',      'female'),
  ('ecnl', 'Solar Soccer Club',           'Dallas',         'TX', 'South',     'female'),
  ('ecnl', 'LAFC Slammers',               'Los Angeles',    'CA', 'West',      'female'),
  ('ecnl', 'Concorde Fire',               'Atlanta',        'GA', 'South',     'female'),
  ('ecnl', 'PDA (Player Development Academy)', 'Somerset',  'NJ', 'Northeast', 'female'),
  ('ecnl', 'Michigan Hawks',              'Ann Arbor',      'MI', 'Midwest',   'female'),
  ('ecnl', 'FC Dallas (Girls)',           'Dallas',         'TX', 'South',     'female'),
  ('ecnl', 'Colorado Rush',               'Denver',         'CO', 'West',      'female'),
  ('ecnl', 'Crossfire Premier',           'Seattle',        'WA', 'West',      'female'),
  ('ecnl', 'Bethesda SC',                 'Bethesda',       'MD', 'Northeast', 'female'),
  ('ecnl', 'FC Virginia',                 'Fredericksburg', 'VA', 'Northeast', 'female'),
  ('ecnl', 'Midwest United',              'Grand Rapids',   'MI', 'Midwest',   'female'),
  ('ecnl', 'Legends FC',                  'Murrieta',       'CA', 'West',      'female'),
  ('ecnl', 'Eclipse Select SC',           'Chicago',        'IL', 'Midwest',   'female'),
  ('ecnl', 'Tampa Bay United',            'Tampa',          'FL', 'South',     'female'),
  ('ecnl', 'Charlotte Independence',      'Charlotte',      'NC', 'South',     'female'),
  ('ecnl', 'Sporting Blue Valley',        'Overland Park',  'KS', 'Midwest',   'female'),
  ('ecnl', 'Utah Royals Academy',         'Salt Lake City', 'UT', 'West',      'female'),
  ('ecnl', 'New England Mutiny',          'Boston',         'MA', 'Northeast', 'female'),
  ('ecnl', 'Penn Fusion SA',              'Thorndale',      'PA', 'Northeast', 'female');

-- ECRL clubs (regional league, mixed)
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  ('ecrl', 'Ohio Premier',                'Columbus',       'OH', 'Midwest',   'both'),
  ('ecrl', 'Seacoast United',             'Portsmouth',     'NH', 'Northeast', 'both'),
  ('ecrl', 'GPS Massachusetts',           'Boston',         'MA', 'Northeast', 'both'),
  ('ecrl', 'Florida Krush',               'Orlando',        'FL', 'South',     'both'),
  ('ecrl', 'Weston FC',                   'Weston',         'FL', 'South',     'both'),
  ('ecrl', 'Dallas Texans',               'Dallas',         'TX', 'South',     'both'),
  ('ecrl', 'Tulsa SC',                    'Tulsa',          'OK', 'South',     'both'),
  ('ecrl', 'Sockers FC Illinois',         'Chicago',        'IL', 'Midwest',   'both'),
  ('ecrl', 'Pittsburgh Riverhounds Academy', 'Pittsburgh',  'PA', 'Northeast', 'both'),
  ('ecrl', 'Richmond Kickers Youth',      'Richmond',       'VA', 'Northeast', 'both');

-- ── Seed: League Events (Spring 2026) ────────────────────────────────────────

-- MLS Next events
INSERT INTO league_events (league, event_name, event_type, start_date, end_date, venue_name, city, state, gender, age_groups, description, website_url) VALUES
  (
    'mlsnext', 'MLS Next Spring Showcase 2026', 'showcase',
    '2026-03-20', '2026-03-23',
    'Legacy Sports Park', 'Mesa', 'AZ', 'male',
    ARRAY['U13','U14','U15','U16','U17','U18'],
    'Spring showcase featuring top MLS Next academies from across the country. College coaches attend to evaluate talent.',
    'https://mlsnextsoccer.com'
  ),
  (
    'mlsnext', 'MLS Next Fest 2026', 'showcase',
    '2026-04-22', '2026-04-27',
    'WakeMed Soccer Park', 'Cary', 'NC', 'male',
    ARRAY['U13','U14','U15','U16','U17','U18','U19'],
    'MLS Next''s flagship annual event. The premier showcase for top academy players in the country. Heavily attended by college coaches at all divisions.',
    'https://mlsnextsoccer.com'
  ),
  (
    'mlsnext', 'MLS Next Spring Playoffs 2026', 'playoff',
    '2026-05-14', '2026-05-18',
    'IMG Academy', 'Bradenton', 'FL', 'male',
    ARRAY['U15','U16','U17','U18','U19'],
    'MLS Next Spring playoff rounds determining regional champions.',
    'https://mlsnextsoccer.com'
  ),
  (
    'mlsnext', 'MLS Next National Championships 2026', 'championship',
    '2026-06-25', '2026-07-02',
    'Grand Park Sports Campus', 'Westfield', 'IN', 'male',
    ARRAY['U13','U14','U15','U16','U17','U18','U19'],
    'MLS Next National Championships — the culminating event of the season for top academies.',
    'https://mlsnextsoccer.com'
  );

-- ECNL events
INSERT INTO league_events (league, event_name, event_type, start_date, end_date, venue_name, city, state, gender, age_groups, description, website_url) VALUES
  (
    'ecnl', 'ECNL Phoenix Showcase 2026', 'showcase',
    '2026-03-19', '2026-03-22',
    'Reach 11 Sports Complex', 'Phoenix', 'AZ', 'female',
    ARRAY['U14','U15','U16','U17','U18','U19'],
    'One of ECNL''s major spring showcases. Heavily attended by college coaches recruiting for women''s programs at all divisions.',
    'https://ecnlsoccer.com'
  ),
  (
    'ecnl', 'ECNL San Diego Showcase 2026', 'showcase',
    '2026-04-02', '2026-04-05',
    'Surf Cup Sports Park', 'San Diego', 'CA', 'female',
    ARRAY['U13','U14','U15','U16','U17','U18','U19'],
    'Premier West Coast ECNL showcase. Top college programs send coaches specifically for this event.',
    'https://ecnlsoccer.com'
  ),
  (
    'ecnl', 'ECNL Playoffs 2026', 'playoff',
    '2026-05-07', '2026-05-10',
    'Various Venues', 'Multiple Cities', 'TBD', 'female',
    ARRAY['U14','U15','U16','U17','U18','U19'],
    'ECNL regional playoff rounds across multiple host sites.',
    'https://ecnlsoccer.com'
  ),
  (
    'ecnl', 'ECNL National Championships 2026', 'championship',
    '2026-06-26', '2026-07-02',
    'WakeMed Soccer Park', 'Cary', 'NC', 'female',
    ARRAY['U14','U15','U16','U17','U18','U19'],
    'ECNL National Championships — the season finale for top ECNL clubs. Elite college recruiting environment.',
    'https://ecnlsoccer.com'
  ),
  (
    'ecnl', 'ECNL Boys Phoenix Showcase 2026', 'showcase',
    '2026-03-19', '2026-03-22',
    'Reach 11 Sports Complex', 'Phoenix', 'AZ', 'male',
    ARRAY['U14','U15','U16','U17','U18','U19'],
    'ECNL Boys spring showcase in Phoenix. Coaches from all divisions attend.',
    'https://ecnlsoccer.com'
  ),
  (
    'ecnl', 'ECNL Boys San Diego Showcase 2026', 'showcase',
    '2026-04-02', '2026-04-05',
    'Surf Cup Sports Park', 'San Diego', 'CA', 'male',
    ARRAY['U14','U15','U16','U17','U18','U19'],
    'ECNL Boys spring showcase in San Diego.',
    'https://ecnlsoccer.com'
  );

-- ECRL events
INSERT INTO league_events (league, event_name, event_type, start_date, end_date, venue_name, city, state, gender, age_groups, description, website_url) VALUES
  (
    'ecrl', 'ECRL Midwest Regional Showcase 2026', 'showcase',
    '2026-04-24', '2026-04-27',
    'Obetz Fortress Sports Complex', 'Columbus', 'OH', 'both',
    ARRAY['U14','U15','U16','U17','U18'],
    'ECRL regional showcase for Midwest clubs. D2 and D3 college coaches well represented.',
    'https://ecnlrl.com'
  ),
  (
    'ecrl', 'ECRL Southeast Regional Showcase 2026', 'showcase',
    '2026-05-08', '2026-05-11',
    'Starr''s Mill Soccer Complex', 'Atlanta', 'GA', 'both',
    ARRAY['U14','U15','U16','U17','U18'],
    'ECRL Southeast regional showcase. Strong D2 and D3 recruiting environment.',
    'https://ecnlrl.com'
  ),
  (
    'ecrl', 'ECRL Northeast Regional Showcase 2026', 'showcase',
    '2026-04-17', '2026-04-20',
    'Reach Soccer Complex', 'Fredericksburg', 'VA', 'both',
    ARRAY['U14','U15','U16','U17','U18'],
    'ECRL Northeast regional showcase.',
    'https://ecnlrl.com'
  ),
  (
    'ecrl', 'ECRL National Playoffs 2026', 'playoff',
    '2026-05-22', '2026-05-25',
    'Grand Park Sports Campus', 'Westfield', 'IN', 'both',
    ARRAY['U14','U15','U16','U17','U18'],
    'ECRL National Playoff rounds.',
    'https://ecnlrl.com'
  );

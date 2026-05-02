-- ── Seed: MLS NEXT Non-Academy Clubs ─────────────────────────────────────────
-- MLS NEXT includes ~200+ independent clubs alongside the MLS pro academies.
-- Organized by region.

-- ── Northeast ──────────────────────────────────────────────────────────────────
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  -- Connecticut
  ('mlsnext', 'Connecticut FC',              'Glastonbury',     'CT', 'Northeast', 'male'),
  ('mlsnext', 'South Windsor FC',            'South Windsor',   'CT', 'Northeast', 'male'),
  ('mlsnext', 'GPS Connecticut',             'Milford',         'CT', 'Northeast', 'male'),
  -- New York
  ('mlsnext', 'Long Island SC',              'Hauppauge',       'NY', 'Northeast', 'male'),
  ('mlsnext', 'Empire Revolution',           'Middletown',      'NY', 'Northeast', 'male'),
  ('mlsnext', 'NY Surf',                     'Melville',        'NY', 'Northeast', 'male'),
  ('mlsnext', 'Western NY Flash',            'Buffalo',         'NY', 'Northeast', 'male'),
  ('mlsnext', 'Capital Area SC',             'Albany',          'NY', 'Northeast', 'male'),
  -- New Jersey
  ('mlsnext', 'Match Fit Chelsea',           'Hoboken',         'NJ', 'Northeast', 'male'),
  ('mlsnext', 'NJ Copa FC',                  'Union',           'NJ', 'Northeast', 'male'),
  ('mlsnext', 'PDA',                         'Somerset',        'NJ', 'Northeast', 'male'),
  ('mlsnext', 'Ironbound SC',                'Newark',          'NJ', 'Northeast', 'male'),
  -- Pennsylvania
  ('mlsnext', 'Delco SC',                    'Springfield',     'PA', 'Northeast', 'male'),
  ('mlsnext', 'FC Bucks',                    'Fairless Hills',  'PA', 'Northeast', 'male'),
  ('mlsnext', 'Lehigh Valley United',        'Bethlehem',       'PA', 'Northeast', 'male'),
  ('mlsnext', 'Penn Fusion SA',              'Thorndale',       'PA', 'Northeast', 'male'),
  ('mlsnext', 'YMS (York Mariner SC)',       'York',            'PA', 'Northeast', 'male'),
  ('mlsnext', 'Pittsburgh Riverhounds',      'Pittsburgh',      'PA', 'Northeast', 'male'),
  -- Massachusetts / New England
  ('mlsnext', 'GPS Massachusetts',           'Dedham',          'MA', 'Northeast', 'male'),
  ('mlsnext', 'FC Boston',                   'Lexington',       'MA', 'Northeast', 'male'),
  ('mlsnext', 'Northeast United FC',         'Worcester',       'MA', 'Northeast', 'male'),
  ('mlsnext', 'Seacoast United',             'Portsmouth',      'NH', 'Northeast', 'male'),
  ('mlsnext', 'Maine United',                'Portland',        'ME', 'Northeast', 'male'),
  -- Maryland / DC / Virginia
  ('mlsnext', 'Bethesda SC',                 'Bethesda',        'MD', 'Northeast', 'male'),
  ('mlsnext', 'Maryland United FC',          'Rockville',       'MD', 'Northeast', 'male'),
  ('mlsnext', 'Baltimore Armour',            'Baltimore',       'MD', 'Northeast', 'male'),
  ('mlsnext', 'Richmond Strikers',           'Richmond',        'VA', 'Northeast', 'male'),
  ('mlsnext', 'Virginia Rush',               'Sterling',        'VA', 'Northeast', 'male'),
  ('mlsnext', 'McLean Youth Soccer',         'McLean',          'VA', 'Northeast', 'male'),
  ('mlsnext', 'FC Virginia',                 'Fredericksburg',  'VA', 'Northeast', 'male'),
  ('mlsnext', 'Virginia Beach United',       'Virginia Beach',  'VA', 'Northeast', 'male');

-- ── Midwest ────────────────────────────────────────────────────────────────────
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  -- Illinois
  ('mlsnext', 'Eclipse Select SC',           'Oswego',          'IL', 'Midwest',   'male'),
  ('mlsnext', 'Chicago Magic PSG',           'Oswego',          'IL', 'Midwest',   'male'),
  ('mlsnext', 'Sockers FC Illinois',         'Rockford',        'IL', 'Midwest',   'male'),
  ('mlsnext', 'FC United of Chicago',        'Chicago',         'IL', 'Midwest',   'male'),
  -- Wisconsin
  ('mlsnext', 'FC Wisconsin Pride',          'Madison',         'WI', 'Midwest',   'male'),
  ('mlsnext', 'Milwaukee Bavarians',         'Milwaukee',       'WI', 'Midwest',   'male'),
  -- Minnesota
  ('mlsnext', 'Minnesota Thunder Academy',   'Minneapolis',     'MN', 'Midwest',   'male'),
  ('mlsnext', 'Shattuck-St. Mary''s',        'Faribault',       'MN', 'Midwest',   'male'),
  ('mlsnext', 'Minnesota Twins Academy',     'Eden Prairie',    'MN', 'Midwest',   'male'),
  -- Indiana
  ('mlsnext', 'Indiana Fire Juniors',        'Indianapolis',    'IN', 'Midwest',   'male'),
  ('mlsnext', 'FC Indiana',                  'Indianapolis',    'IN', 'Midwest',   'male'),
  ('mlsnext', 'Fort Wayne FC',               'Fort Wayne',      'IN', 'Midwest',   'male'),
  -- Ohio
  ('mlsnext', 'Cincinnati United Premier',   'Cincinnati',      'OH', 'Midwest',   'male'),
  ('mlsnext', 'Ohio Legacy FC',              'Columbus',        'OH', 'Midwest',   'male'),
  ('mlsnext', 'Ohio Premier',                'Columbus',        'OH', 'Midwest',   'male'),
  ('mlsnext', 'Cleveland Force SC',          'Cleveland',       'OH', 'Midwest',   'male'),
  ('mlsnext', 'Dayton Dutch Lions',          'Dayton',          'OH', 'Midwest',   'male'),
  -- Michigan
  ('mlsnext', 'Michigan Hawks',              'Ann Arbor',       'MI', 'Midwest',   'male'),
  ('mlsnext', 'Michigan Wolves',             'Troy',            'MI', 'Midwest',   'male'),
  ('mlsnext', 'Detroit City FC Academy',     'Detroit',         'MI', 'Midwest',   'male'),
  -- Missouri / Kansas
  ('mlsnext', 'St. Louis Scott Gallagher',   'St. Louis',       'MO', 'Midwest',   'male'),
  ('mlsnext', 'Sporting Blue Valley',        'Overland Park',   'KS', 'Midwest',   'male'),
  ('mlsnext', 'FC Kansas City',              'Kansas City',     'MO', 'Midwest',   'male'),
  -- Iowa / Nebraska / Other Midwest
  ('mlsnext', 'Des Moines Menace Juniors',   'Des Moines',      'IA', 'Midwest',   'male'),
  ('mlsnext', 'Nebraska Rush',               'Omaha',           'NE', 'Midwest',   'male'),
  ('mlsnext', 'Louisville City FC Academy',  'Louisville',      'KY', 'Midwest',   'male');

-- ── South ─────────────────────────────────────────────────────────────────────
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  -- Texas
  ('mlsnext', 'Lonestar SC',                 'Austin',          'TX', 'South',     'male'),
  ('mlsnext', 'Solar Soccer Club',           'Dallas',          'TX', 'South',     'male'),
  ('mlsnext', 'Spirit of Texas',             'Coppell',         'TX', 'South',     'male'),
  ('mlsnext', 'Chargers SC',                 'Fort Worth',      'TX', 'South',     'male'),
  ('mlsnext', 'BVB Academy',                 'San Antonio',     'TX', 'South',     'male'),
  ('mlsnext', 'San Antonio FC Academy',      'San Antonio',     'TX', 'South',     'male'),
  ('mlsnext', 'HFC (Houston FC)',            'Houston',         'TX', 'South',     'male'),
  ('mlsnext', 'Barca Residency Academy TX',  'Dallas',          'TX', 'South',     'male'),
  ('mlsnext', 'West Texas FC',               'Lubbock',         'TX', 'South',     'male'),
  -- Oklahoma / Arkansas
  ('mlsnext', 'Oklahoma Energy FC',          'Oklahoma City',   'OK', 'South',     'male'),
  ('mlsnext', 'Tulsa SC',                    'Tulsa',           'OK', 'South',     'male'),
  ('mlsnext', 'Arkansas Comets',             'Little Rock',     'AR', 'South',     'male'),
  -- Tennessee / Kentucky
  ('mlsnext', 'Tennessee SC',                'Brentwood',       'TN', 'South',     'male'),
  ('mlsnext', 'Memphis 901 FC Academy',      'Memphis',         'TN', 'South',     'male'),
  ('mlsnext', 'Nashville SC Academy',        'Nashville',       'TN', 'South',     'male'),
  -- North Carolina
  ('mlsnext', 'Carolina FC',                 'Cary',            'NC', 'South',     'male'),
  ('mlsnext', 'Charlotte Soccer Academy',    'Charlotte',       'NC', 'South',     'male'),
  ('mlsnext', 'Wake FC',                     'Raleigh',         'NC', 'South',     'male'),
  ('mlsnext', 'Greensboro United FC',        'Greensboro',      'NC', 'South',     'male'),
  -- Georgia / Alabama
  ('mlsnext', 'Concorde Fire',               'Atlanta',         'GA', 'South',     'male'),
  ('mlsnext', 'Georgia United FC',           'Marietta',        'GA', 'South',     'male'),
  ('mlsnext', 'Alabama FC',                  'Birmingham',      'AL', 'South',     'male'),
  -- South Carolina
  ('mlsnext', 'Carolina Elite Soccer Academy', 'Irmo',          'SC', 'South',     'male'),
  -- Florida
  ('mlsnext', 'Tampa Bay United',            'Tampa',           'FL', 'South',     'male'),
  ('mlsnext', 'Miami Rush Kendall SC',       'Kendall',         'FL', 'South',     'male'),
  ('mlsnext', 'Space Coast United',          'Melbourne',       'FL', 'South',     'male'),
  ('mlsnext', 'Jacksonville Armada Academy', 'Jacksonville',    'FL', 'South',     'male'),
  ('mlsnext', 'Weston FC',                   'Weston',          'FL', 'South',     'male'),
  ('mlsnext', 'South Florida FC',            'Boca Raton',      'FL', 'South',     'male'),
  ('mlsnext', 'Florida West FC',             'Fort Myers',      'FL', 'South',     'male'),
  -- Louisiana / Mississippi
  ('mlsnext', 'New Orleans Jesters Academy', 'New Orleans',     'LA', 'South',     'male');

-- ── West ──────────────────────────────────────────────────────────────────────
INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  -- California — Northern
  ('mlsnext', 'Bay Area Surf',               'Pleasanton',      'CA', 'West',      'male'),
  ('mlsnext', 'Pateadores',                  'Mission Hills',   'CA', 'West',      'male'),
  ('mlsnext', 'De Anza Force',               'Cupertino',       'CA', 'West',      'male'),
  ('mlsnext', 'Lamorinda SC',                'Lafayette',       'CA', 'West',      'male'),
  ('mlsnext', 'Placer United',               'Roseville',       'CA', 'West',      'male'),
  ('mlsnext', 'FC Golden State Force',       'Stockton',        'CA', 'West',      'male'),
  ('mlsnext', 'Napa Valley FC',              'Napa',            'CA', 'West',      'male'),
  ('mlsnext', 'Sporting Santa Cruz',         'Santa Cruz',      'CA', 'West',      'male'),
  -- California — Southern
  ('mlsnext', 'West Coast FC',               'Laguna Niguel',   'CA', 'West',      'male'),
  ('mlsnext', 'Ajax America',                'Gardena',         'CA', 'West',      'male'),
  ('mlsnext', 'Sporting International',      'Westminster',     'CA', 'West',      'male'),
  ('mlsnext', 'Cal United Strikers',         'Laguna Hills',    'CA', 'West',      'male'),
  ('mlsnext', 'LAFC Slammers',               'Mission Viejo',   'CA', 'West',      'male'),
  ('mlsnext', 'Pacific Coast SC',            'Costa Mesa',      'CA', 'West',      'male'),
  ('mlsnext', 'California Thorns',           'Brentwood',       'CA', 'West',      'male'),
  ('mlsnext', 'Barca Residency Academy CA',  'Phoenix',         'AZ', 'West',      'male'),
  -- California — San Diego
  ('mlsnext', 'Albion SC',                   'San Diego',       'CA', 'West',      'male'),
  ('mlsnext', 'Surf Soccer Club',            'San Diego',       'CA', 'West',      'male'),
  ('mlsnext', 'San Diego SC Academy',        'San Diego',       'CA', 'West',      'male'),
  ('mlsnext', 'So Cal Blues',                'San Clemente',    'CA', 'West',      'male'),
  -- Washington / Oregon / Idaho
  ('mlsnext', 'Eastside FC',                 'Redmond',         'WA', 'West',      'male'),
  ('mlsnext', 'Crossfire Premier',           'Redmond',         'WA', 'West',      'male'),
  ('mlsnext', 'Oly Town FC',                 'Olympia',         'WA', 'West',      'male'),
  ('mlsnext', 'Timberline FC',               'Boise',           'ID', 'West',      'male'),
  -- Utah / Nevada
  ('mlsnext', 'Utah Avalanche',              'St. George',      'UT', 'West',      'male'),
  ('mlsnext', 'Utah Valley FC',              'Provo',           'UT', 'West',      'male'),
  ('mlsnext', 'Nevada Fury',                 'Las Vegas',       'NV', 'West',      'male'),
  ('mlsnext', 'Reno Premier FC',             'Reno',            'NV', 'West',      'male'),
  -- Colorado
  ('mlsnext', 'Real Colorado',               'Thornton',        'CO', 'West',      'male'),
  ('mlsnext', 'Colorado Storm',              'Parker',          'CO', 'West',      'male'),
  ('mlsnext', 'Colorado Springs United',     'Colorado Springs','CO', 'West',      'male'),
  -- Arizona / New Mexico
  ('mlsnext', 'Arizona Arsenal',             'Scottsdale',      'AZ', 'West',      'male'),
  ('mlsnext', 'Arizona Arsenal South',       'Tucson',          'AZ', 'West',      'male'),
  ('mlsnext', 'New Mexico Rush',             'Albuquerque',     'NM', 'West',      'male'),
  -- Montana / Wyoming / Alaska
  ('mlsnext', 'Missoula Strikers',           'Missoula',        'MT', 'West',      'male');

-- ── Additional ECNL Girls Clubs ────────────────────────────────────────────────
-- Expanding the initial 20 with more programs across the country

INSERT INTO league_clubs (league, club_name, city, state, region, gender) VALUES
  -- Northeast
  ('ecnl', 'Connecticut FC',                 'Glastonbury',     'CT', 'Northeast', 'female'),
  ('ecnl', 'Long Island SC',                 'Hauppauge',       'NY', 'Northeast', 'female'),
  ('ecnl', 'NJ Copa FC',                     'Union',           'NJ', 'Northeast', 'female'),
  ('ecnl', 'Virginia Rush',                  'Sterling',        'VA', 'Northeast', 'female'),
  ('ecnl', 'Richmond Strikers',              'Richmond',        'VA', 'Northeast', 'female'),
  ('ecnl', 'GPS Massachusetts',              'Dedham',          'MA', 'Northeast', 'female'),
  ('ecnl', 'Seacoast United',                'Portsmouth',      'NH', 'Northeast', 'female'),
  ('ecnl', 'Maryland United FC',             'Rockville',       'MD', 'Northeast', 'female'),
  -- Midwest
  ('ecnl', 'Chicago Magic PSG',              'Oswego',          'IL', 'Midwest',   'female'),
  ('ecnl', 'FC Wisconsin Pride',             'Madison',         'WI', 'Midwest',   'female'),
  ('ecnl', 'Minnesota Thunder Academy',      'Minneapolis',     'MN', 'Midwest',   'female'),
  ('ecnl', 'Ohio Premier',                   'Columbus',        'OH', 'Midwest',   'female'),
  ('ecnl', 'Michigan Wolves',                'Troy',            'MI', 'Midwest',   'female'),
  ('ecnl', 'FC Indiana',                     'Indianapolis',    'IN', 'Midwest',   'female'),
  ('ecnl', 'St. Louis Scott Gallagher',      'St. Louis',       'MO', 'Midwest',   'female'),
  -- South
  ('ecnl', 'Lonestar SC',                    'Austin',          'TX', 'South',     'female'),
  ('ecnl', 'Carolina FC',                    'Cary',            'NC', 'South',     'female'),
  ('ecnl', 'Tennessee SC',                   'Brentwood',       'TN', 'South',     'female'),
  ('ecnl', 'Weston FC',                      'Weston',          'FL', 'South',     'female'),
  ('ecnl', 'Space Coast United',             'Melbourne',       'FL', 'South',     'female'),
  -- West
  ('ecnl', 'Bay Area Surf',                  'Pleasanton',      'CA', 'West',      'female'),
  ('ecnl', 'De Anza Force',                  'Cupertino',       'CA', 'West',      'female'),
  ('ecnl', 'West Coast FC',                  'Laguna Niguel',   'CA', 'West',      'female'),
  ('ecnl', 'Albion SC',                      'San Diego',       'CA', 'West',      'female'),
  ('ecnl', 'Real Colorado',                  'Thornton',        'CO', 'West',      'female'),
  ('ecnl', 'Eastside FC',                    'Redmond',         'WA', 'West',      'female'),
  ('ecnl', 'Arizona Arsenal',                'Scottsdale',      'AZ', 'West',      'female');

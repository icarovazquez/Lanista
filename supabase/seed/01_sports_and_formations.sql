-- Seed: Soccer sport
INSERT INTO sports (id, name, name_es) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Soccer', 'Fútbol');

-- Seed: Soccer formations
INSERT INTO formations (id, sport_id, name, description, description_es) VALUES
  ('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440001', '4-3-3', 'Four defenders, three midfielders, three forwards', 'Cuatro defensas, tres centrocampistas, tres delanteros'),
  ('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440001', '4-2-3-1', 'Four defenders, two holding midfielders, three attacking midfielders, one striker', 'Cuatro defensas, dos mediocampistas defensivos, tres mediocampistas ofensivos, un delantero'),
  ('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440001', '3-4-3', 'Three defenders, four midfielders, three forwards', 'Tres defensas, cuatro centrocampistas, tres delanteros'),
  ('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440001', '4-4-2', 'Four defenders, four midfielders, two forwards', 'Cuatro defensas, cuatro centrocampistas, dos delanteros'),
  ('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440001', '3-5-2', 'Three defenders, five midfielders, two forwards', 'Tres defensas, cinco centrocampistas, dos delanteros');

-- Seed: Soccer positions (general, not formation-specific)
INSERT INTO positions (id, sport_id, name, name_es, abbreviation, position_type) VALUES
  ('550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440001', 'Goalkeeper', 'Portero', 'GK', 'goalkeeper'),
  ('550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440001', 'Center Back', 'Defensa Central', 'CB', 'defender'),
  ('550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440001', 'Left Back', 'Lateral Izquierdo', 'LB', 'defender'),
  ('550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440001', 'Right Back', 'Lateral Derecho', 'RB', 'defender'),
  ('550e8400-e29b-41d4-a716-446655440024', '550e8400-e29b-41d4-a716-446655440001', 'Defensive Midfielder', 'Mediocampista Defensivo', 'CDM', 'midfielder'),
  ('550e8400-e29b-41d4-a716-446655440025', '550e8400-e29b-41d4-a716-446655440001', 'Central Midfielder', 'Mediocampista Central', 'CM', 'midfielder'),
  ('550e8400-e29b-41d4-a716-446655440026', '550e8400-e29b-41d4-a716-446655440001', 'Attacking Midfielder', 'Mediocampista Ofensivo', 'CAM', 'midfielder'),
  ('550e8400-e29b-41d4-a716-446655440027', '550e8400-e29b-41d4-a716-446655440001', 'Left Winger', 'Extremo Izquierdo', 'LW', 'forward'),
  ('550e8400-e29b-41d4-a716-446655440028', '550e8400-e29b-41d4-a716-446655440001', 'Right Winger', 'Extremo Derecho', 'RW', 'forward'),
  ('550e8400-e29b-41d4-a716-446655440029', '550e8400-e29b-41d4-a716-446655440001', 'Striker', 'Delantero Centro', 'ST', 'forward'),
  ('550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440001', 'False 9', 'Falso 9', 'F9', 'forward'),
  ('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440001', 'Wing Back', 'Carrilero', 'WB', 'defender');

-- Seed: Divisions
INSERT INTO divisions (id, name, name_es, scholarship_type) VALUES
  ('550e8400-e29b-41d4-a716-446655440040', 'NCAA Division I', 'NCAA División I', 'equivalency'),
  ('550e8400-e29b-41d4-a716-446655440041', 'NCAA Division II', 'NCAA División II', 'equivalency'),
  ('550e8400-e29b-41d4-a716-446655440042', 'NCAA Division III', 'NCAA División III', 'none'),
  ('550e8400-e29b-41d4-a716-446655440043', 'NAIA', 'NAIA', 'equivalency'),
  ('550e8400-e29b-41d4-a716-446655440044', 'Junior College', 'Colegio Comunitario', 'equivalency');

-- Seed: Youth leagues
INSERT INTO leagues (id, sport_id, name, name_es, gender, level) VALUES
  ('550e8400-e29b-41d4-a716-446655440050', '550e8400-e29b-41d4-a716-446655440001', 'MLS Next', 'MLS Next', 'male', 1),
  ('550e8400-e29b-41d4-a716-446655440051', '550e8400-e29b-41d4-a716-446655440001', 'ECNL Boys', 'ECNL Masculino', 'male', 2),
  ('550e8400-e29b-41d4-a716-446655440052', '550e8400-e29b-41d4-a716-446655440001', 'ECNL Girls', 'ECNL Femenino', 'female', 1),
  ('550e8400-e29b-41d4-a716-446655440053', '550e8400-e29b-41d4-a716-446655440001', 'Girls Academy', 'Girls Academy', 'female', 2),
  ('550e8400-e29b-41d4-a716-446655440054', '550e8400-e29b-41d4-a716-446655440001', 'ECRL', 'ECRL', 'male', 3),
  ('550e8400-e29b-41d4-a716-446655440055', '550e8400-e29b-41d4-a716-446655440001', 'NPL', 'NPL', 'male', 4);

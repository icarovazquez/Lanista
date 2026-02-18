// Static reference data for player profile setup.
// Real data will be fetched from Supabase reference tables.

class GradeLevel {
  final String id;
  final String label;
  final String labelEs;
  const GradeLevel(this.id, this.label, this.labelEs);
}

class Position {
  final String id;
  final String name;
  final String abbreviation;
  const Position(this.id, this.name, this.abbreviation);
}

class Formation {
  final String id;
  final String name;
  const Formation(this.id, this.name);
}

class PlayerProfileData {
  static const List<GradeLevel> gradeLevels = [
    GradeLevel('6', '6th Grade', '6to Grado'),
    GradeLevel('7', '7th Grade', '7mo Grado'),
    GradeLevel('8', '8th Grade', '8vo Grado'),
    GradeLevel('9', '9th Grade (Freshman)', '9no Grado (Freshman)'),
    GradeLevel('10', '10th Grade (Sophomore)', '10mo Grado (Sophomore)'),
    GradeLevel('11', '11th Grade (Junior)', '11mo Grado (Junior)'),
    GradeLevel('12', '12th Grade (Senior)', '12mo Grado (Senior)'),
  ];

  static const List<Position> positions = [
    Position('gk', 'Goalkeeper', 'GK'),
    Position('rb', 'Right Back', 'RB'),
    Position('cb', 'Center Back', 'CB'),
    Position('lb', 'Left Back', 'LB'),
    Position('cdm', 'Defensive Midfielder', 'CDM'),
    Position('cm', 'Central Midfielder', 'CM'),
    Position('cam', 'Attacking Midfielder', 'CAM'),
    Position('rm', 'Right Midfielder', 'RM'),
    Position('lm', 'Left Midfielder', 'LM'),
    Position('rw', 'Right Winger', 'RW'),
    Position('lw', 'Left Winger', 'LW'),
    Position('st', 'Striker / Forward', 'ST'),
    Position('cf', 'Center Forward', 'CF'),
    Position('f9', 'False 9', 'F9'),
  ];

  static const List<String> divisions = [
    'NCAA Division I',
    'NCAA Division II',
    'NCAA Division III',
    'NAIA',
    'NJCAA (Junior College)',
    'Open — Any Division',
  ];

  static const List<String> leagues = [
    'MLS NEXT',
    'ECNL Boys',
    'ECNL Girls',
    'Girls Academy',
    'ECRL',
    'National Premier League (NPL)',
    'State League (High School)',
    'Club — Regional',
    'Other',
  ];

  static const List<String> footPreferences = [
    'Right',
    'Left',
    'Both (Ambidextrous)',
  ];

  static const List<String> heightRanges = [
    'Under 5\'0"',
    '5\'0" – 5\'3"',
    '5\'4" – 5\'7"',
    '5\'8" – 5\'11"',
    '6\'0" – 6\'2"',
    '6\'3"+',
  ];

  static const List<String> gpaRanges = [
    '4.0 (Unweighted)',
    '3.5 – 3.9',
    '3.0 – 3.4',
    '2.5 – 2.9',
    '2.0 – 2.4',
    'Prefer not to say',
  ];

  static const List<String> targetTimelines = [
    'Class of 2025',
    'Class of 2026',
    'Class of 2027',
    'Class of 2028',
    'Class of 2029',
    'Class of 2030+',
  ];
}

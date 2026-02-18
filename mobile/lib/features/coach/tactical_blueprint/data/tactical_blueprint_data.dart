// Static reference data for the coach tactical blueprint form.

class FormationInfo {
  final String id;
  final String name;
  final String description;
  final List<BlueprintPosition> positions;

  const FormationInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.positions,
  });
}

class BlueprintPosition {
  final String positionId;
  final String positionName;
  final String abbreviation;
  // Normalized coordinates for a vertical soccer field layout
  // (0,0) = top-left, (1,1) = bottom-right
  final double x;
  final double y;

  const BlueprintPosition({
    required this.positionId,
    required this.positionName,
    required this.abbreviation,
    required this.x,
    required this.y,
  });
}

class PlayerQuality {
  final String id;
  final String label;
  final String category;

  const PlayerQuality(this.id, this.label, this.category);
}

class TacticalBlueprintData {
  static const List<FormationInfo> formations = [
    FormationInfo(
      id: '4-3-3',
      name: '4-3-3',
      description: 'High pressing, wide attacking, fluid midfield triangle',
      positions: [
        BlueprintPosition(positionId: 'gk', positionName: 'Goalkeeper', abbreviation: 'GK', x: 0.5, y: 0.92),
        BlueprintPosition(positionId: 'rb', positionName: 'Right Back', abbreviation: 'RB', x: 0.82, y: 0.75),
        BlueprintPosition(positionId: 'rcb', positionName: 'Right Center Back', abbreviation: 'RCB', x: 0.65, y: 0.78),
        BlueprintPosition(positionId: 'lcb', positionName: 'Left Center Back', abbreviation: 'LCB', x: 0.35, y: 0.78),
        BlueprintPosition(positionId: 'lb', positionName: 'Left Back', abbreviation: 'LB', x: 0.18, y: 0.75),
        BlueprintPosition(positionId: 'rcm', positionName: 'Right CM', abbreviation: 'RCM', x: 0.72, y: 0.54),
        BlueprintPosition(positionId: 'cm', positionName: 'Central CM', abbreviation: 'CM', x: 0.5, y: 0.48),
        BlueprintPosition(positionId: 'lcm', positionName: 'Left CM', abbreviation: 'LCM', x: 0.28, y: 0.54),
        BlueprintPosition(positionId: 'rw', positionName: 'Right Winger', abbreviation: 'RW', x: 0.82, y: 0.28),
        BlueprintPosition(positionId: 'st', positionName: 'Striker', abbreviation: 'ST', x: 0.5, y: 0.18),
        BlueprintPosition(positionId: 'lw', positionName: 'Left Winger', abbreviation: 'LW', x: 0.18, y: 0.28),
      ],
    ),
    FormationInfo(
      id: '4-2-3-1',
      name: '4-2-3-1',
      description: 'Double pivot protection, creative #10, lone striker',
      positions: [
        BlueprintPosition(positionId: 'gk', positionName: 'Goalkeeper', abbreviation: 'GK', x: 0.5, y: 0.92),
        BlueprintPosition(positionId: 'rb', positionName: 'Right Back', abbreviation: 'RB', x: 0.82, y: 0.75),
        BlueprintPosition(positionId: 'rcb', positionName: 'Right CB', abbreviation: 'RCB', x: 0.63, y: 0.78),
        BlueprintPosition(positionId: 'lcb', positionName: 'Left CB', abbreviation: 'LCB', x: 0.37, y: 0.78),
        BlueprintPosition(positionId: 'lb', positionName: 'Left Back', abbreviation: 'LB', x: 0.18, y: 0.75),
        BlueprintPosition(positionId: 'rdm', positionName: 'Right DM', abbreviation: 'RDM', x: 0.63, y: 0.60),
        BlueprintPosition(positionId: 'ldm', positionName: 'Left DM', abbreviation: 'LDM', x: 0.37, y: 0.60),
        BlueprintPosition(positionId: 'ram', positionName: 'Right AM', abbreviation: 'RAM', x: 0.75, y: 0.38),
        BlueprintPosition(positionId: 'cam', positionName: 'Attacking MF', abbreviation: 'CAM', x: 0.5, y: 0.34),
        BlueprintPosition(positionId: 'lam', positionName: 'Left AM', abbreviation: 'LAM', x: 0.25, y: 0.38),
        BlueprintPosition(positionId: 'st', positionName: 'Striker', abbreviation: 'ST', x: 0.5, y: 0.14),
      ],
    ),
    FormationInfo(
      id: '3-4-3',
      name: '3-4-3',
      description: 'Three CB aggression, wide midfielders, attacking trio',
      positions: [
        BlueprintPosition(positionId: 'gk', positionName: 'Goalkeeper', abbreviation: 'GK', x: 0.5, y: 0.92),
        BlueprintPosition(positionId: 'rcb', positionName: 'Right CB', abbreviation: 'RCB', x: 0.72, y: 0.76),
        BlueprintPosition(positionId: 'cb', positionName: 'Center CB', abbreviation: 'CB', x: 0.5, y: 0.80),
        BlueprintPosition(positionId: 'lcb', positionName: 'Left CB', abbreviation: 'LCB', x: 0.28, y: 0.76),
        BlueprintPosition(positionId: 'rm', positionName: 'Right MF', abbreviation: 'RM', x: 0.82, y: 0.55),
        BlueprintPosition(positionId: 'rcm', positionName: 'Right CM', abbreviation: 'RCM', x: 0.62, y: 0.52),
        BlueprintPosition(positionId: 'lcm', positionName: 'Left CM', abbreviation: 'LCM', x: 0.38, y: 0.52),
        BlueprintPosition(positionId: 'lm', positionName: 'Left MF', abbreviation: 'LM', x: 0.18, y: 0.55),
        BlueprintPosition(positionId: 'rw', positionName: 'Right Wing', abbreviation: 'RW', x: 0.78, y: 0.24),
        BlueprintPosition(positionId: 'st', positionName: 'Striker', abbreviation: 'ST', x: 0.5, y: 0.16),
        BlueprintPosition(positionId: 'lw', positionName: 'Left Wing', abbreviation: 'LW', x: 0.22, y: 0.24),
      ],
    ),
    FormationInfo(
      id: '4-4-2',
      name: '4-4-2',
      description: 'Classic flat four, two strikers, hard-working midfield',
      positions: [
        BlueprintPosition(positionId: 'gk', positionName: 'Goalkeeper', abbreviation: 'GK', x: 0.5, y: 0.92),
        BlueprintPosition(positionId: 'rb', positionName: 'Right Back', abbreviation: 'RB', x: 0.82, y: 0.75),
        BlueprintPosition(positionId: 'rcb', positionName: 'Right CB', abbreviation: 'RCB', x: 0.63, y: 0.78),
        BlueprintPosition(positionId: 'lcb', positionName: 'Left CB', abbreviation: 'LCB', x: 0.37, y: 0.78),
        BlueprintPosition(positionId: 'lb', positionName: 'Left Back', abbreviation: 'LB', x: 0.18, y: 0.75),
        BlueprintPosition(positionId: 'rm', positionName: 'Right MF', abbreviation: 'RM', x: 0.82, y: 0.52),
        BlueprintPosition(positionId: 'rcm', positionName: 'Right CM', abbreviation: 'RCM', x: 0.60, y: 0.54),
        BlueprintPosition(positionId: 'lcm', positionName: 'Left CM', abbreviation: 'LCM', x: 0.40, y: 0.54),
        BlueprintPosition(positionId: 'lm', positionName: 'Left MF', abbreviation: 'LM', x: 0.18, y: 0.52),
        BlueprintPosition(positionId: 'rst', positionName: 'Right Striker', abbreviation: 'RS', x: 0.63, y: 0.20),
        BlueprintPosition(positionId: 'lst', positionName: 'Left Striker', abbreviation: 'LS', x: 0.37, y: 0.20),
      ],
    ),
    FormationInfo(
      id: '3-5-2',
      name: '3-5-2',
      description: 'Three backs, wing backs, two-striker combination',
      positions: [
        BlueprintPosition(positionId: 'gk', positionName: 'Goalkeeper', abbreviation: 'GK', x: 0.5, y: 0.92),
        BlueprintPosition(positionId: 'rcb', positionName: 'Right CB', abbreviation: 'RCB', x: 0.72, y: 0.76),
        BlueprintPosition(positionId: 'cb', positionName: 'Center CB', abbreviation: 'CB', x: 0.5, y: 0.80),
        BlueprintPosition(positionId: 'lcb', positionName: 'Left CB', abbreviation: 'LCB', x: 0.28, y: 0.76),
        BlueprintPosition(positionId: 'rwb', positionName: 'Right Wing Back', abbreviation: 'RWB', x: 0.88, y: 0.54),
        BlueprintPosition(positionId: 'rcm', positionName: 'Right CM', abbreviation: 'RCM', x: 0.66, y: 0.52),
        BlueprintPosition(positionId: 'cm', positionName: 'CM', abbreviation: 'CM', x: 0.5, y: 0.50),
        BlueprintPosition(positionId: 'lcm', positionName: 'Left CM', abbreviation: 'LCM', x: 0.34, y: 0.52),
        BlueprintPosition(positionId: 'lwb', positionName: 'Left Wing Back', abbreviation: 'LWB', x: 0.12, y: 0.54),
        BlueprintPosition(positionId: 'rst', positionName: 'Right Striker', abbreviation: 'RS', x: 0.63, y: 0.20),
        BlueprintPosition(positionId: 'lst', positionName: 'Left Striker', abbreviation: 'LS', x: 0.37, y: 0.20),
      ],
    ),
  ];

  static const List<PlayerQuality> qualities = [
    // Technical
    PlayerQuality('first_touch', 'Elite First Touch', 'Technical'),
    PlayerQuality('dribbling', 'Dribbling Under Pressure', 'Technical'),
    PlayerQuality('passing_range', 'Long Range Passing', 'Technical'),
    PlayerQuality('finishing', 'Clinical Finishing', 'Technical'),
    PlayerQuality('crossing', 'Delivery & Crossing', 'Technical'),
    PlayerQuality('set_pieces', 'Set Piece Specialist', 'Technical'),
    PlayerQuality('1v1_defense', '1v1 Defending', 'Technical'),
    PlayerQuality('heading', 'Aerial Ability', 'Technical'),
    // Physical
    PlayerQuality('pace', 'Explosive Pace', 'Physical'),
    PlayerQuality('strength', 'Physical Strength', 'Physical'),
    PlayerQuality('stamina', 'High Stamina / Engine', 'Physical'),
    PlayerQuality('agility', 'Agility & Quickness', 'Physical'),
    PlayerQuality('jumping', 'Jumping Reach', 'Physical'),
    // Mental / Tactical
    PlayerQuality('pressing', 'High Pressing Intensity', 'Tactical'),
    PlayerQuality('positioning', 'Tactical Positioning', 'Tactical'),
    PlayerQuality('leadership', 'Leadership & Communication', 'Tactical'),
    PlayerQuality('vision', 'Game Vision', 'Tactical'),
    PlayerQuality('work_rate', 'High Work Rate', 'Tactical'),
    PlayerQuality('composure', 'Composure Under Pressure', 'Tactical'),
    PlayerQuality('versatility', 'Positional Versatility', 'Tactical'),
    // Character
    PlayerQuality('coachability', 'Coachability', 'Character'),
    PlayerQuality('gpa_priority', 'Strong Academic Record', 'Character'),
    PlayerQuality('bilingual', 'Bilingual (Spanish/English)', 'Character'),
  ];

  static List<String> get qualityCategories =>
      qualities.map((q) => q.category).toSet().toList();

  static const List<String> playingStyles = [
    'High Press / Gegenpressing',
    'Possession-based (Tiki-Taka)',
    'Counter Attack',
    'Direct / Long Ball',
    'Hybrid / Balanced',
  ];

  static const List<String> recruitingYears = [
    '2025', '2026', '2027', '2028', '2029', '2030',
  ];
}

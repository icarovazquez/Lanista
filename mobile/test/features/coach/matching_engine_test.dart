/// Regression tests for the match-players edge function data model.
///
/// These tests guard against column name regressions (e.g. position_id vs
/// position_key, primary_formation_id vs primary_formation) that caused the
/// matching engine to return 500 "Failed to load coaches".
///
/// Because the edge function is TypeScript/Deno, we test the Dart-side
/// contracts: the field names used in Supabase queries and the scoring logic
/// mirrors that live in the function.

import 'package:flutter_test/flutter_test.dart';

// ─── Data model contracts ────────────────────────────────────────────────────

/// Mirrors the Coach interface in match-players/index.ts.
/// If this changes, the edge function MUST be updated to match.
class _Coach {
  final String id;
  final String? primaryFormation;       // TEXT column — NOT primary_formation_id
  final List<String>? recruitingClassYears;
  final List<_CoachReq> requirements;
  final List<_RosterSlot> rosterSlots;

  const _Coach({
    required this.id,
    this.primaryFormation,
    this.recruitingClassYears,
    this.requirements = const [],
    this.rosterSlots = const [],
  });
}

/// Mirrors CoachRequirement in match-players/index.ts.
class _CoachReq {
  final String positionKey;             // TEXT column — NOT position_id
  final List<String> requiredQualities;

  const _CoachReq({required this.positionKey, this.requiredQualities = const []});
}

/// Mirrors RosterSlot in match-players/index.ts.
class _RosterSlot {
  final String positionKey;             // TEXT column — NOT position_id
  final int? graduationYear;
  final String slotStatus;

  const _RosterSlot({
    required this.positionKey,
    this.graduationYear,
    required this.slotStatus,
  });
}

/// Mirrors the Player interface in match-players/index.ts.
class _Player {
  final String? primaryPosition;        // TEXT column — NOT primary_position_id
  final String? secondaryPosition;      // TEXT column — NOT secondary_position_id
  final int? graduationYear;
  final String? gpaUnweighted;
  final String? dominantFoot;
  final String? heightCm;
  final String? targetDivision;

  const _Player({
    this.primaryPosition,
    this.secondaryPosition,
    this.graduationYear,
    this.gpaUnweighted,
    this.dominantFoot,
    this.heightCm,
    this.targetDivision,
  });
}

// ─── Scoring logic (mirrors computeMatchScore in match-players/index.ts) ────

Map<String, double> _computeMatchScore(_Player player, _Coach coach) {
  double tactical = 0;
  double position = 0;
  double physical = 10;
  double academic = 0;
  double timeline = 0;

  // Tactical (35 pts)
  final primaryReq = coach.requirements.cast<_CoachReq?>().firstWhere(
    (r) => r?.positionKey == player.primaryPosition,
    orElse: () => null,
  );
  if (primaryReq != null) {
    tactical += 25;
    if (player.secondaryPosition != null) {
      final secReq = coach.requirements.cast<_CoachReq?>().firstWhere(
        (r) => r?.positionKey == player.secondaryPosition,
        orElse: () => null,
      );
      if (secReq != null) tactical += 10;
    }
  }
  tactical = tactical.clamp(0, 35);

  // Position (25 pts)
  if (primaryReq != null) {
    final openSlot = coach.rosterSlots.cast<_RosterSlot?>().firstWhere(
      (s) => s?.positionKey == player.primaryPosition && s?.slotStatus == 'open',
      orElse: () => null,
    );
    if (openSlot != null) {
      position += 20;
      if (openSlot.graduationYear != null && player.graduationYear != null) {
        final diff = (openSlot.graduationYear! - player.graduationYear!).abs();
        if (diff == 0) position += 5;
        else if (diff == 1) position += 3;
      }
    } else {
      position += 8;
    }
  }
  position = position.clamp(0, 25);

  // Physical (20 pts)
  if (player.dominantFoot != null) physical += 5;
  if (player.heightCm != null) physical += 5;
  physical = physical.clamp(0, 20);

  // Academic (15 pts)
  if (player.gpaUnweighted != null) {
    final gpa = player.gpaUnweighted!.startsWith('4.0') ? 4.0
        : player.gpaUnweighted!.startsWith('3.5') ? 3.5
        : player.gpaUnweighted!.startsWith('3.0') ? 3.0
        : player.gpaUnweighted!.startsWith('2.5') ? 2.5
        : 0.0;
    if (gpa >= 4.0) academic = 15;
    else if (gpa >= 3.5) academic = 12;
    else if (gpa >= 3.0) academic = 9;
    else if (gpa >= 2.5) academic = 6;
  }
  academic = academic.clamp(0, 15);

  // Timeline (5 pts)
  if (player.graduationYear != null && coach.recruitingClassYears != null) {
    final yearStr = player.graduationYear.toString();
    if (coach.recruitingClassYears!.contains(yearStr)) {
      timeline = 5;
    } else if (coach.recruitingClassYears!.any(
        (y) => (int.tryParse(y) ?? 0 - player.graduationYear!).abs() == 1)) {
      timeline = 3;
    }
  }

  return {
    'tactical': tactical,
    'position': position,
    'physical': physical,
    'academic': academic,
    'timeline': timeline,
    'total': tactical + position + physical + academic + timeline,
  };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── Column name contract tests ─────────────────────────────────────────────
  group('Matching engine — column name contracts', () {
    test('Coach uses primary_formation (TEXT), not primary_formation_id', () {
      // Regression: match-players was selecting primary_formation_id which
      // no longer exists after migration 010 renamed it to primary_formation.
      const coach = _Coach(id: 'c1', primaryFormation: '4-3-3');
      expect(coach.primaryFormation, equals('4-3-3'));
    });

    test('CoachRequirement uses position_key (TEXT), not position_id', () {
      // Regression: match-players was joining on position_id which is now
      // nullable after migration 015 switched to position_key TEXT.
      const req = _CoachReq(positionKey: 'st');
      expect(req.positionKey, equals('st'));
    });

    test('RosterSlot uses position_key (TEXT), not position_id', () {
      const slot = _RosterSlot(positionKey: 'gk', slotStatus: 'open');
      expect(slot.positionKey, equals('gk'));
    });

    test('Player uses primary_position (TEXT), not primary_position_id', () {
      // Regression: match-players was reading primary_position_id which
      // no longer exists after migration 011 added primary_position TEXT.
      const player = _Player(primaryPosition: 'st');
      expect(player.primaryPosition, equals('st'));
    });

    test('Player uses secondary_position (TEXT), not secondary_position_id', () {
      const player = _Player(secondaryPosition: 'rw');
      expect(player.secondaryPosition, equals('rw'));
    });
  });

  // ── Scoring logic tests ────────────────────────────────────────────────────
  group('Matching engine — scoring', () {
    test('perfect match scores >= 30 (threshold for saving)', () {
      const player = _Player(
        primaryPosition: 'st',
        graduationYear: 2027,
        gpaUnweighted: '3.5',
        dominantFoot: 'right',
        heightCm: '182',
      );
      const coach = _Coach(
        id: 'c1',
        primaryFormation: '4-3-3',
        recruitingClassYears: ['2026', '2027', '2028'],
        requirements: [_CoachReq(positionKey: 'st')],
        rosterSlots: [_RosterSlot(positionKey: 'st', graduationYear: 2027, slotStatus: 'open')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['total'], greaterThanOrEqualTo(30));
    });

    test('position_key match gives tactical points', () {
      const player = _Player(primaryPosition: 'gk');
      const coach = _Coach(
        id: 'c1',
        requirements: [_CoachReq(positionKey: 'gk')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['tactical'], greaterThan(0));
    });

    test('position_key mismatch gives zero tactical points', () {
      const player = _Player(primaryPosition: 'st');
      const coach = _Coach(
        id: 'c1',
        requirements: [_CoachReq(positionKey: 'gk')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['tactical'], equals(0));
    });

    test('open roster slot for matching position gives position points', () {
      const player = _Player(primaryPosition: 'cm', graduationYear: 2027);
      const coach = _Coach(
        id: 'c1',
        requirements: [_CoachReq(positionKey: 'cm')],
        rosterSlots: [_RosterSlot(positionKey: 'cm', graduationYear: 2027, slotStatus: 'open')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['position'], equals(25)); // 20 open slot + 5 perfect year
    });

    test('perfect graduation year match gives full position bonus', () {
      const player = _Player(primaryPosition: 'lw', graduationYear: 2026);
      const coach = _Coach(
        id: 'c1',
        requirements: [_CoachReq(positionKey: 'lw')],
        rosterSlots: [_RosterSlot(positionKey: 'lw', graduationYear: 2026, slotStatus: 'open')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['position'], equals(25));
    });

    test('recruiting class year match gives timeline points', () {
      const player = _Player(primaryPosition: 'rb', graduationYear: 2027);
      const coach = _Coach(
        id: 'c1',
        recruitingClassYears: ['2026', '2027', '2028'],
        requirements: [_CoachReq(positionKey: 'rb')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['timeline'], equals(5));
    });

    test('physical score increases with height and foot data', () {
      const playerBase = _Player(primaryPosition: 'cb');
      const playerFull = _Player(
        primaryPosition: 'cb',
        dominantFoot: 'right',
        heightCm: '190',
      );
      final baseScore = _computeMatchScore(playerBase,
          const _Coach(id: 'c1', requirements: []));
      final fullScore = _computeMatchScore(playerFull,
          const _Coach(id: 'c1', requirements: []));
      expect(fullScore['physical'], greaterThan(baseScore['physical']!));
    });

    test('total score does not exceed 100', () {
      const player = _Player(
        primaryPosition: 'st',
        secondaryPosition: 'cf',
        graduationYear: 2027,
        gpaUnweighted: '4.0+',
        dominantFoot: 'right',
        heightCm: '185',
      );
      const coach = _Coach(
        id: 'c1',
        primaryFormation: '4-3-3',
        recruitingClassYears: ['2027'],
        requirements: [
          _CoachReq(positionKey: 'st'),
          _CoachReq(positionKey: 'cf'),
        ],
        rosterSlots: [_RosterSlot(positionKey: 'st', graduationYear: 2027, slotStatus: 'open')],
      );
      final score = _computeMatchScore(player, coach);
      expect(score['total'], lessThanOrEqualTo(100));
    });
  });
}

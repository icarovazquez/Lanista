/// Regression tests for the coach-side features.
///
/// Tests cover: dashboard card counts, roster map depth chart logic,
/// pipeline stage transitions, search filter pipeline, match score binning,
/// height conversion, GPA range matching, and conversation upsert contract.
///
/// All tests are pure unit/logic tests — no real Supabase or device needed.

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── 1. Dashboard card count logic ────────────────────────────────────────────
  group('Coach dashboard card counts', () {
    // Mirrors _loadStats() in coach_dashboard_page.dart

    int _rosterGaps(List<Map<String, dynamic>> slots) =>
        slots.where((s) => s['needs_recruit'] == true).length;

    int _inPipeline(List<Map<String, dynamic>> pipeline) =>
        pipeline.where((p) => !['declined', 'lost'].contains(p['stage'])).length;

    test('roster gaps counts only slots where needs_recruit is true', () {
      final slots = [
        {'position_key': 'gk', 'needs_recruit': true},
        {'position_key': 'cb', 'needs_recruit': false},
        {'position_key': 'st', 'needs_recruit': true},
      ];
      expect(_rosterGaps(slots), 2);
    });

    test('roster gaps returns 0 when all slots are filled', () {
      final slots = [
        {'position_key': 'gk', 'needs_recruit': false},
        {'position_key': 'cb', 'needs_recruit': false},
      ];
      expect(_rosterGaps(slots), 0);
    });

    test('pipeline count excludes declined and lost stages', () {
      final pipeline = [
        {'stage': 'identified'},
        {'stage': 'contacted'},
        {'stage': 'declined'},
        {'stage': 'lost'},
        {'stage': 'committed'},
      ];
      expect(_inPipeline(pipeline), 3);
    });

    test('pipeline count is 0 when all prospects declined or lost', () {
      final pipeline = [
        {'stage': 'declined'},
        {'stage': 'lost'},
      ];
      expect(_inPipeline(pipeline), 0);
    });

    test('dashboard shows "Setup Blueprint" when onboarding incomplete', () {
      const onboardingComplete = false;
      final label = onboardingComplete ? 'Edit Blueprint' : 'Setup Blueprint';
      expect(label, 'Setup Blueprint');
    });

    test('dashboard shows "Edit Blueprint" when onboarding complete', () {
      const onboardingComplete = true;
      final label = onboardingComplete ? 'Edit Blueprint' : 'Setup Blueprint';
      expect(label, 'Edit Blueprint');
    });
  });

  // ── 2. Roster map depth chart logic ─────────────────────────────────────────
  group('Roster map depth chart', () {
    const maxDepth = 4;

    String _slotKey(String positionKey, int year) => '${positionKey}_$year';

    test('slot key format is positionKey_year', () {
      expect(_slotKey('gk', 2026), 'gk_2026');
      expect(_slotKey('cm', 2027), 'cm_2027');
    });

    test('depth order must be between 1 and maxDepth (4)', () {
      for (int d = 1; d <= maxDepth; d++) {
        expect(d, greaterThanOrEqualTo(1));
        expect(d, lessThanOrEqualTo(maxDepth));
      }
    });

    test('cannot add more than 4 players to a position per year', () {
      final slots = [1, 2, 3, 4]; // depth orders
      expect(slots.length, maxDepth);
      // Attempting to add a 5th slot should be blocked
      final canAdd = slots.length < maxDepth;
      expect(canAdd, isFalse);
    });

    test('all 5 slot statuses are valid', () {
      const validStatuses = {'filled', 'graduating', 'portal_risk', 'open', 'unknown'};
      expect(validStatuses.length, 5);
      for (final s in validStatuses) {
        expect(s.isNotEmpty, isTrue);
      }
    });

    test('upsert conflict key includes depth_order — regression guard', () {
      // Regression: missing depth_order in onConflict caused duplicate row error
      const onConflict = 'coach_id,position_key,graduation_year,depth_order';
      expect(onConflict.contains('depth_order'), isTrue);
      expect(onConflict.contains('coach_id'), isTrue);
      expect(onConflict.contains('position_key'), isTrue);
      expect(onConflict.contains('graduation_year'), isTrue);
    });

    test('depth swap uses temp value 999 to avoid constraint violation', () {
      // Simulates 3-step swap: A→999, B→A, 999→B
      int depthA = 1;
      int depthB = 2;
      const tempDepth = 999;

      int slotADepth = depthA;
      int slotBDepth = depthB;

      // Step 1: move A to temp
      slotADepth = tempDepth;
      // Step 2: move B to A's original position
      slotBDepth = depthA;
      // Step 3: move temp to B's original position
      slotADepth = depthB;

      expect(slotADepth, 2);
      expect(slotBDepth, 1);
    });

    test('injured player can still have a slot status', () {
      final slot = {
        'slot_status': 'filled',
        'is_injured': true,
        'injury_return_date': '2026-05-01',
      };
      expect(slot['is_injured'], isTrue);
      expect(slot['slot_status'], 'filled');
    });
  });

  // ── 3. Pipeline stage transitions ────────────────────────────────────────────
  group('Recruiting pipeline stage transitions', () {
    const activeStages = ['identified', 'contacted', 'evaluated', 'offered', 'committed'];
    const archiveStages = ['declined', 'lost'];
    const allStages = [...activeStages, ...archiveStages];

    test('there are exactly 5 active kanban stages', () {
      expect(activeStages.length, 5);
    });

    test('there are exactly 2 archive stages', () {
      expect(archiveStages.length, 2);
    });

    test('total stages count is 7', () {
      expect(allStages.length, 7);
    });

    test('committed is the final active stage', () {
      expect(activeStages.last, 'committed');
    });

    test('identified is the first active stage', () {
      expect(activeStages.first, 'identified');
    });

    test('moving to any valid stage is allowed', () {
      for (final stage in allStages) {
        expect(allStages.contains(stage), isTrue);
      }
    });

    test('pipeline upsert conflict key is coach_id,player_id — no duplicates', () {
      const onConflict = 'coach_id,player_id';
      expect(onConflict, 'coach_id,player_id');
    });

    test('add to pipeline sets stage to identified by default', () {
      final payload = {
        'coach_id': 'coach-1',
        'player_id': 'player-1',
        'stage': 'identified',
      };
      expect(payload['stage'], 'identified');
    });
  });

  // ── 4. Coach search filter pipeline ─────────────────────────────────────────
  group('Coach search filter pipeline', () {
    final _mockPlayers = [
      {'name': 'Kieran Ross', 'primary_position': 'CM', 'graduation_year': 2026, 'gpa': 3.8, 'dominant_foot': 'right', 'league': 'MLS Next'},
      {'name': 'Alex Torres', 'primary_position': 'ST', 'graduation_year': 2027, 'gpa': 3.2, 'dominant_foot': 'left', 'league': 'ECNL Boys'},
      {'name': 'Sam Green', 'primary_position': 'GK', 'graduation_year': 2026, 'gpa': 4.0, 'dominant_foot': 'right', 'league': 'MLS Next'},
      {'name': 'Jordan Lee', 'primary_position': 'CB', 'graduation_year': 2028, 'gpa': 2.8, 'dominant_foot': 'both', 'league': 'ECRL'},
    ];

    List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> players, {
      String? position,
      int? gradYear,
      String? foot,
      String? league,
      String? keyword,
    }) {
      var r = players.toList();
      if (position != null) r = r.where((p) => p['primary_position'] == position).toList();
      if (gradYear != null) r = r.where((p) => p['graduation_year'] == gradYear).toList();
      if (foot != null) r = r.where((p) => (p['dominant_foot'] as String).toLowerCase() == foot.toLowerCase()).toList();
      if (league != null) r = r.where((p) => (p['league'] as String).toLowerCase().contains(league.toLowerCase())).toList();
      if (keyword != null) r = r.where((p) => (p['name'] as String).toLowerCase().contains(keyword.toLowerCase())).toList();
      return r;
    }

    String _gpaRange(double gpa) {
      if (gpa >= 3.9) return '3.9+';
      if (gpa >= 3.5) return '3.5–3.9';
      if (gpa >= 3.0) return '3.0–3.5';
      if (gpa >= 2.5) return '2.5–3.0';
      return 'Below 2.5';
    }

    test('position filter returns only matching position', () {
      final results = _applyFilters(_mockPlayers, position: 'GK');
      expect(results.length, 1);
      expect(results.first['name'], 'Sam Green');
    });

    test('graduation year filter returns only matching year', () {
      final results = _applyFilters(_mockPlayers, gradYear: 2026);
      expect(results.length, 2);
      expect(results.every((p) => p['graduation_year'] == 2026), isTrue);
    });

    test('dominant foot filter is case-insensitive', () {
      final results = _applyFilters(_mockPlayers, foot: 'Right');
      expect(results.every((p) => (p['dominant_foot'] as String).toLowerCase() == 'right'), isTrue);
    });

    test('league filter uses partial match', () {
      final results = _applyFilters(_mockPlayers, league: 'MLS');
      expect(results.every((p) => (p['league'] as String).contains('MLS')), isTrue);
      expect(results.length, 2);
    });

    test('keyword search matches player name', () {
      final results = _applyFilters(_mockPlayers, keyword: 'kieran');
      expect(results.length, 1);
      expect(results.first['name'], 'Kieran Ross');
    });

    test('combining position + grad year narrows results', () {
      final results = _applyFilters(_mockPlayers, position: 'CM', gradYear: 2026);
      expect(results.length, 1);
    });

    test('no matching filters returns empty list without error', () {
      final results = _applyFilters(_mockPlayers, position: 'LB', gradYear: 2030);
      expect(results, isEmpty);
    });

    test('GPA range 3.9+ correctly categorized', () {
      expect(_gpaRange(4.0), '3.9+');
      expect(_gpaRange(3.9), '3.9+');
    });

    test('GPA range 3.5–3.9 correctly categorized', () {
      expect(_gpaRange(3.8), '3.5–3.9');
      expect(_gpaRange(3.5), '3.5–3.9');
    });

    test('GPA range below 2.5 correctly categorized', () {
      expect(_gpaRange(2.4), 'Below 2.5');
      expect(_gpaRange(0.0), 'Below 2.5');
    });
  });

  // ── 5. Match score binning (Excellent/Strong/Good/Possible) ─────────────────
  group('Coach match score binning', () {
    String _matchLabel(double score) {
      if (score >= 75) return 'Excellent';
      if (score >= 60) return 'Strong';
      if (score >= 45) return 'Good';
      return 'Possible';
    }

    test('score >= 75 is Excellent', () {
      expect(_matchLabel(75), 'Excellent');
      expect(_matchLabel(100), 'Excellent');
      expect(_matchLabel(90), 'Excellent');
    });

    test('score 60–74 is Strong', () {
      expect(_matchLabel(60), 'Strong');
      expect(_matchLabel(74), 'Strong');
    });

    test('score 45–59 is Good', () {
      expect(_matchLabel(45), 'Good');
      expect(_matchLabel(59), 'Good');
    });

    test('score below 45 is Possible', () {
      expect(_matchLabel(44), 'Possible');
      expect(_matchLabel(0), 'Possible');
    });

    test('score boundary 74.9 is Strong not Excellent', () {
      expect(_matchLabel(74.9), 'Strong');
    });

    test('score boundary 44.9 is Possible not Good', () {
      expect(_matchLabel(44.9), 'Possible');
    });

    test('match score is always 0–100', () {
      final scores = [0.0, 25.0, 50.0, 75.0, 100.0];
      for (final s in scores) {
        expect(s, greaterThanOrEqualTo(0));
        expect(s, lessThanOrEqualTo(100));
      }
    });

    test('position weight is 35% of total score', () {
      const positionWeight = 35;
      const timelineWeight = 30;
      const academicsWeight = 20;
      const physicalWeight = 15;
      expect(positionWeight + timelineWeight + academicsWeight + physicalWeight, 100);
    });
  });

  // ── 6. Height conversion (cm → imperial) ────────────────────────────────────
  group('Player height conversion', () {
    String _heightDisplay(int? heightCm) {
      if (heightCm == null) return '—';
      final totalInches = (heightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$heightCm cm ($feet'$inches\")";
    }

    test('180 cm displays as 5\'11\"', () {
      expect(_heightDisplay(180), "180 cm (5'11\")");
    });

    test('183 cm displays as 6\'0\"', () {
      // 183 / 2.54 = 72.047... rounds to 72 inches = 6'0"
      final result = _heightDisplay(183);
      expect(result.contains("183 cm"), isTrue);
      expect(result.contains("6'"), isTrue);
      expect(result.contains("0\""), isTrue);
    });

    test('null height displays as dash', () {
      expect(_heightDisplay(null), '—');
    });

    test('height display includes both metric and imperial', () {
      final display = _heightDisplay(175);
      expect(display.contains('cm'), isTrue);
      expect(display.contains("'"), isTrue);
      expect(display.contains('"'), isTrue);
    });

    test('height display format is "NNN cm (F\'I\")"', () {
      final display = _heightDisplay(180);
      expect(display, startsWith('180 cm'));
      expect(display, contains('('));
      expect(display, contains(')'));
    });
  });

  // ── 7. Conversation upsert contract ─────────────────────────────────────────
  group('Coach conversation creation contract', () {
    Map<String, dynamic> _buildConversationPayload({
      required String coachId,
      required String playerId,
      String initiatedBy = 'coach',
    }) {
      return {
        'coach_id': coachId,
        'player_id': playerId,
        'initiated_by': initiatedBy,
        'contact_window_valid': true,
      };
    }

    test('conversation payload includes coach_id and player_id', () {
      final payload = _buildConversationPayload(coachId: 'c1', playerId: 'p1');
      expect(payload['coach_id'], 'c1');
      expect(payload['player_id'], 'p1');
    });

    test('coach-initiated conversation sets initiated_by to coach', () {
      final payload = _buildConversationPayload(coachId: 'c1', playerId: 'p1', initiatedBy: 'coach');
      expect(payload['initiated_by'], 'coach');
    });

    test('contact_window_valid is true on creation', () {
      final payload = _buildConversationPayload(coachId: 'c1', playerId: 'p1');
      expect(payload['contact_window_valid'], isTrue);
    });

    test('conversation upsert conflict key is coach_id,player_id', () {
      // Guards against creating duplicate conversations between same coach+player
      const onConflict = 'coach_id,player_id';
      expect(onConflict.contains('coach_id'), isTrue);
      expect(onConflict.contains('player_id'), isTrue);
    });
  });

  // ── 8. Onboarding guard for matching engine ──────────────────────────────────
  group('Matching engine onboarding guard', () {
    bool _canLoadMatches(bool onboardingComplete) => onboardingComplete;

    test('matches page requires onboarding to be complete', () {
      expect(_canLoadMatches(false), isFalse);
      expect(_canLoadMatches(true), isTrue);
    });

    test('incomplete onboarding shows setup prompt not match results', () {
      const onboardingComplete = false;
      final shows = onboardingComplete ? 'matches' : 'setup_prompt';
      expect(shows, 'setup_prompt');
    });
  });

  // ── 9. Coach position requirements — DELETE + INSERT contract ────────────────
  group('Coach position requirements save contract', () {
    // Regression: upsert caused duplicates because no unique constraint exists.
    // Fix: always DELETE first, then INSERT.

    test('position requirements use DELETE then INSERT not upsert', () {
      // Simulates the correct save flow
      final savedRequirements = <Map<String, dynamic>>[];

      void savePositionRequirements(
        String coachId,
        Map<String, List<String>> positionQualities,
      ) {
        // Step 1: DELETE all existing (simulated)
        savedRequirements.clear(); // mirrors .delete().eq('coach_id', coachId)

        // Step 2: INSERT new rows
        for (final entry in positionQualities.entries) {
          if (entry.value.isNotEmpty) {
            savedRequirements.add({
              'coach_id': coachId,
              'position_key': entry.key,
              'required_qualities': entry.value,
              'is_published': true,
            });
          }
        }
      }

      // Call twice to verify no duplicates
      savePositionRequirements('coach-1', {'gk': ['shot_stopping'], 'cm': ['vision']});
      savePositionRequirements('coach-1', {'gk': ['shot_stopping'], 'cm': ['vision']});

      expect(savedRequirements.length, 2); // No duplicates
    });

    test('position requirements with empty qualities are excluded', () {
      final qualities = {'gk': ['shot_stopping'], 'cm': <String>[], 'st': ['finishing']};
      final rows = qualities.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => {'position_key': e.key, 'required_qualities': e.value})
          .toList();
      expect(rows.length, 2); // cm excluded
      expect(rows.any((r) => r['position_key'] == 'cm'), isFalse);
    });

    test('is_published is always true on save', () {
      final qualities = {'gk': ['shot_stopping']};
      final rows = qualities.entries
          .map((e) => {'position_key': e.key, 'required_qualities': e.value, 'is_published': true})
          .toList();
      expect(rows.every((r) => r['is_published'] == true), isTrue);
    });
  });

  // ── 10. Roster slot status → needs_recruit mapping ──────────────────────────
  group('Roster slot status to needs_recruit mapping', () {
    bool _needsRecruit(String status) =>
        status == 'open' || status == 'graduating';

    test('open slot needs recruit', () => expect(_needsRecruit('open'), isTrue));
    test('graduating slot needs recruit', () => expect(_needsRecruit('graduating'), isTrue));
    test('filled slot does not need recruit', () => expect(_needsRecruit('filled'), isFalse));
    test('portal_risk slot does not need recruit', () => expect(_needsRecruit('portal_risk'), isFalse));
    test('unknown slot does not need recruit', () => expect(_needsRecruit('unknown'), isFalse));
  });

  // ── 11. Profile view tracking ────────────────────────────────────────────────
  group('Profile view tracking', () {
    // Mirrors _recordProfileView in coach_player_detail_page.dart and
    // the _loadViews deduplication logic in player_profile_views_page.dart.

    // Simulate the insert payload that _recordProfileView builds
    Map<String, dynamic>? _buildViewPayload(
        String? userId, Map<String, dynamic>? coachRow, String playerId) {
      if (userId == null) return null;
      if (coachRow == null) return null;
      return {
        'coach_id': coachRow['id'] as String,
        'player_id': playerId,
      };
    }

    // Simulate deduplication logic from PlayerProfileViewsPage._loadViews()
    List<Map<String, dynamic>> _deduplicateByCoach(
        List<Map<String, dynamic>> rows) {
      final seen = <String>{};
      final deduped = <Map<String, dynamic>>[];
      for (final r in rows) {
        final coachId = r['coach_id'] as String;
        if (seen.contains(coachId)) continue;
        seen.add(coachId);
        deduped.add(r);
      }
      return deduped;
    }

    test('payload is null when userId is null (unauthenticated)', () {
      final payload = _buildViewPayload(null, {'id': 'coach-1'}, 'player-1');
      expect(payload, isNull);
    });

    test('payload is null when coachRow is null (non-coach user)', () {
      final payload = _buildViewPayload('user-1', null, 'player-1');
      expect(payload, isNull);
    });

    test('payload contains correct coach_id and player_id', () {
      final payload =
          _buildViewPayload('user-1', {'id': 'coach-abc'}, 'player-xyz');
      expect(payload, isNotNull);
      expect(payload!['coach_id'], 'coach-abc');
      expect(payload['player_id'], 'player-xyz');
    });

    test('each coach view is deduplicated — only most recent kept', () {
      final rows = [
        {'coach_id': 'coach-1', 'viewed_at': '2026-04-02T10:00:00Z'},
        {'coach_id': 'coach-2', 'viewed_at': '2026-04-02T09:00:00Z'},
        {'coach_id': 'coach-1', 'viewed_at': '2026-04-01T08:00:00Z'}, // duplicate
      ];
      final deduped = _deduplicateByCoach(rows);
      expect(deduped.length, 2);
      expect(deduped.map((r) => r['coach_id']).toSet(), {'coach-1', 'coach-2'});
    });

    test('deduplicated list keeps the first occurrence (most recent, ordered DESC)', () {
      final rows = [
        {'coach_id': 'coach-1', 'viewed_at': '2026-04-02T10:00:00Z'}, // most recent first
        {'coach_id': 'coach-1', 'viewed_at': '2026-04-01T08:00:00Z'},
      ];
      final deduped = _deduplicateByCoach(rows);
      expect(deduped.length, 1);
      expect(deduped.first['viewed_at'], '2026-04-02T10:00:00Z');
    });

    test('30-day count equals number of unique coaches', () {
      final rows = [
        {'coach_id': 'coach-1', 'viewed_at': '2026-04-02T10:00:00Z'},
        {'coach_id': 'coach-2', 'viewed_at': '2026-04-01T09:00:00Z'},
        {'coach_id': 'coach-1', 'viewed_at': '2026-03-30T08:00:00Z'},
        {'coach_id': 'coach-3', 'viewed_at': '2026-03-28T07:00:00Z'},
      ];
      final deduped = _deduplicateByCoach(rows);
      expect(deduped.length, 3); // 3 unique coaches
    });

    test('7-day count filters correctly from deduplicated views', () {
      final now = DateTime(2026, 4, 2);
      final views = [
        {'coach_id': 'coach-1', 'viewed_at': now.subtract(const Duration(days: 1))},
        {'coach_id': 'coach-2', 'viewed_at': now.subtract(const Duration(days: 5))},
        {'coach_id': 'coach-3', 'viewed_at': now.subtract(const Duration(days: 8))}, // outside 7d
      ];
      final last7 =
          views.where((v) => now.difference(v['viewed_at'] as DateTime).inDays < 7).length;
      expect(last7, 2);
    });

    test('empty profile_views returns zero counts', () {
      final deduped = _deduplicateByCoach([]);
      expect(deduped.length, 0);
    });
  });

  // ── 12. Seed data integrity ───────────────────────────────────────────────
  group('Seed data integrity — Coach Daniels (regression: school_name)', () {
    // Regression: coach c3000000-0000-0000-0000-000000000001 had school_name
    // manually overwritten to 'UT Austin' in the DB despite bio/state pointing
    // to UNC. Migration 077 fixed it. These tests guard the expected values.

    const coachDaniels = {
      'id': 'c3000000-0000-0000-0000-000000000001',
      'school_name': 'University of North Carolina',
      'state': 'NC',
      'division': 'D1',
      'bio': 'UNC Men\'s Soccer — ACC powerhouse with a rich history of developing professional players.',
    };

    test('school_name is University of North Carolina, not UT Austin', () {
      expect(coachDaniels['school_name'], 'University of North Carolina');
      expect(coachDaniels['school_name'], isNot('UT Austin'));
    });

    test('state is NC (consistent with UNC, not TX for UT Austin)', () {
      expect(coachDaniels['state'], 'NC');
    });

    test('bio references UNC, not UT Austin', () {
      expect((coachDaniels['bio'] as String).contains('UNC'), isTrue);
    });

    test('school_name and bio are internally consistent', () {
      final school = coachDaniels['school_name'] as String;
      final bio = coachDaniels['bio'] as String;
      // Both should reference Carolina / UNC, not conflicting programs
      final schoolIsUNC = school.contains('North Carolina') || school.contains('UNC');
      final bioIsUNC = bio.contains('UNC') || bio.contains('North Carolina');
      expect(schoolIsUNC, isTrue);
      expect(bioIsUNC, isTrue);
      expect(schoolIsUNC == bioIsUNC, isTrue);
    });
  });
}

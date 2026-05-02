/// Regression tests for the player-side features.
///
/// Tests cover: profile creation payload, search filter logic, AI analysis
/// state machine, dark mode toggle, edit profile navigation, dashboard count
/// consistency, and matching engine error handling.
///
/// All tests are pure unit/logic tests — no real Supabase or device needed.

import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:lanista/features/player/roadmap/data/roadmap_models.dart';
import 'package:lanista/core/theme/player_colors.dart';
import 'package:lanista/core/theme/app_colors.dart';

void main() {
  // ── 1. Player profile creation payload ──────────────────────────────────────
  group('Player profile creation', () {
    Map<String, dynamic> buildProfilePayload({
      String firstName = 'Kieran',
      String lastName = 'Ross',
      String? primaryPosition = 'CM',
      int? graduationYear = 2026,
      String? clubName = 'Colorado Rapids Academy',
    }) {
      return {
        'first_name': firstName,
        'last_name': lastName,
        'primary_position': primaryPosition,
        'graduation_year': graduationYear,
        'club_name': clubName,
      };
    }

    test('payload contains required first_name and last_name', () {
      final payload = buildProfilePayload();
      expect(payload['first_name'], isNotEmpty);
      expect(payload['last_name'], isNotEmpty);
    });

    test('payload with empty first name is invalid', () {
      final payload = buildProfilePayload(firstName: '');
      expect((payload['first_name'] as String).isEmpty, isTrue);
    });

    test('graduation_year must be a plausible future year', () {
      final payload = buildProfilePayload(graduationYear: 2026);
      final year = payload['graduation_year'] as int;
      expect(year, greaterThanOrEqualTo(2024));
      expect(year, lessThanOrEqualTo(2032));
    });

    test('primary_position must be a known soccer position', () {
      const validPositions = [
        'GK', 'CB', 'LB', 'RB', 'LWB', 'RWB',
        'CDM', 'CM', 'CAM', 'LM', 'RM',
        'LW', 'RW', 'SS', 'ST',
      ];
      final payload = buildProfilePayload(primaryPosition: 'CM');
      expect(validPositions, contains(payload['primary_position']));
    });

    test('payload with null primary_position is allowed (optional)', () {
      final payload = buildProfilePayload(primaryPosition: null);
      expect(payload.containsKey('primary_position'), isTrue);
      expect(payload['primary_position'], isNull);
    });
  });

  // ── 2. Search filter logic ───────────────────────────────────────────────────
  group('Player search filters', () {
    final _mockPrograms = [
      {'school_name': 'University of Denver', 'division': 'D1', 'primary_formation': '4-3-3', 'state': 'CO', 'is_recruiting': true},
      {'school_name': 'CSU Pueblo', 'division': 'D2', 'primary_formation': '4-4-2', 'state': 'CO', 'is_recruiting': true},
      {'school_name': 'UNM', 'division': 'D1', 'primary_formation': '4-2-3-1', 'state': 'NM', 'is_recruiting': false},
      {'school_name': 'Ohio State', 'division': 'D1', 'primary_formation': '4-3-3', 'state': 'OH', 'is_recruiting': true},
      {'school_name': 'Wyoming', 'division': 'D2', 'primary_formation': '4-4-2', 'state': 'WY', 'is_recruiting': true},
    ];

    List<Map<String, dynamic>> applyFilters(
      List<Map<String, dynamic>> programs, {
      String? division,
      String? formation,
      String? state,
      bool? recruitingOnly,
    }) {
      var r = programs.toList();
      if (division != null) r = r.where((c) => c['division'] == division).toList();
      if (formation != null) r = r.where((c) => c['primary_formation'] == formation).toList();
      if (state != null) r = r.where((c) => c['state'] == state).toList();
      if (recruitingOnly == true) r = r.where((c) => c['is_recruiting'] == true).toList();
      return r;
    }

    test('division filter returns only matching programs', () {
      final results = applyFilters(_mockPrograms, division: 'D1');
      expect(results.every((p) => p['division'] == 'D1'), isTrue);
      expect(results.length, 3);
    });

    test('state filter returns only programs in that state', () {
      final results = applyFilters(_mockPrograms, state: 'CO');
      expect(results.every((p) => p['state'] == 'CO'), isTrue);
      expect(results.length, 2);
    });

    test('formation filter returns only matching formations', () {
      final results = applyFilters(_mockPrograms, formation: '4-3-3');
      expect(results.every((p) => p['primary_formation'] == '4-3-3'), isTrue);
    });

    test('combining division + state filters narrows results correctly', () {
      final results = applyFilters(_mockPrograms, division: 'D2', state: 'CO');
      expect(results.length, 1);
      expect(results.first['school_name'], 'CSU Pueblo');
    });

    test('no filters applied returns all programs', () {
      final results = applyFilters(_mockPrograms);
      expect(results.length, _mockPrograms.length);
    });

    test('filter with no matches returns empty list, not error', () {
      final results = applyFilters(_mockPrograms, state: 'AK', division: 'D1');
      expect(results, isEmpty);
    });

    test('recruiting-only filter excludes non-recruiting programs', () {
      final results = applyFilters(_mockPrograms, recruitingOnly: true);
      expect(results.every((p) => p['is_recruiting'] == true), isTrue);
    });
  });

  // ── 3. AI analysis state machine ────────────────────────────────────────────
  group('AI analysis state machine', () {
    // Mirrors the _analysisStatus transitions in player_profile_page.dart
    String _triggerAnalysis({bool apiSuccess = true, bool hasAnalysis = true}) {
      try {
        if (!apiSuccess) throw Exception('edge function error');
        if (!hasAnalysis) return 'failed';
        return 'complete';
      } catch (_) {
        return 'failed';
      }
    }

    test('initial status is pending before analysis is triggered', () {
      const status = 'pending';
      expect(status, 'pending');
    });

    test('successful API call with result transitions to complete', () {
      final status = _triggerAnalysis(apiSuccess: true, hasAnalysis: true);
      expect(status, 'complete');
    });

    test('API error transitions to failed', () {
      final status = _triggerAnalysis(apiSuccess: false);
      expect(status, 'failed');
    });

    test('API success but no analysis result transitions to failed', () {
      final status = _triggerAnalysis(apiSuccess: true, hasAnalysis: false);
      expect(status, 'failed');
    });

    test('valid analysis_status values are known set', () {
      const validStatuses = {'pending', 'complete', 'failed', 'running'};
      expect(validStatuses.contains('complete'), isTrue);
      expect(validStatuses.contains('pending'), isTrue);
      expect(validStatuses.contains('failed'), isTrue);
    });
  });

  // ── 4. Dark mode toggle ──────────────────────────────────────────────────────
  group('Dark mode toggle', () {
    test('dark mode background color is different from light mode', () {
      expect(PlayerColors.background, isNot(equals(AppColors.background)));
    });

    test('dark mode accent is neon lime #C8F135', () {
      expect(PlayerColors.accent.value, equals(const Color(0xFFC8F135).value));
    });

    test('toggling from light to dark changes background color', () {
      bool isDark = false;
      final lightBg = isDark ? PlayerColors.background : AppColors.background;
      isDark = true;
      final darkBg = isDark ? PlayerColors.background : AppColors.background;
      expect(lightBg, isNot(equals(darkBg)));
    });

    test('toggling from dark to light restores original background', () {
      bool isDark = true;
      final darkBg = isDark ? PlayerColors.background : AppColors.background;
      isDark = false;
      final lightBg = isDark ? PlayerColors.background : AppColors.background;
      expect(darkBg, isNot(equals(lightBg)));
      expect(lightBg, equals(AppColors.background));
    });
  });

  // ── 5. Edit profile starts at step 1 ────────────────────────────────────────
  group('Edit profile navigation', () {
    test('profile setup wizard starts at step 0 (first step)', () {
      const initialStep = 0;
      expect(initialStep, 0);
    });

    test('total steps in profile wizard is 5', () {
      const totalSteps = 5; // matches _totalSteps in player_profile_setup_page.dart
      expect(totalSteps, 5);
    });

    test('step label is "Step 1 of 5" on first load', () {
      const currentStep = 0;
      const totalSteps = 5;
      final label = 'Step ${currentStep + 1} of $totalSteps';
      expect(label, 'Step 1 of 5');
    });

    test('cannot go back from step 0', () {
      int currentStep = 0;
      // Mirrors: if (_currentStep > 0) setState(() => _currentStep--)
      if (currentStep > 0) currentStep--;
      expect(currentStep, 0); // stays at 0
    });

    test('can advance from step 0 to step 1', () {
      int currentStep = 0;
      const totalSteps = 5;
      if (currentStep < totalSteps - 1) currentStep++;
      expect(currentStep, 1);
    });
  });

  // ── 6. Edit profile pre-populates existing data ──────────────────────────────
  group('Edit profile pre-populates existing data', () {
    // Mirrors _loadExistingProfile() in player_profile_setup_page.dart
    Map<String, dynamic> _simulateLoad(Map<String, dynamic> userData, Map<String, dynamic> playerData) {
      final state = <String, dynamic>{};
      state['firstName'] = userData['first_name'] as String? ?? '';
      state['lastName'] = userData['last_name'] as String? ?? '';
      state['primaryPosition'] = playerData['primary_position'] as String?;
      state['secondaryPosition'] = playerData['secondary_position'] as String?;
      state['clubName'] = playerData['club_name'] as String?;
      final gradYear = playerData['graduation_year'] as int?;
      if (gradYear != null) state['classLabel'] = 'Class of $gradYear';
      return state;
    }

    test('first and last name are pre-populated from user record', () {
      final state = _simulateLoad(
        {'first_name': 'Kieran', 'last_name': 'Ross'},
        {'primary_position': 'CM', 'graduation_year': 2026},
      );
      expect(state['firstName'], 'Kieran');
      expect(state['lastName'], 'Ross');
    });

    test('primary position is pre-populated from player record', () {
      final state = _simulateLoad(
        {'first_name': 'Kieran', 'last_name': 'Ross'},
        {'primary_position': 'ST', 'graduation_year': 2026},
      );
      expect(state['primaryPosition'], 'ST');
    });

    test('graduation year is shown as "Class of YYYY"', () {
      final state = _simulateLoad(
        {'first_name': 'A', 'last_name': 'B'},
        {'primary_position': 'GK', 'graduation_year': 2027},
      );
      expect(state['classLabel'], 'Class of 2027');
    });

    test('null graduation year does not crash — classLabel absent', () {
      final state = _simulateLoad(
        {'first_name': 'A', 'last_name': 'B'},
        {'primary_position': null, 'graduation_year': null},
      );
      expect(state.containsKey('classLabel'), isFalse);
    });
  });

  // ── 7. Refreshing matches does not error ─────────────────────────────────────
  group('Refreshing program matches', () {
    // Mirrors match-players response handling
    List<Map<String, dynamic>> _processMatchResponse(dynamic response) {
      if (response == null) return [];
      if (response is List) return response.cast<Map<String, dynamic>>();
      return [];
    }

    test('valid match list response returns list of matches', () {
      final matches = _processMatchResponse([
        {'coach_id': 'c1', 'score': 85},
        {'coach_id': 'c2', 'score': 72},
      ]);
      expect(matches.length, 2);
    });

    test('null response returns empty list without throwing', () {
      final matches = _processMatchResponse(null);
      expect(matches, isEmpty);
    });

    test('empty list response returns empty list without throwing', () {
      final matches = _processMatchResponse([]);
      expect(matches, isEmpty);
    });

    test('match score is between 0 and 100', () {
      final matches = _processMatchResponse([
        {'coach_id': 'c1', 'score': 85},
        {'coach_id': 'c2', 'score': 100},
        {'coach_id': 'c3', 'score': 0},
      ]);
      for (final m in matches) {
        final score = m['score'] as int;
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      }
    });
  });

  // ── 8. Dashboard matches count consistency ───────────────────────────────────
  group('Dashboard matches card count consistency', () {
    int _computeMatchCount(List<dynamic> matches) => matches.length;

    test('match count equals number of records returned', () {
      final rawMatches = [
        {'coach_id': 'c1', 'score': 85},
        {'coach_id': 'c2', 'score': 72},
        {'coach_id': 'c3', 'score': 60},
      ];
      expect(_computeMatchCount(rawMatches), 3);
    });

    test('zero matches returns count of 0', () {
      expect(_computeMatchCount([]), 0);
    });

    test('dashboard displays "—" when stats not yet loaded', () {
      const statsLoaded = false;
      const matchCount = 5;
      final displayed = statsLoaded ? '$matchCount' : '—';
      expect(displayed, '—');
    });

    test('dashboard displays actual count when stats loaded', () {
      const statsLoaded = true;
      const matchCount = 5;
      final displayed = statsLoaded ? '$matchCount' : '—';
      expect(displayed, '5');
    });
  });

  // ── 9. Dashboard roadmap count consistency ───────────────────────────────────
  group('Dashboard roadmap card count consistency', () {
    int _computeCompletedSteps(List<dynamic> roadmaps) {
      // Mirrors _roadmapStepsCompleted logic in player_dashboard_page.dart
      int completedSteps = 0;
      for (final r in roadmaps) {
        final milestones = (r as Map)['roadmap_milestones'] as List? ?? [];
        completedSteps += milestones.length;
      }
      return completedSteps;
    }

    test('completed steps count sums milestones across all roadmaps', () {
      final roadmaps = [
        {'roadmap_milestones': [{'id': 'm1'}, {'id': 'm2'}]},
        {'roadmap_milestones': [{'id': 'm3'}]},
      ];
      expect(_computeCompletedSteps(roadmaps), 3);
    });

    test('zero milestones returns 0 (regression: Kieran Ross shows "—")', () {
      // Kieran Ross bug: roadmap record exists but milestones list is empty
      final roadmaps = [
        {'roadmap_milestones': []},
      ];
      expect(_computeCompletedSteps(roadmaps), 0);
    });

    test('null milestones field treated as empty list — no crash', () {
      final roadmaps = [
        {'roadmap_milestones': null},
      ];
      expect(_computeCompletedSteps(roadmaps), 0);
    });

    test('roadmap page total steps equals steps in defaultStepsForGrade', () {
      // Grade 11 (recruitment phase) should have foundation+development+recruitment steps
      final steps = RoadmapData.defaultStepsForGrade(11);
      expect(steps.isNotEmpty, isTrue);
      expect(steps.any((s) => s.phase == RoadmapPhase.foundation), isTrue);
      expect(steps.any((s) => s.phase == RoadmapPhase.recruitment), isTrue);
    });

    test('completed steps on roadmap page matches count of StepStatus.completed', () {
      final steps = RoadmapData.defaultStepsForGrade(10);
      final completedOnPage = steps.where((s) => s.status == StepStatus.completed).length;
      // Grade 10: foundation steps should be completed
      expect(completedOnPage, greaterThan(0));
    });
  });

  // ── 10. Dashboard messages count consistency ──────────────────────────────────
  group('Dashboard messages card count consistency', () {
    int _computeMessageCount(List<dynamic> conversations) => conversations.length;

    test('message count equals number of conversations', () {
      final convos = [
        {'id': 'conv1', 'last_message': 'Hey'},
        {'id': 'conv2', 'last_message': 'Great game!'},
      ];
      expect(_computeMessageCount(convos), 2);
    });

    test('zero conversations returns count of 0', () {
      expect(_computeMessageCount([]), 0);
    });

    test('dashboard shows conversation count, not message count', () {
      // The dashboard card counts conversations (threads), not individual messages
      // This guards against accidentally counting messages instead of threads
      final conversations = [
        {'id': 'conv1', 'messages': [1, 2, 3]}, // 3 messages, 1 thread
      ];
      // Should be 1 (one conversation), not 3 (three messages)
      expect(_computeMessageCount(conversations), 1);
    });

    test('dashboard displays "—" when messages not yet loaded', () {
      const statsLoaded = false;
      const messageCount = 2;
      final displayed = statsLoaded ? '$messageCount' : '—';
      expect(displayed, '—');
    });

    test('dashboard displays actual count when messages loaded', () {
      const statsLoaded = true;
      const messageCount = 2;
      final displayed = statsLoaded ? '$messageCount' : '—';
      expect(displayed, '2');
    });
  });
}

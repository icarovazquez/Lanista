import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_data.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';

/// Displays college program matches ranked by the Lanista matching engine.
/// Each card shows the match score breakdown and key reasons.
class PlayerMatchesPage extends StatefulWidget {
  const PlayerMatchesPage({super.key});

  @override
  State<PlayerMatchesPage> createState() => _PlayerMatchesPageState();
}

class _PlayerMatchesPageState extends State<PlayerMatchesPage> {
  List<Map<String, dynamic>> _matches = [];
  Set<String> _coachIdsWithOpenings = {};
  bool _isLoading = true;
  bool _isRunningEngine = false;
  // ignore: unused_field
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // player_coach_matches.player_id references players.id (not users.id)
      final playerRecord = await Supabase.instance.client
          .from('players')
          .select('id, primary_position, graduation_year')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerRecord == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final playerId        = playerRecord['id'] as String;
      final playerPosition  = (playerRecord['primary_position'] as String?)?.toLowerCase() ?? '';
      final playerGradYear  = playerRecord['graduation_year'] as int?;

      final data = await Supabase.instance.client
          .from('player_coach_matches')
          .select('''
            total_score,
            tactical_score,
            position_score,
            physical_score,
            academic_score,
            timeline_score,
            match_reasons,
            match_gaps,
            last_computed_at,
            coaches!inner(
              id,
              school_name,
              division,
              primary_formation,
              assistant_staff,
              users(first_name, last_name, email)
            )
          ''')
          .eq('player_id', playerId)
          .order('total_score', ascending: false)
          .limit(50);

      debugPrint('PlayerMatchesPage: loaded ${(data as List).length} matches');
      final matches = List<Map<String, dynamic>>.from(data);

      // Find coaches with roster openings at the player's position + graduation year
      Set<String> openingCoachIds = {};
      if (playerPosition.isNotEmpty && playerGradYear != null) {
        try {
          final coachIds = matches
              .map((m) => (m['coaches'] as Map<String, dynamic>?)?['id'] as String?)
              .whereType<String>()
              .toList();
          if (coachIds.isNotEmpty) {
            final openings = await Supabase.instance.client
                .from('roster_slots')
                .select('coach_id')
                .eq('needs_recruit', true)
                .eq('graduation_year', playerGradYear)
                .filter('position_key', 'ilike', playerPosition)
                .inFilter('coach_id', coachIds);
            openingCoachIds = (openings as List)
                .map((r) => r['coach_id'] as String)
                .toSet();
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _coachIdsWithOpenings = openingCoachIds;
        });
      }
    } catch (e, st) {
      debugPrint('_loadMatches error: $e\n$st');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runMatchingEngine() async {
    setState(() => _isRunningEngine = true);
    try {
      await Supabase.instance.client.auth.refreshSession();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client.functions.invoke(
        'match-players',
        body: {'player_id': userId},
      );

      debugPrint('match-players status: ${response.status}, data: ${response.data}');

      if (response.status != 200) {
        throw Exception('Engine error (${response.status}): ${response.data}');
      }

      await _loadMatches();
    } catch (e) {
      debugPrint('_runMatchingEngine error: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isRunningEngine = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: PlayerColors.accent),
      );
    } else if (_matches.isEmpty) {
      body = _EmptyMatchesState(
        isRunning: _isRunningEngine,
        errorMessage: _errorMessage,
        onFindMatches: _runMatchingEngine,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadMatches,
        color: PlayerColors.accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_matches.length} Program Matches',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: PlayerColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Text(
                      'Ranked by fit score',
                      style: TextStyle(
                        fontSize: 12,
                        color: PlayerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _isRunningEngine ? null : _runMatchingEngine,
                  icon: _isRunningEngine
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: PlayerColors.accent,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _ScoreLegend(),
            const SizedBox(height: 16),
            ..._matches.asMap().entries.map((entry) {
              final coachId = (entry.value['coaches'] as Map<String, dynamic>?)?['id'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MatchCard(
                  match: entry.value,
                  rank: entry.key + 1,
                  hasOpening: coachId != null && _coachIdsWithOpenings.contains(coachId),
                ),
              );
            }),
          ],
        ),
      );
    }

    final themeService = getIt<PlayerThemeService>();
    return ListenableBuilder(
      listenable: themeService,
      builder: (ctx, _) => Theme(
        data: PlayerThemeData.dark,
        child: PlayerThemeScope(
          service: themeService,
          child: Scaffold(
            backgroundColor: PlayerColors.background,
            appBar: AppBar(
              backgroundColor: PlayerColors.background,
              foregroundColor: PlayerColors.textPrimary,
              iconTheme: const IconThemeData(color: PlayerColors.textPrimary),
              elevation: 0,
              title: const Text(
                'My Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PlayerColors.textPrimary,
                ),
              ),
            ),
            body: body,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────────

class _EmptyMatchesState extends StatelessWidget {
  final bool isRunning;
  final String? errorMessage;
  final VoidCallback onFindMatches;

  const _EmptyMatchesState({
    required this.isRunning,
    required this.onFindMatches,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: PlayerColors.accentDim,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Find Your Matches',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: PlayerColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete your profile and run the matching engine to see which college programs fit your style, position, and academic profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: PlayerColors.textPrimary,
                height: 1.6,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: isRunning ? null : onFindMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayerColors.accent,
                foregroundColor: PlayerColors.textOnAccent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: isRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A0A)),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                isRunning ? 'Finding matches...' : 'Find My Matches',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PlayerColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: PlayerColors.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scores programs on tactical fit (35%), position need (25%), physical profile (20%), academics (15%), and timeline (5%).',
                      style: TextStyle(
                        fontSize: 13,
                        color: PlayerColors.textSecondary,
                        height: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0000),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade900),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          height: 1.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Score Legend ───────────────────────────────────────────────────────────────

class _ScoreLegend extends StatelessWidget {
  const _ScoreLegend();

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem('Tactical', '35%', AppColors.coachColor),
          _LegendItem('Position', '25%', AppColors.playerColor),
          _LegendItem('Physical', '20%', AppColors.mentorColor),
          _LegendItem('Academic', '15%', const Color(0xFF7B1FA2)),
          _LegendItem('Timeline', '5%', AppColors.secondary),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String weight;
  final Color color;

  const _LegendItem(this.label, this.weight, this.color);

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
          ),
        ),
        Text(
          weight,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Email helper ───────────────────────────────────────────────────────────────

Future<void> _launchStaffEmail({
  required BuildContext context,
  required List<String> emails,
  required String schoolName,
}) async {
  final subject = Uri.encodeComponent('Recruiting Inquiry — $schoolName');
  final uri = Uri.parse('mailto:${emails.join(',')}?subject=$subject');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open email app. Try: ${emails.first}')),
    );
  }
}

// ─── Match Card ─────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final int rank;
  final bool hasOpening;

  const _MatchCard({required this.match, required this.rank, this.hasOpening = false});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);

    final coach = match['coaches'] as Map<String, dynamic>? ?? {};
    final user = coach['users'] as Map<String, dynamic>? ?? {};
    final schoolName = coach['school_name'] as String? ?? 'Unknown Program';
    final division = coach['division'] as String? ?? '';
    final formation = coach['primary_formation'] as String? ?? '';
    final coachName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final coachEmail = user['email'] as String? ?? '';
    final assistantStaff = (coach['assistant_staff'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Collect all unique emails — assistant_staff is the canonical source (includes HC + ACs)
    final allEmails = assistantStaff
        .map((s) => (s['email'] as String? ?? '').trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    // Fallback to users.email if assistant_staff wasn't populated yet
    if (allEmails.isEmpty && coachEmail.isNotEmpty) allEmails.add(coachEmail.toLowerCase());
    final totalScore    = ((match['total_score']    as num?) ?? 0).round();
    final tacticalScore = ((match['tactical_score'] as num?) ?? 0).round();
    final positionScore = ((match['position_score'] as num?) ?? 0).round();
    final physicalScore = ((match['physical_score'] as num?) ?? 0).round();
    final academicScore = ((match['academic_score'] as num?) ?? 0).round();
    final timelineScore = ((match['timeline_score'] as num?) ?? 0).round();
    final reasons = ((match['match_reasons'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final gaps = ((match['match_gaps'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    final scoreColor = isDark
        ? PlayerColors.scoreColor(totalScore)
        : (totalScore >= 75
            ? AppColors.playerColor
            : totalScore >= 55
                ? AppColors.secondary
                : AppColors.textSecondary);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1 && isDark
              ? PlayerColors.accent.withValues(alpha: 0.4)
              : rank == 1
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : (isDark ? PlayerColors.border : AppColors.border),
          width: rank == 1 ? 2 : 1,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : (isDark ? PlayerColors.surfaceVariant : AppColors.surface),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 16 : 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              schoolName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (rank == 1 && totalScore >= 75) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PlayerColors.accent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'HOT',
                                style: TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.w900,
                                  color: Color(0xFF0A0A0A), letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                          if (hasOpening) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3A1A),
                                border: Border.all(color: PlayerColors.accent, width: 1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'OPEN SPOT',
                                style: TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.w900,
                                  color: PlayerColors.accent, letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (division.isNotEmpty) ...[
                            Text(
                              division,
                              style: const TextStyle(
                                fontSize: 12,
                                color: PlayerColors.textPrimary,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: PlayerColors.textPrimary,
                              ),
                            ),
                          ],
                          if (formation.isNotEmpty)
                            Text(
                              formation,
                              style: const TextStyle(
                                fontSize: 12,
                                color: PlayerColors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                      if (coachName.isNotEmpty)
                        Text(
                          'Coach $coachName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: PlayerColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Total score circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.1),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$totalScore',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'pts',
                        style: TextStyle(fontSize: 9, color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Score bar breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ScoreBreakdownBar(
              tactical: tacticalScore,
              position: positionScore,
              physical: physicalScore,
              academic: academicScore,
              timeline: timelineScore,
            ),
          ),
          // Top reasons + gap count badge
          if (reasons.isNotEmpty || gaps.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Up to 2 hit chips
                  ...reasons.take(2).map((reason) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? PlayerColors.accentSubtle
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 10,
                            color: isDark ? PlayerColors.accent : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(reason,
                          style: TextStyle(fontSize: 10,
                              color: isDark ? PlayerColors.accent : AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  // Gap count badge
                  if (gaps.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2D1F0A)
                            : const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 10,
                              color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            '${gaps.length} gap${gaps.length > 1 ? 's' : ''} · tap to see',
                            style: const TextStyle(fontSize: 10,
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      side: BorderSide(
                        color: isDark ? PlayerColors.border : AppColors.border,
                      ),
                      foregroundColor: isDark ? PlayerColors.textPrimary : null,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => _ProgramDetailSheet(
                          schoolName: schoolName,
                          division: division,
                          formation: formation,
                          coachName: coachName,
                          allEmails: allEmails,
                          assistantStaff: assistantStaff,
                          totalScore: totalScore,
                          tacticalScore: tacticalScore,
                          positionScore: positionScore,
                          physicalScore: physicalScore,
                          academicScore: academicScore,
                          timelineScore: timelineScore,
                          reasons: reasons,
                          gaps: gaps,
                          scoreColor: scoreColor,
                          isDark: isDark,
                        ),
                      );
                    },
                    child: const Text('View Program', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
                      foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                    ),
                    icon: const Icon(Icons.email_outlined, size: 14),
                    onPressed: allEmails.isEmpty ? null : () => _launchStaffEmail(
                      context: context,
                      emails: allEmails,
                      schoolName: schoolName,
                    ),
                    label: Text(
                      allEmails.isEmpty
                          ? 'No Email on File'
                          : 'Email Staff (${allEmails.length})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Program Detail Bottom Sheet ────────────────────────────────────────────────

class _ProgramDetailSheet extends StatelessWidget {
  final String schoolName;
  final String division;
  final String formation;
  final String coachName;
  final List<String> allEmails;
  final List<Map<String, dynamic>> assistantStaff;
  final int totalScore;
  final int tacticalScore;
  final int positionScore;
  final int physicalScore;
  final int academicScore;
  final int timelineScore;
  final List<String> reasons;
  final List<String> gaps;
  final Color scoreColor;
  final bool isDark;

  const _ProgramDetailSheet({
    required this.schoolName,
    required this.division,
    required this.formation,
    required this.coachName,
    required this.allEmails,
    required this.assistantStaff,
    required this.totalScore,
    required this.tacticalScore,
    required this.positionScore,
    required this.physicalScore,
    required this.academicScore,
    required this.timelineScore,
    required this.reasons,
    required this.gaps,
    required this.scoreColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? PlayerColors.surfaceElevated : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.border : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // School + score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (division.isNotEmpty)
                          Text(
                            division,
                            style: const TextStyle(
                              fontSize: 14,
                              color: PlayerColors.textPrimary,
                            ),
                          ),
                        if (division.isNotEmpty && formation.isNotEmpty)
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 14,
                              color: PlayerColors.textPrimary,
                            ),
                          ),
                        if (formation.isNotEmpty)
                          Text(
                            formation,
                            style: const TextStyle(
                              fontSize: 14,
                              color: PlayerColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                    if (coachName.isNotEmpty)
                      Text(
                        'Coach $coachName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: PlayerColors.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.1),
                  border: Border.all(color: scoreColor, width: 2.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalScore',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                    Text('pts', style: TextStyle(fontSize: 10, color: scoreColor)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Score breakdown
          Text(
            'Score Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _ScoreBreakdownBar(
            tactical: tacticalScore,
            position: positionScore,
            physical: physicalScore,
            academic: academicScore,
            timeline: timelineScore,
          ),

          // Why this program — hits
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.check_circle, size: 14,
                    color: isDark ? PlayerColors.accent : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Why This Program',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 13,
                      color: isDark ? PlayerColors.accent : AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r,
                      style: TextStyle(fontSize: 12,
                          color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary)),
                  ),
                ],
              ),
            )),
          ],

          // What's holding you back — gaps
          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14,
                    color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  'What\'s Holding You Back',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D1F0A)
                    : const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF6B4C1A)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                children: gaps.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 13,
                          color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(g,
                          style: TextStyle(fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFFFD580)
                                  : const Color(0xFF92400E))),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],

          // Coaching Staff section
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 14,
                  color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Coaching Staff',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (assistantStaff.isEmpty)
            Text(
              coachName.isNotEmpty ? 'Coach $coachName' : 'Staff info loading…',
              style: const TextStyle(fontSize: 13, color: PlayerColors.textSecondary),
            )
          else
            ...assistantStaff.map((s) {
              final name = s['name'] as String? ?? '';
              final title = s['title'] as String? ?? '';
              final email = (s['email'] as String? ?? '').trim();
              // Skip entries where name is actually a role string (inverted-table schools)
              final displayName = _looksLikeRoleString(name) ? null : name;
              final displayTitle = _looksLikeRoleString(name) ? name : title;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? PlayerColors.surfaceVariant : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline, size: 15,
                          color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (displayName != null)
                            Text(displayName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary)),
                          if (displayTitle.isNotEmpty)
                            Text(_shortenTitle(displayTitle),
                              style: const TextStyle(fontSize: 11, color: PlayerColors.textSecondary)),
                          Text(email,
                            style: const TextStyle(fontSize: 11, color: PlayerColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: isDark ? PlayerColors.border : AppColors.border),
                    foregroundColor: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              if (allEmails.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Builder(builder: (ctx) => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
                      foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.email_outlined, size: 16),
                    onPressed: () => _launchStaffEmail(
                      context: ctx,
                      emails: allEmails,
                      schoolName: schoolName,
                    ),
                    label: Text(
                      'Email All Staff (${allEmails.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

bool _looksLikeRoleString(String s) {
  final lower = s.toLowerCase();
  return lower.startsWith('head ') || lower.startsWith('assistant ') ||
      lower.startsWith('associate ') || lower.startsWith('graduate ') ||
      lower.startsWith('director ');
}

// Keep titles readable — truncate verbose titles like "Associate Head Coach/Director of..."
String _shortenTitle(String title) {
  final slash = title.indexOf('/');
  if (slash > 0 && title.length > 40) return title.substring(0, slash).trim();
  return title.length > 48 ? '${title.substring(0, 45)}…' : title;
}

// ─── Score Breakdown Bar ────────────────────────────────────────────────────────

class _ScoreBreakdownBar extends StatelessWidget {
  final int tactical;
  final int position;
  final int physical;
  final int academic;
  final int timeline;

  const _ScoreBreakdownBar({
    required this.tactical,
    required this.position,
    required this.physical,
    required this.academic,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScoreBar('Tactical', tactical, 35, AppColors.coachColor),
        const SizedBox(height: 4),
        _ScoreBar('Position', position, 25, AppColors.playerColor),
        const SizedBox(height: 4),
        _ScoreBar('Physical', physical, 20, AppColors.mentorColor),
        const SizedBox(height: 4),
        _ScoreBar('Academic', academic, 15, const Color(0xFF7B1FA2)),
        const SizedBox(height: 4),
        _ScoreBar('Timeline', timeline, 5, AppColors.secondary),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final Color color;

  const _ScoreBar(this.label, this.score, this.maxScore, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = maxScore > 0 ? score / maxScore : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: PlayerColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$score/$maxScore',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PlayerColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

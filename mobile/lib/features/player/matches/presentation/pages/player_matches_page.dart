import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Displays college program matches ranked by the Lanista matching engine.
/// Each card shows the match score breakdown and key reasons.
class PlayerMatchesPage extends StatefulWidget {
  const PlayerMatchesPage({super.key});

  @override
  State<PlayerMatchesPage> createState() => _PlayerMatchesPageState();
}

class _PlayerMatchesPageState extends State<PlayerMatchesPage> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  bool _isRunningEngine = false;
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
            last_computed_at,
            coaches!inner(
              id,
              school_name,
              division,
              primary_formation_id,
              users!inner(first_name, last_name)
            )
          ''')
          .eq('player_id', userId)
          .order('total_score', ascending: false)
          .limit(50);

      if (mounted) setState(() => _matches = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runMatchingEngine() async {
    setState(() => _isRunningEngine = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.functions.invoke(
        'match-players',
        body: {'player_id': userId},
      );
      await _loadMatches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not run matching engine: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningEngine = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_matches.isEmpty) {
      return _EmptyMatchesState(
        isRunning: _isRunningEngine,
        onFindMatches: _runMatchingEngine,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_matches.length} Program Matches',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Ranked by fit score',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _isRunningEngine ? null : _runMatchingEngine,
                icon: _isRunningEngine
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Score legend
          const _ScoreLegend(),
          const SizedBox(height: 16),
          // Match cards
          ..._matches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MatchCard(
                match: match,
                rank: index + 1,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────────

class _EmptyMatchesState extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onFindMatches;

  const _EmptyMatchesState({
    required this.isRunning,
    required this.onFindMatches,
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
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your profile and run the matching engine to see which college programs fit your style, position, and academic profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isRunning ? null : onFindMatches,
              icon: isRunning
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(isRunning ? 'Finding matches...' : 'Find My Matches'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lanista scores programs on tactical fit (35%), position need (25%), physical profile (20%), academics (15%), and timeline (5%).',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
    return Column(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        Text(weight, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

// ─── Match Card ─────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final int rank;

  const _MatchCard({required this.match, required this.rank});

  @override
  Widget build(BuildContext context) {
    final coach = match['coaches'] as Map<String, dynamic>? ?? {};
    final user = coach['users'] as Map<String, dynamic>? ?? {};
    final schoolName = coach['school_name'] as String? ?? 'Unknown Program';
    final division = coach['division'] as String? ?? '';
    final formation = coach['primary_formation_id'] as String? ?? '';
    final coachName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final totalScore = match['total_score'] as int? ?? 0;
    final tacticalScore = match['tactical_score'] as int? ?? 0;
    final positionScore = match['position_score'] as int? ?? 0;
    final physicalScore = match['physical_score'] as int? ?? 0;
    final academicScore = match['academic_score'] as int? ?? 0;
    final timelineScore = match['timeline_score'] as int? ?? 0;
    final reasons = (match['match_reasons'] as List?)?.cast<String>() ?? [];

    final scoreColor = totalScore >= 75
        ? AppColors.playerColor
        : totalScore >= 55
            ? AppColors.secondary
            : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? AppColors.secondary.withValues(alpha: 0.5)
              : AppColors.border,
          width: rank == 1 ? 2 : 1,
        ),
        boxShadow: rank <= 3
            ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )]
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
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 16 : 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          if (division.isNotEmpty) ...[
                            Text(division,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
                            const Text(' • ',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
                          ],
                          if (formation.isNotEmpty)
                            Text(formation,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      if (coachName.isNotEmpty)
                        Text('Coach $coachName',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
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
          // Top reasons
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: reasons.take(3).map((reason) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 10, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
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
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {},
                    child: const Text('View Program',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {},
                    child: const Text('Message Coach',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
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
          width: 56,
          child: Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 28,
          child: Text(
            '$score/$maxScore',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

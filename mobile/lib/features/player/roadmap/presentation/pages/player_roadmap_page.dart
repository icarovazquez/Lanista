import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../data/roadmap_models.dart';

/// Player development roadmap — a visual timeline of steps from 6th grade
/// through college commitment, personalized by grade level and target school.
///
/// This widget is a tab inside PlayerDashboardPage, so it is already inside
/// a PlayerThemeScope. All sub-widgets use PlayerThemeScope.isDark(context).
/// The _StepDetailSheet is launched via showModalBottomSheet (outside the
/// scope tree), so isDark is captured before the call and passed as a param.
class PlayerRoadmapPage extends StatefulWidget {
  const PlayerRoadmapPage({super.key});

  @override
  State<PlayerRoadmapPage> createState() => _PlayerRoadmapPageState();
}

class _PlayerRoadmapPageState extends State<PlayerRoadmapPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RoadmapStep> _steps = [];
  bool _isLoading = true;
  int _playerGrade = 10; // Default, loaded from profile

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadRoadmap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoadmap() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('players')
            .select('grade_level')
            .eq('user_id', userId)
            .maybeSingle();
        if (data != null && data['grade_level'] != null) {
          _playerGrade = data['grade_level'] as int;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _steps = RoadmapData.defaultStepsForGrade(_playerGrade);
        _isLoading = false;
      });
    }
  }

  List<RoadmapStep> _stepsForPhase(RoadmapPhase phase) =>
      _steps.where((s) => s.phase == phase).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  int _completedCount(RoadmapPhase phase) =>
      _stepsForPhase(phase)
          .where((s) => s.status == StepStatus.completed)
          .length;

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? PlayerColors.accent : AppColors.primary,
        ),
      );
    }

    final totalSteps = _steps.length;
    final completedSteps =
        _steps.where((s) => s.status == StepStatus.completed).length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Column(
      children: [
        // Header progress card
        _RoadmapHeaderCard(
          grade: _playerGrade,
          completed: completedSteps,
          total: totalSteps,
          progress: progress,
        ),
        // Phase tabs
        Container(
          color: isDark ? PlayerColors.surface : AppColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: isDark ? PlayerColors.accent : AppColors.primary,
            unselectedLabelColor: isDark
                ? PlayerColors.textSecondary
                : AppColors.textSecondary,
            indicatorColor: isDark ? PlayerColors.accent : AppColors.primary,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: [
              _PhaseTab(
                l10n?.roadmapPhaseFoundation ?? 'Foundation',
                '6–8',
                _completedCount(RoadmapPhase.foundation),
                _stepsForPhase(RoadmapPhase.foundation).length,
              ),
              _PhaseTab(
                l10n?.roadmapPhaseDevelopment ?? 'Development',
                '9–10',
                _completedCount(RoadmapPhase.development),
                _stepsForPhase(RoadmapPhase.development).length,
              ),
              _PhaseTab(
                l10n?.roadmapPhaseRecruitment ?? 'Recruitment',
                '11th',
                _completedCount(RoadmapPhase.recruitment),
                _stepsForPhase(RoadmapPhase.recruitment).length,
              ),
              _PhaseTab(
                l10n?.roadmapPhaseCommitment ?? 'Commitment',
                '12th',
                _completedCount(RoadmapPhase.commitment),
                _stepsForPhase(RoadmapPhase.commitment).length,
              ),
              const Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💰 Financial', overflow: TextOverflow.ellipsis, softWrap: false),
                    Text('Aid & Costs', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Steps list per phase
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PhaseStepsList(
                steps: _stepsForPhase(RoadmapPhase.foundation),
                phaseColor: const Color(0xFF4CAF50),
                onStepTap: _showStepDetail,
                onToggleComplete: _toggleStepComplete,
              ),
              _PhaseStepsList(
                steps: _stepsForPhase(RoadmapPhase.development),
                phaseColor: const Color(0xFF2196F3),
                onStepTap: _showStepDetail,
                onToggleComplete: _toggleStepComplete,
              ),
              _PhaseStepsList(
                steps: _stepsForPhase(RoadmapPhase.recruitment),
                phaseColor: AppColors.secondary,
                onStepTap: _showStepDetail,
                onToggleComplete: _toggleStepComplete,
              ),
              _PhaseStepsList(
                steps: _stepsForPhase(RoadmapPhase.commitment),
                phaseColor: AppColors.mentorColor,
                onStepTap: _showStepDetail,
                onToggleComplete: _toggleStepComplete,
              ),
              const _FinancialTab(),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleStepComplete(RoadmapStep step) {
    setState(() {
      final index = _steps.indexWhere((s) => s.id == step.id);
      if (index != -1) {
        final current = _steps[index];
        final newStatus = current.status == StepStatus.completed
            ? StepStatus.available
            : StepStatus.completed;
        _steps[index] = RoadmapStep(
          id: current.id,
          title: current.title,
          description: current.description,
          descriptionEs: current.descriptionEs,
          phase: current.phase,
          category: current.category,
          status: newStatus,
          orderIndex: current.orderIndex,
          actionItems: current.actionItems,
          isPremium: current.isPremium,
        );
      }
    });
  }

  // Capture isDark BEFORE showModalBottomSheet because the bottom sheet is
  // built in a new subtree that has no PlayerThemeScope ancestor.
  void _showStepDetail(RoadmapStep step) {
    final isDark = PlayerThemeScope.isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StepDetailSheet(
        step: step,
        isDark: isDark,
        onToggleComplete: () {
          _toggleStepComplete(step);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── Header Progress Card ───────────────────────────────────────────────────────

class _RoadmapHeaderCard extends StatelessWidget {
  final int grade;
  final int completed;
  final int total;
  final double progress;

  const _RoadmapHeaderCard({
    required this.grade,
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [PlayerColors.gradientStart, PlayerColors.gradientEnd]
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Recruiting Roadmap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grade $grade Player',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completed / $total done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% complete — keep going! 🚀',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Tab ──────────────────────────────────────────────────────────────────

class _PhaseTab extends Tab {
  _PhaseTab(String label, String grade, int completed, int total)
      : super(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, overflow: TextOverflow.ellipsis, softWrap: false),
              Text(
                grade,
                style:
                    const TextStyle(fontSize: 9, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 2),
              if (total > 0)
                Text(
                  '$completed/$total',
                  style: const TextStyle(fontSize: 9),
                ),
            ],
          ),
        );
}

// ─── Phase Steps List ───────────────────────────────────────────────────────────

class _PhaseStepsList extends StatelessWidget {
  final List<RoadmapStep> steps;
  final Color phaseColor;
  final ValueChanged<RoadmapStep> onStepTap;
  final ValueChanged<RoadmapStep> onToggleComplete;

  const _PhaseStepsList({
    required this.steps,
    required this.phaseColor,
    required this.onStepTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);

    if (steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'This phase unlocks as you progress',
              style: TextStyle(
                color: isDark
                    ? PlayerColors.textSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return _RoadmapStepCard(
          step: step,
          phaseColor: phaseColor,
          isLast: isLast,
          onTap: () => onStepTap(step),
          onToggle: () => onToggleComplete(step),
        );
      },
    );
  }
}

// ─── Roadmap Step Card ──────────────────────────────────────────────────────────

class _RoadmapStepCard extends StatelessWidget {
  final RoadmapStep step;
  final Color phaseColor;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _RoadmapStepCard({
    required this.step,
    required this.phaseColor,
    required this.isLast,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final isCompleted = step.status == StepStatus.completed;
    final isLocked = step.status == StepStatus.locked;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: isLocked ? null : onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? phaseColor
                          : (isDark ? PlayerColors.surface : Colors.white),
                      border: Border.all(
                        color: isLocked
                            ? AppColors.border
                            : isCompleted
                                ? phaseColor
                                : phaseColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : isLocked
                              ? Icons.lock_outline
                              : Icons.circle_outlined,
                      size: 14,
                      color: isCompleted
                          ? Colors.white
                          : isLocked
                              ? AppColors.border
                              : phaseColor,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: phaseColor.withValues(alpha: 0.25),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: GestureDetector(
                onTap: isLocked ? null : onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? phaseColor.withValues(alpha: 0.06)
                        : (isDark ? PlayerColors.surface : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCompleted
                          ? phaseColor.withValues(alpha: 0.3)
                          : (isDark ? PlayerColors.border : AppColors.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isLocked
                                    ? (isDark
                                        ? PlayerColors.textTertiary
                                        : AppColors.textSecondary)
                                    : (isDark
                                        ? PlayerColors.textPrimary
                                        : AppColors.textPrimary),
                                decoration: isCompleted
                                    ? TextDecoration.none
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CategoryBadge(category: step.category),
                          if (step.isPremium) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? PlayerColors.textSecondary
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${step.actionItems.length} action items',
                            style: TextStyle(
                              fontSize: 11,
                              color: phaseColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: isDark
                                ? PlayerColors.textSecondary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final StepCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (category) {
      StepCategory.technical => ('Technical', AppColors.coachColor),
      StepCategory.physical => ('Physical', AppColors.playerColor),
      StepCategory.academic => ('Academic', const Color(0xFF7B1FA2)),
      StepCategory.recruiting => ('Recruiting', AppColors.secondary),
      StepCategory.mental => ('Mental', AppColors.mentorColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Financial Tab ──────────────────────────────────────────────────────────────

class _FinancialTab extends StatelessWidget {
  const _FinancialTab();

  static const _divisionColor = Color(0xFF1B5E20);
  static const _scholarshipColor = Color(0xFF2E7D32);
  static const _costColor = Color(0xFF1565C0);
  static const _tipColor = Color(0xFF6A1B9A);
  static const _deadlineColor = Color(0xFFBF360C);

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final bg = isDark ? PlayerColors.background : const Color(0xFFF8F9FA);
    final cardBg = isDark ? PlayerColors.surface : Colors.white;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Header banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 Financial Aid Guide', style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text(
                'College soccer can be fully funded. Understand your options early — '
                'athletic scholarships stack with academic aid and need-based grants.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Scholarship by Division ──
        _SectionHeader('Scholarship by Division', Icons.school_outlined, _divisionColor),
        const SizedBox(height: 10),
        _DivisionCard(
          division: 'NCAA D1',
          color: const Color(0xFF1565C0),
          scholarshipNote: 'Up to full ride (tuition + room + board + books)',
          range: '\$20,000 – \$80,000 / yr',
          maxScholarships: '9.9 equivalencies per team (men) / 14 (women)',
          notes: 'Highly competitive. D1 programs can split scholarships — '
              'a "full ride" is rare; most athletes receive partial aid.',
          icon: '🏆',
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 10),
        _DivisionCard(
          division: 'NCAA D2',
          color: const Color(0xFF283593),
          scholarshipNote: '9.9 equivalencies (men) / 9.9 (women)',
          range: '\$5,000 – \$25,000 / yr',
          maxScholarships: '9.9 equivalencies per team',
          notes: 'More opportunities than D1. Solid programs that balance '
              'academics and athletics. Many D2 athletes get meaningful aid.',
          icon: '🥈',
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 10),
        _DivisionCard(
          division: 'NCAA D3',
          color: const Color(0xFF4527A0),
          scholarshipNote: 'No athletic scholarships — merit & need-based only',
          range: '\$5,000 – \$50,000 / yr (non-athletic aid)',
          maxScholarships: 'Unlimited merit/need-based aid',
          notes: 'D3 schools are often high-quality liberal arts colleges with '
              'strong academics. Financial aid packages can be very generous.',
          icon: '🎓',
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 10),
        _DivisionCard(
          division: 'NAIA',
          color: const Color(0xFF00695C),
          scholarshipNote: '12 equivalencies per team',
          range: '\$2,000 – \$20,000 / yr',
          maxScholarships: '12 equivalencies per team',
          notes: 'Often overlooked but great value. NAIA schools can offer '
              'athletic scholarships AND significant academic aid on top.',
          icon: '⭐',
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 10),
        _DivisionCard(
          division: 'JUCO (NJCAA)',
          color: const Color(0xFF558B2F),
          scholarshipNote: 'D1 JUCO: full rides available',
          range: '\$1,000 – \$15,000 / yr',
          maxScholarships: '18 scholarships (D1) / 8 (D2)',
          notes: 'Two-year path to a 4-year school. D1 JUCOs can offer full '
              'tuition + room & board. Great for development.',
          icon: '🔄',
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 24),

        // ── Stacking Aid ──
        _SectionHeader('Stacking Your Aid Package', Icons.layers_outlined, _scholarshipColor),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Athletic + Academic + Need = Full Funding',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary)),
              const SizedBox(height: 12),
              ...[
                ('⚽', 'Athletic Scholarship', 'Awarded by coach. Renewable annually. Can be partial.'),
                ('📚', 'Academic Merit Aid', 'Awarded by admissions based on GPA/SAT. Does NOT require being an athlete.'),
                ('💵', 'Need-Based Aid (FAFSA)', 'Federal/state grants based on family income. File FAFSA every October.'),
                ('🏛️', 'Institutional Grants', 'School-specific aid. Often generous at private schools.'),
              ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text(item.$3, style: TextStyle(fontSize: 12,
                            color: textSecondary, height: 1.4)),
                      ],
                    )),
                  ],
                ),
              )),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Average Annual Costs ──
        _SectionHeader('Average Annual College Costs', Icons.account_balance_outlined, _costColor),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
          ),
          child: Column(
            children: [
              _CostRow('Public In-State', '\$27,000', '\$3,000 – \$15,000', true, textPrimary, textSecondary),
              _CostRow('Public Out-of-State', '\$45,000', '\$5,000 – \$25,000', false, textPrimary, textSecondary),
              _CostRow('Private University', '\$60,000', '\$10,000 – \$60,000', true, textPrimary, textSecondary),
              _CostRow('NAIA / JUCO', '\$22,000', '\$5,000 – \$20,000', false, textPrimary, textSecondary),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text('* Includes tuition, room & board, and fees. Before aid.',
              style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic)),
        ),

        const SizedBox(height: 24),

        // ── Key Deadlines ──
        _SectionHeader('Key Financial Deadlines', Icons.calendar_today_outlined, _deadlineColor),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
          ),
          child: Column(
            children: [
              _DeadlineRow('🗓️ October 1', 'FAFSA opens for next academic year. File ASAP — aid is first-come, first-served.', _deadlineColor, textPrimary, textSecondary),
              _DeadlineRow('🗓️ November 1', 'Early Action / Early Decision deadlines for most universities.', _deadlineColor, textPrimary, textSecondary),
              _DeadlineRow('🗓️ February 1', 'Many schools\' financial aid priority deadline. Miss this = less aid.', _deadlineColor, textPrimary, textSecondary),
              _DeadlineRow('🗓️ April 1', 'CSS Profile deadline for many private schools (additional need-based form).', _deadlineColor, textPrimary, textSecondary),
              _DeadlineRow('🗓️ NLI Day', 'National Letter of Intent signing day (varies by sport). Locks in your athletic scholarship.', _deadlineColor, textPrimary, textSecondary),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Pro Tips ──
        _SectionHeader('Pro Tips', Icons.lightbulb_outline, _tipColor),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _tipColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _tipColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...[
                'Negotiate your aid package — coaches and financial aid offices expect it.',
                'A 3.8+ GPA can unlock automatic merit scholarships at most schools.',
                'Don\'t rule out D3 or NAIA — total cost after aid can be LOWER than a D1 partial scholarship.',
                'Always compare the "net price" (after all aid), not the sticker price.',
                'File FAFSA even if you think you won\'t qualify. Many families are surprised.',
                'Ask coaches specifically: "Is my scholarship renewable? Under what conditions?"',
              ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tip,
                        style: TextStyle(fontSize: 12, color: textPrimary, height: 1.4))),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Club Soccer Costs ──
        _SectionHeader('Club Soccer Investment', Icons.sports_soccer_outlined, const Color(0xFF0277BD)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'What families typically spend to develop a recruit-level player',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
          ),
          child: Column(children: [
            _ClubCostRow('Club Fees', '\$3,000 – \$8,000', 'Annual registration, field time, coaching staff', true, textPrimary, textSecondary),
            _ClubCostRow('Uniforms & Gear', '\$500 – \$1,500', 'Jersey sets, training kits, cleats, bags per year', false, textPrimary, textSecondary),
            _ClubCostRow('Tournament Fees', '\$2,000 – \$6,000', 'Entry fees for 8–15 tournaments per season', true, textPrimary, textSecondary),
            _ClubCostRow('Travel (per player)', '\$3,000 – \$10,000', 'Flights, hotels, food for regionals/nationals', false, textPrimary, textSecondary),
            _ClubCostRow('College ID Events', '\$500 – \$2,000', 'Showcases, college ID camps, recruiting events', true, textPrimary, textSecondary),
            _ClubCostRow('Private Training', '\$1,000 – \$5,000', 'Individual skill sessions, goalkeeper coaches', false, textPrimary, textSecondary),
          ]),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0277BD).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0277BD).withValues(alpha: 0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Annual Investment: \$10,000 – \$32,000',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textPrimary)),
            const SizedBox(height: 6),
            Text(
              'This is why understanding college financial aid matters — a D1 or D2 athletic '
              'scholarship can return your entire club soccer investment in the first year alone.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
            ),
          ]),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
          ),
          child: Row(
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Share this tab with your parents — your Lanista parent companion '
                'has a full financial planning dashboard with calculators and loan comparisons.',
                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
    ]);
  }
}

class _DivisionCard extends StatelessWidget {
  final String division, scholarshipNote, range, maxScholarships, notes, icon;
  final Color color;
  final Color cardBg, textPrimary, textSecondary;

  const _DivisionCard({
    required this.division, required this.color, required this.scholarshipNote,
    required this.range, required this.maxScholarships, required this.notes,
    required this.icon, required this.cardBg, required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(division, style: TextStyle(fontWeight: FontWeight.w800,
              fontSize: 14, color: color)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(range, style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(scholarshipNote, style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 4),
        Text('Max: $maxScholarships', style: TextStyle(fontSize: 11,
            color: textSecondary)),
        const SizedBox(height: 6),
        Text(notes, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4)),
      ]),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String type, total, aidRange;
  final bool shaded;
  final Color textPrimary, textSecondary;

  const _CostRow(this.type, this.total, this.aidRange, this.shaded,
      this.textPrimary, this.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: shaded ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
        borderRadius: shaded ? BorderRadius.circular(10) : null,
      ),
      child: Row(children: [
        Expanded(child: Text(type, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: textPrimary))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(total, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w800, color: Color(0xFFC62828))),
          Text('Aid: $aidRange', style: TextStyle(fontSize: 10,
              color: textSecondary)),
        ]),
      ]),
    );
  }
}

class _ClubCostRow extends StatelessWidget {
  final String item, range, description;
  final bool shaded;
  final Color textPrimary, textSecondary;

  const _ClubCostRow(this.item, this.range, this.description, this.shaded,
      this.textPrimary, this.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: shaded ? const Color(0xFF0277BD).withValues(alpha: 0.04) : Colors.transparent,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3)),
        ])),
        const SizedBox(width: 12),
        Text(range, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: Color(0xFF0277BD))),
      ]),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final String date, description;
  final Color color, textPrimary, textSecondary;

  const _DeadlineRow(this.date, this.description, this.color,
      this.textPrimary, this.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(date, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: color)),
        ),
        Expanded(child: Text(description, style: TextStyle(fontSize: 12,
            color: textSecondary, height: 1.4))),
      ]),
    );
  }
}

// ─── Step Detail Sheet ──────────────────────────────────────────────────────────
// isDark is passed as a constructor parameter because showModalBottomSheet
// creates a new route/subtree with no PlayerThemeScope ancestor. The value is
// captured by _showStepDetail() before opening the sheet.

class _StepDetailSheet extends StatelessWidget {
  final RoadmapStep step;
  final VoidCallback onToggleComplete;
  final bool isDark;

  const _StepDetailSheet({
    required this.step,
    required this.onToggleComplete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.status == StepStatus.completed;
    final (_, categoryColor) = switch (step.category) {
      StepCategory.technical => ('Technical', AppColors.coachColor),
      StepCategory.physical => ('Physical', AppColors.playerColor),
      StepCategory.academic => ('Academic', const Color(0xFF7B1FA2)),
      StepCategory.recruiting => ('Recruiting', AppColors.secondary),
      StepCategory.mental => ('Mental', AppColors.mentorColor),
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.border : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryBadge(category: step.category),
                    const SizedBox(width: 8),
                    if (step.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⭐ PRO FEATURE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? PlayerColors.textPrimary : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? PlayerColors.textSecondary
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Action Items',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...step.actionItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: categoryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark
                                  ? PlayerColors.textPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? (isDark
                            ? PlayerColors.surfaceVariant
                            : AppColors.border)
                        : categoryColor,
                  ),
                  onPressed: onToggleComplete,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.undo
                            : Icons.check_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompleted
                            ? 'Mark as Not Done'
                            : 'Mark as Complete ✓',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../data/roadmap_models.dart';

/// Player development roadmap — a visual timeline of steps from 6th grade
/// through college commitment, personalized by grade level and target school.
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
    _tabController = TabController(length: 4, vsync: this);
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
      _stepsForPhase(phase).where((s) => s.status == StepStatus.completed).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final totalSteps = _steps.length;
    final completedSteps = _steps.where((s) => s.status == StepStatus.completed).length;
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
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: [
              _PhaseTab('Foundation', '6–8', _completedCount(RoadmapPhase.foundation),
                  _stepsForPhase(RoadmapPhase.foundation).length),
              _PhaseTab('Development', '9–10', _completedCount(RoadmapPhase.development),
                  _stepsForPhase(RoadmapPhase.development).length),
              _PhaseTab('Recruitment', '11th', _completedCount(RoadmapPhase.recruitment),
                  _stepsForPhase(RoadmapPhase.recruitment).length),
              _PhaseTab('Commitment', '12th', _completedCount(RoadmapPhase.commitment),
                  _stepsForPhase(RoadmapPhase.commitment).length),
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

  void _showStepDetail(RoadmapStep step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StepDetailSheet(
        step: step,
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Text(label),
              Text(
                grade,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w400),
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
    if (steps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔒', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('This phase unlocks as you progress',
                style: TextStyle(color: AppColors.textSecondary)),
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
                      color: isCompleted ? phaseColor : Colors.white,
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
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCompleted
                          ? phaseColor.withValues(alpha: 0.3)
                          : AppColors.border,
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
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
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
                                color: AppColors.secondary.withValues(alpha: 0.15),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
                          const Icon(Icons.chevron_right,
                              size: 16, color: AppColors.textSecondary),
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

// ─── Step Detail Sheet ──────────────────────────────────────────────────────────

class _StepDetailSheet extends StatelessWidget {
  final RoadmapStep step;
  final VoidCallback onToggleComplete;

  const _StepDetailSheet({
    required this.step,
    required this.onToggleComplete,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: AppColors.border,
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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
                ...step.actionItems.map((item) => Padding(
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
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? AppColors.border : categoryColor,
                  ),
                  onPressed: onToggleComplete,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted ? Icons.undo : Icons.check_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompleted ? 'Mark as Not Done' : 'Mark as Complete ✓',
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/step_progress_indicator.dart';
import '../../data/tactical_blueprint_data.dart';
import '../widgets/formation_field_widget.dart';
import '../widgets/position_requirements_sheet.dart';

/// Multi-step coach setup: formation, playing style, position requirements, roster gaps.
class TacticalBlueprintPage extends StatefulWidget {
  const TacticalBlueprintPage({super.key});

  @override
  State<TacticalBlueprintPage> createState() => _TacticalBlueprintPageState();
}

class _TacticalBlueprintPageState extends State<TacticalBlueprintPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  static const int _totalSteps = 4;

  // Step 1 — Formation & Playing Style
  String? _selectedFormation;
  final List<String> _selectedStyles = [];
  final _teamNameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();

  // Step 2 — Position Requirements (per-position quality cards)
  // Map<positionId, List<qualityId>>
  final Map<String, List<String>> _positionQualities = {};

  // Step 3 — Roster Map (graduation years per position)
  // Map<positionId, {year: int, needs_recruit: bool}>
  final Map<String, Map<String, dynamic>> _rosterSlots = {};

  // Step 4 — Recruiting Priorities
  final List<String> _targetRecruitYears = [];
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _teamNameCtrl.dispose();
    _schoolCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  FormationInfo? get _currentFormationInfo {
    if (_selectedFormation == null) return null;
    return TacticalBlueprintData.formations
        .firstWhere((f) => f.id == _selectedFormation, orElse: () => TacticalBlueprintData.formations.first);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveBlueprintAndNavigate();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveBlueprintAndNavigate() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Upsert coach profile — column names match migrations 010 + 015
      final coachResult = await Supabase.instance.client.from('coaches').upsert({
        'user_id': userId,
        'school_name': _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
        'primary_formation': _selectedFormation,          // TEXT column (migration 010)
        'playing_styles': _selectedStyles.isNotEmpty ? _selectedStyles : null,
        'recruiting_class_years': _targetRecruitYears.isNotEmpty ? _targetRecruitYears : null,
        'recruiting_notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'onboarding_complete': true,
      }, onConflict: 'user_id').select('id').single();

      final coachId = coachResult['id'] as String;

      // Save position requirements using TEXT position_key (migration 015)
      for (final entry in _positionQualities.entries) {
        if (entry.value.isNotEmpty) {
          await Supabase.instance.client.from('coach_position_requirements').upsert({
            'coach_id': coachId,
            'position_key': entry.key,       // TEXT, not UUID FK
            'required_qualities': entry.value,
            'is_published': true,
          });
        }
      }

      // Save roster slots using TEXT position_key + graduation_year (migration 015)
      for (final entry in _rosterSlots.entries) {
        await Supabase.instance.client.from('roster_slots').upsert({
          'coach_id': coachId,
          'position_key': entry.key,         // TEXT, not UUID FK
          'graduation_year': entry.value['graduation_year'],
          'slot_status': entry.value['needs_recruit'] == true ? 'open' : 'filled',
        });
      }

      // Mark users.onboarding_complete = true
      await Supabase.instance.client.from('users').update({
        'onboarding_complete': true,
      }).eq('id', userId);

      if (mounted) context.go('/coach/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving blueprint: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedFormation != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
                onPressed: _prevStep,
              )
            : IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tactical Blueprint',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: StepProgressIndicator(
            total: _totalSteps,
            current: _currentStep,
            color: AppColors.coachColor,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StepFormation(
            selectedFormation: _selectedFormation,
            selectedStyles: _selectedStyles,
            schoolCtrl: _schoolCtrl,
            onFormationSelected: (f) => setState(() => _selectedFormation = f),
            onStyleToggled: (s) => setState(() {
              if (_selectedStyles.contains(s)) {
                _selectedStyles.remove(s);
              } else {
                _selectedStyles.add(s);
              }
            }),
          ),
          _StepPositionQualities(
            formation: _currentFormationInfo,
            positionQualities: _positionQualities,
            onPositionTap: _showPositionRequirementsSheet,
          ),
          _StepRosterMap(
            formation: _currentFormationInfo,
            rosterSlots: _rosterSlots,
            onSlotUpdated: (posId, data) {
              setState(() => _rosterSlots[posId] = data);
            },
          ),
          _StepRecruitingPriorities(
            targetYears: _targetRecruitYears,
            notesCtrl: _notesCtrl,
            onYearToggled: (y) => setState(() {
              if (_targetRecruitYears.contains(y)) {
                _targetRecruitYears.remove(y);
              } else {
                _targetRecruitYears.add(y);
              }
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.coachColor),
                onPressed: (_canProceed && !_isSaving) ? _nextStep : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_currentStep == _totalSteps - 1 ? 'Save Blueprint' : 'Continue'),
              ),
              if (_currentStep > 0)
                TextButton(
                  onPressed: _nextStep,
                  child: const Text('Skip this step',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPositionRequirementsSheet(BlueprintPosition position) {
    final currentQualities = _positionQualities[position.positionId] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PositionRequirementsSheet(
        position: position,
        allQualities: TacticalBlueprintData.qualities,
        selectedQualities: List.from(currentQualities),
        onSaved: (selected) {
          setState(() => _positionQualities[position.positionId] = selected);
        },
      ),
    );
  }
}

// ─── Step 1: Formation & Playing Style ─────────────────────────────────────────

class _StepFormation extends StatelessWidget {
  final String? selectedFormation;
  final List<String> selectedStyles;
  final TextEditingController schoolCtrl;
  final ValueChanged<String> onFormationSelected;
  final ValueChanged<String> onStyleToggled;

  const _StepFormation({
    required this.selectedFormation,
    required this.selectedStyles,
    required this.schoolCtrl,
    required this.onFormationSelected,
    required this.onStyleToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlueprintStepHeader(
            emoji: '🗺️',
            title: 'Your System of Play',
            subtitle: 'What formation do you run?',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: schoolCtrl,
            decoration: InputDecoration(
              labelText: 'School / Program Name',
              hintText: 'e.g. University of Texas, Austin CC',
              prefixIcon: const Icon(Icons.school_outlined),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.coachColor, width: 2)),
            ),
          ),
          const SizedBox(height: 28),
          Text('Primary Formation *', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          ...TacticalBlueprintData.formations.map((formation) {
            final selected = selectedFormation == formation.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onFormationSelected(formation.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.coachColor.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.coachColor : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.coachColor.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            formation.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: selected ? AppColors.coachColor : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formation.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: selected ? AppColors.coachColor : AppColors.textPrimary,
                                )),
                            const SizedBox(height: 3),
                            Text(formation.description,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: AppColors.coachColor, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 28),
          Text('Playing Style', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text('Select all that apply',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TacticalBlueprintData.playingStyles.map((style) {
              final selected = selectedStyles.contains(style);
              return GestureDetector(
                onTap: () => onStyleToggled(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.coachColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.coachColor : AppColors.border,
                    ),
                  ),
                  child: Text(
                    style,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Position Qualities ────────────────────────────────────────────────

class _StepPositionQualities extends StatelessWidget {
  final FormationInfo? formation;
  final Map<String, List<String>> positionQualities;
  final ValueChanged<BlueprintPosition> onPositionTap;

  const _StepPositionQualities({
    required this.formation,
    required this.positionQualities,
    required this.onPositionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (formation == null) {
      return const Center(child: Text('Please select a formation first'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlueprintStepHeader(
            emoji: '🎯',
            title: 'Position Requirements',
            subtitle: 'Tap each position to define what qualities you want',
          ),
          const SizedBox(height: 24),
          // Interactive formation field
          FormationFieldWidget(
            formation: formation!,
            positionQualities: positionQualities,
            onPositionTap: onPositionTap,
          ),
          const SizedBox(height: 24),
          // Position list with quality badges
          ...formation!.positions.map((pos) {
            final qualities = positionQualities[pos.positionId] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onPositionTap(pos),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: qualities.isNotEmpty ? AppColors.coachColor.withValues(alpha: 0.4) : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: qualities.isNotEmpty
                              ? AppColors.coachColor.withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(pos.abbreviation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: qualities.isNotEmpty
                                    ? AppColors.coachColor
                                    : AppColors.textSecondary,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pos.positionName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            if (qualities.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${qualities.length} quality${qualities.length != 1 ? 'qualities' : 'quality'} defined',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.coachColor),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              const Text('Tap to define requirements',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 3: Roster Map ────────────────────────────────────────────────────────

class _StepRosterMap extends StatelessWidget {
  final FormationInfo? formation;
  final Map<String, Map<String, dynamic>> rosterSlots;
  final void Function(String posId, Map<String, dynamic> data) onSlotUpdated;

  const _StepRosterMap({
    required this.formation,
    required this.rosterSlots,
    required this.onSlotUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (formation == null) {
      return const Center(child: Text('Please select a formation first'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlueprintStepHeader(
            emoji: '📊',
            title: 'Roster Map',
            subtitle: 'Which positions are graduating? Do you need a recruit?',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.coachColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '💡 Mark positions with graduating players and flag where you need a recruit. This powers the matching engine.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          ...formation!.positions.map((pos) {
            final slot = rosterSlots[pos.positionId];
            final needsRecruit = slot?['needs_recruit'] == true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: needsRecruit ? AppColors.coachColor.withValues(alpha: 0.5) : AppColors.border,
                    width: needsRecruit ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: needsRecruit
                                ? AppColors.coachColor.withValues(alpha: 0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(pos.abbreviation,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: needsRecruit
                                      ? AppColors.coachColor
                                      : AppColors.textSecondary,
                                )),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(pos.positionName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        if (needsRecruit)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.coachColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('NEEDS RECRUIT',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Graduation Year',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              _YearDropdown(
                                value: slot?['graduation_year']?.toString(),
                                onChanged: (year) {
                                  onSlotUpdated(pos.positionId, {
                                    ...?rosterSlots[pos.positionId],
                                    'graduation_year': year != null ? int.tryParse(year) : null,
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Needs Recruit',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Switch(
                              value: needsRecruit,
                              activeThumbColor: AppColors.coachColor,
                              activeTrackColor: AppColors.coachColor.withValues(alpha: 0.4),
                              onChanged: (val) {
                                onSlotUpdated(pos.positionId, {
                                  ...?rosterSlots[pos.positionId],
                                  'needs_recruit': val,
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _YearDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Select year', style: TextStyle(fontSize: 12)),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          isDense: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('—')),
            ...TacticalBlueprintData.recruitingYears.map(
              (y) => DropdownMenuItem(value: y, child: Text(y)),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Step 4: Recruiting Priorities ─────────────────────────────────────────────

class _StepRecruitingPriorities extends StatelessWidget {
  final List<String> targetYears;
  final TextEditingController notesCtrl;
  final ValueChanged<String> onYearToggled;

  const _StepRecruitingPriorities({
    required this.targetYears,
    required this.notesCtrl,
    required this.onYearToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlueprintStepHeader(
            emoji: '📅',
            title: 'Recruiting Classes',
            subtitle: 'Which graduating classes are you actively recruiting?',
          ),
          const SizedBox(height: 28),
          Text('Target Recruiting Years', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TacticalBlueprintData.recruitingYears.map((year) {
              final selected = targetYears.contains(year);
              return GestureDetector(
                onTap: () => onYearToggled(year),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.coachColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.coachColor : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    'Class of $year',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text('Recruiting Notes (Optional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: notesCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Any specific requirements, preferred regions, scholarship availability, program culture notes...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.coachColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.coachColor.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🚀', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text("What happens next",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Lanista\'s matching engine will compare your blueprint against thousands of player profiles and surface the best fits — ranked by tactical match, position need, academic profile, and timeline.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared header widget ───────────────────────────────────────────────────────

class _BlueprintStepHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _BlueprintStepHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

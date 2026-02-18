import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/step_progress_indicator.dart';
import '../../data/player_profile_data.dart';

/// Multi-step player profile completion wizard.
/// Shown after role selection when a player's profile is incomplete.
class PlayerProfileSetupPage extends StatefulWidget {
  const PlayerProfileSetupPage({super.key});

  @override
  State<PlayerProfileSetupPage> createState() => _PlayerProfileSetupPageState();
}

class _PlayerProfileSetupPageState extends State<PlayerProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  static const int _totalSteps = 5;

  // Step 1 — Basic Info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  String? _selectedGrade;
  String? _selectedTimeline;

  // Step 2 — Position & Physical
  String? _primaryPosition;
  String? _secondaryPosition;
  String? _footPreference;
  String? _heightRange;

  // Step 3 — Current Club & League
  final _clubNameCtrl = TextEditingController();
  String? _selectedLeague;

  // Step 4 — Academic
  String? _gpaRange;
  final _satCtrl = TextEditingController();
  final _actCtrl = TextEditingController();

  // Step 5 — Goals
  final List<String> _selectedDivisions = [];
  final _bioCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _clubNameCtrl.dispose();
    _satCtrl.dispose();
    _actCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveProfile();
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

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Update base user record
      await Supabase.instance.client.from('users').update({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'onboarding_complete': true,
      }).eq('id', userId);

      // Map foot preference to DB CHECK values (left/right/both)
      String? dominantFoot;
      if (_footPreference == 'Right') dominantFoot = 'right';
      else if (_footPreference == 'Left') dominantFoot = 'left';
      else if (_footPreference != null) dominantFoot = 'both';

      // Upsert player profile — column names match migration 011
      await Supabase.instance.client.from('players').upsert({
        'user_id': userId,
        'grade': _selectedGrade != null ? int.tryParse(_selectedGrade!) : null,
        'graduation_year': _selectedTimeline != null
            ? int.tryParse(_selectedTimeline!.replaceAll('Class of ', ''))
            : null,
        'primary_position': _primaryPosition,
        'secondary_position': _secondaryPosition,
        'dominant_foot': dominantFoot,
        // height_cm is INTEGER in DB — skip the range string, save null for now
        'height_cm': null,
        'club_name': _clubNameCtrl.text.trim().isEmpty ? null : _clubNameCtrl.text.trim(),
        'league': _selectedLeague,
        // gpa is NUMERIC(3,2) — skip range string, save null for now
        'gpa': null,
        'sat_score': _satCtrl.text.trim().isEmpty ? null : int.tryParse(_satCtrl.text.trim()),
        'act_score': _actCtrl.text.trim().isEmpty ? null : int.tryParse(_actCtrl.text.trim()),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'target_divisions': _selectedDivisions.isNotEmpty ? _selectedDivisions : null,
        'is_discoverable': true,
      }, onConflict: 'user_id');

      if (mounted) context.go('/player/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
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
        return _firstNameCtrl.text.trim().isNotEmpty &&
            _lastNameCtrl.text.trim().isNotEmpty &&
            _selectedGrade != null;
      case 1:
        return _primaryPosition != null;
      case 2:
        return true; // Club info is optional
      case 3:
        return true; // Academic info is optional
      case 4:
        return true; // Goals are optional — encourage but don't block
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
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build Your Profile',
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
            color: AppColors.playerColor,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StepBasicInfo(
            firstNameCtrl: _firstNameCtrl,
            lastNameCtrl: _lastNameCtrl,
            selectedGrade: _selectedGrade,
            selectedTimeline: _selectedTimeline,
            onGradeChanged: (v) => setState(() => _selectedGrade = v),
            onTimelineChanged: (v) => setState(() => _selectedTimeline = v),
            onChanged: () => setState(() {}),
          ),
          _StepPosition(
            primaryPosition: _primaryPosition,
            secondaryPosition: _secondaryPosition,
            footPreference: _footPreference,
            heightRange: _heightRange,
            onPrimaryChanged: (v) => setState(() => _primaryPosition = v),
            onSecondaryChanged: (v) => setState(() => _secondaryPosition = v),
            onFootChanged: (v) => setState(() => _footPreference = v),
            onHeightChanged: (v) => setState(() => _heightRange = v),
          ),
          _StepClub(
            clubNameCtrl: _clubNameCtrl,
            selectedLeague: _selectedLeague,
            onLeagueChanged: (v) => setState(() => _selectedLeague = v),
          ),
          _StepAcademic(
            gpaRange: _gpaRange,
            satCtrl: _satCtrl,
            actCtrl: _actCtrl,
            onGpaChanged: (v) => setState(() => _gpaRange = v),
          ),
          _StepGoals(
            selectedDivisions: _selectedDivisions,
            bioCtrl: _bioCtrl,
            onDivisionToggled: (div) {
              setState(() {
                if (_selectedDivisions.contains(div)) {
                  _selectedDivisions.remove(div);
                } else {
                  _selectedDivisions.add(div);
                }
              });
            },
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
                onPressed: (_canProceed && !_isSaving) ? _nextStep : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_currentStep == _totalSteps - 1 ? 'Complete Profile' : 'Continue'),
              ),
              if (_currentStep < _totalSteps - 1 && _currentStep > 0)
                TextButton(
                  onPressed: _nextStep,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Basic Info ────────────────────────────────────────────────────────

class _StepBasicInfo extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final String? selectedGrade;
  final String? selectedTimeline;
  final ValueChanged<String?> onGradeChanged;
  final ValueChanged<String?> onTimelineChanged;
  final VoidCallback onChanged;

  const _StepBasicInfo({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.selectedGrade,
    required this.selectedTimeline,
    required this.onGradeChanged,
    required this.onTimelineChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '👤',
            title: 'About You',
            subtitle: 'Tell coaches who you are',
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _ProfileTextField(
                  controller: firstNameCtrl,
                  label: 'First Name',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileTextField(
                  controller: lastNameCtrl,
                  label: 'Last Name',
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Current Grade', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.gradeLevels.map((grade) {
              final selected = selectedGrade == grade.id;
              return _SelectChip(
                label: grade.label.replaceAll(' Grade', '').replaceAll(' (Freshman)', '\nFreshman').replaceAll(' (Sophomore)', '\nSophomore').replaceAll(' (Junior)', '\nJunior').replaceAll(' (Senior)', '\nSenior'),
                isSelected: selected,
                color: AppColors.playerColor,
                onTap: () => onGradeChanged(selected ? null : grade.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Graduation Year', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.targetTimelines.map((timeline) {
              final selected = selectedTimeline == timeline;
              return _SelectChip(
                label: timeline,
                isSelected: selected,
                color: AppColors.playerColor,
                onTap: () => onTimelineChanged(selected ? null : timeline),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Position & Physical ──────────────────────────────────────────────

class _StepPosition extends StatelessWidget {
  final String? primaryPosition;
  final String? secondaryPosition;
  final String? footPreference;
  final String? heightRange;
  final ValueChanged<String?> onPrimaryChanged;
  final ValueChanged<String?> onSecondaryChanged;
  final ValueChanged<String?> onFootChanged;
  final ValueChanged<String?> onHeightChanged;

  const _StepPosition({
    required this.primaryPosition,
    required this.secondaryPosition,
    required this.footPreference,
    required this.heightRange,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
    required this.onFootChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '⚽',
            title: 'Your Position',
            subtitle: 'Help coaches find you for the right role',
          ),
          const SizedBox(height: 32),
          Text('Primary Position *', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.positions.map((pos) {
              final selected = primaryPosition == pos.id;
              return _SelectChip(
                label: '${pos.abbreviation}\n${pos.name}',
                isSelected: selected,
                color: AppColors.playerColor,
                onTap: () => onPrimaryChanged(selected ? null : pos.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Secondary Position (Optional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.positions
                .where((p) => p.id != primaryPosition)
                .map((pos) {
              final selected = secondaryPosition == pos.id;
              return _SelectChip(
                label: pos.abbreviation,
                isSelected: selected,
                color: AppColors.playerColor.withValues(alpha: 0.7),
                onTap: () => onSecondaryChanged(selected ? null : pos.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Dominant Foot', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: PlayerProfileData.footPreferences.map((foot) {
              final selected = footPreference == foot;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SelectChip(
                  label: foot,
                  isSelected: selected,
                  color: AppColors.playerColor,
                  onTap: () => onFootChanged(selected ? null : foot),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Height', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.heightRanges.map((h) {
              final selected = heightRange == h;
              return _SelectChip(
                label: h,
                isSelected: selected,
                color: AppColors.playerColor,
                onTap: () => onHeightChanged(selected ? null : h),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Club & League ─────────────────────────────────────────────────────

class _StepClub extends StatelessWidget {
  final TextEditingController clubNameCtrl;
  final String? selectedLeague;
  final ValueChanged<String?> onLeagueChanged;

  const _StepClub({
    required this.clubNameCtrl,
    required this.selectedLeague,
    required this.onLeagueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '🏟️',
            title: 'Your Club',
            subtitle: 'Where do you play currently?',
          ),
          const SizedBox(height: 32),
          _ProfileTextField(
            controller: clubNameCtrl,
            label: 'Club / Team Name',
            hint: 'e.g. FC Dallas Academy, Real Colorado',
          ),
          const SizedBox(height: 24),
          Text('Current League', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.leagues.map((league) {
              final selected = selectedLeague == league;
              return _SelectChip(
                label: league,
                isSelected: selected,
                color: AppColors.playerColor,
                onTap: () => onLeagueChanged(selected ? null : league),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'College coaches pay close attention to which leagues you play in. MLS NEXT and ECNL carry the most visibility.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
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

// ─── Step 4: Academic ──────────────────────────────────────────────────────────

class _StepAcademic extends StatelessWidget {
  final String? gpaRange;
  final TextEditingController satCtrl;
  final TextEditingController actCtrl;
  final ValueChanged<String?> onGpaChanged;

  const _StepAcademic({
    required this.gpaRange,
    required this.satCtrl,
    required this.actCtrl,
    required this.onGpaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '📚',
            title: 'Academics',
            subtitle: 'NCAA eligibility starts in the classroom',
          ),
          const SizedBox(height: 32),
          Text('GPA (Unweighted)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.gpaRanges.map((gpa) {
              final selected = gpaRange == gpa;
              return _SelectChip(
                label: gpa,
                isSelected: selected,
                color: AppColors.playerColor,
                onTap: () => onGpaChanged(selected ? null : gpa),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ProfileTextField(
                  controller: satCtrl,
                  label: 'SAT Score',
                  hint: 'e.g. 1200',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileTextField(
                  controller: actCtrl,
                  label: 'ACT Score',
                  hint: 'e.g. 28',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('NCAA Eligibility Tip',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'NCAA D1 requires a minimum 2.3 GPA in 16 core courses. D2 requires a 2.2 GPA. '
                  'Register with the NCAA Eligibility Center (ncaaeligibilitycenter.org) by junior year.',
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

// ─── Step 5: Goals ─────────────────────────────────────────────────────────────

class _StepGoals extends StatelessWidget {
  final List<String> selectedDivisions;
  final TextEditingController bioCtrl;
  final ValueChanged<String> onDivisionToggled;

  const _StepGoals({
    required this.selectedDivisions,
    required this.bioCtrl,
    required this.onDivisionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '🎯',
            title: 'Your Goals',
            subtitle: "Let coaches know what you're aiming for",
          ),
          const SizedBox(height: 32),
          Text('Target Division(s)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text('Select all that apply', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...PlayerProfileData.divisions.map((div) {
            final selected = selectedDivisions.contains(div);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DivisionTile(
                label: div,
                isSelected: selected,
                onTap: () => onDivisionToggled(div),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text('About Me', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: bioCtrl,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Share your story, what makes you unique as a player, your work ethic...',
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
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _StepHeader({
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
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _DivisionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DivisionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.playerColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.playerColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.playerColor : AppColors.border,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.playerColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

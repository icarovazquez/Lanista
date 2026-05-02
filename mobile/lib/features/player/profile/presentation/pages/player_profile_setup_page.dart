import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_data.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
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
  bool _isLoadingData = true;

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
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load user record (first/last name)
      final userData = await Supabase.instance.client
          .from('users')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      // Load player record (all profile fields)
      final playerData = await Supabase.instance.client
          .from('players')
          .select(
              'grade, graduation_year, dominant_foot, height_cm, gpa, '
              'sat_score, act_score, bio, target_division, '
              'primary_position, secondary_position, club_name, league')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;

        // ── User fields ────────────────────────────────────────────────────
        if (userData != null) {
          _firstNameCtrl.text = userData['first_name'] as String? ?? '';
          _lastNameCtrl.text  = userData['last_name']  as String? ?? '';
        }

        if (playerData == null) return;

        // ── Grade ──────────────────────────────────────────────────────────
        final grade = playerData['grade'];
        if (grade != null) _selectedGrade = grade.toString();

        // ── Graduation year → timeline label ──────────────────────────────
        final gradYear = playerData['graduation_year'] as int?;
        if (gradYear != null) {
          final label = 'Class of $gradYear';
          if (PlayerProfileData.targetTimelines.contains(label)) {
            _selectedTimeline = label;
          }
        }

        // ── Dominant foot ─────────────────────────────────────────────────
        final foot = playerData['dominant_foot'] as String?;
        if (foot == 'right') _footPreference = 'Right';
        else if (foot == 'left') _footPreference = 'Left';
        else if (foot == 'both') _footPreference = 'Both (Ambidextrous)';

        // ── Height cm → range label ───────────────────────────────────────
        final heightCm = playerData['height_cm'] as int?;
        if (heightCm != null) {
          if (heightCm < 152)       _heightRange = 'Under 5\'0"';
          else if (heightCm <= 160) _heightRange = '5\'0" – 5\'3"';
          else if (heightCm <= 170) _heightRange = '5\'4" – 5\'7"';
          else if (heightCm <= 181) _heightRange = '5\'8" – 5\'11"';
          else if (heightCm <= 189) _heightRange = '6\'0" – 6\'2"';
          else                      _heightRange = '6\'3"+';
        }

        // ── GPA decimal → range label ─────────────────────────────────────
        final gpa = (playerData['gpa'] as num?)?.toDouble();
        if (gpa != null) {
          if (gpa >= 4.0)      _gpaRange = '4.0 (Unweighted)';
          else if (gpa >= 3.5) _gpaRange = '3.5 – 3.9';
          else if (gpa >= 3.0) _gpaRange = '3.0 – 3.4';
          else if (gpa >= 2.5) _gpaRange = '2.5 – 2.9';
          else if (gpa >= 2.0) _gpaRange = '2.0 – 2.4';
        }

        // ── SAT / ACT ─────────────────────────────────────────────────────
        final sat = playerData['sat_score'] as int?;
        if (sat != null) _satCtrl.text = sat.toString();
        final act = playerData['act_score'] as int?;
        if (act != null) _actCtrl.text = act.toString();

        // ── Bio ───────────────────────────────────────────────────────────
        final bio = playerData['bio'] as String?;
        if (bio != null) _bioCtrl.text = bio;

        // ── Target division → selected divisions list ─────────────────────
        final div = playerData['target_division'] as String?;
        if (div != null) {
          final divLabel = const {
            'D1': 'NCAA Division I',
            'D2': 'NCAA Division II',
            'D3': 'NCAA Division III',
            'NAIA': 'NAIA',
            'JUCO': 'NJCAA (Junior College)',
          }[div];
          if (divLabel != null && !_selectedDivisions.contains(divLabel)) {
            _selectedDivisions.add(divLabel);
          }
        }

        // ── Positions ─────────────────────────────────────────────────────
        _primaryPosition   = playerData['primary_position']   as String?;
        _secondaryPosition = playerData['secondary_position'] as String?;

        // ── Club & League ─────────────────────────────────────────────────
        final clubName = playerData['club_name'] as String?;
        if (clubName != null) _clubNameCtrl.text = clubName;
        _selectedLeague = playerData['league'] as String?;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

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

      // Map height range to a representative cm value
      int? heightCm;
      switch (_heightRange) {
        case 'Under 5\'0"': heightCm = 150; break;
        case '5\'0" – 5\'3"': heightCm = 158; break;
        case '5\'4" – 5\'7"': heightCm = 168; break;
        case '5\'8" – 5\'11"': heightCm = 178; break;
        case '6\'0" – 6\'2"': heightCm = 185; break;
        case '6\'3"+': heightCm = 193; break;
      }

      // Map GPA range to decimal midpoint
      double? gpa;
      switch (_gpaRange) {
        case '4.0 (Unweighted)': gpa = 4.00; break;
        case '3.5 – 3.9': gpa = 3.70; break;
        case '3.0 – 3.4': gpa = 3.20; break;
        case '2.5 – 2.9': gpa = 2.70; break;
        case '2.0 – 2.4': gpa = 2.20; break;
      }

      // target_division: use first selected division, map label to DB enum value
      String? targetDivision;
      if (_selectedDivisions.isNotEmpty) {
        final div = _selectedDivisions.first;
        if (div.contains('Division I') && !div.contains('II') && !div.contains('III')) {
          targetDivision = 'D1';
        } else if (div.contains('Division II') && !div.contains('III')) {
          targetDivision = 'D2';
        } else if (div.contains('Division III')) {
          targetDivision = 'D3';
        } else if (div.contains('NAIA')) {
          targetDivision = 'NAIA';
        } else if (div.contains('Junior') || div.contains('NJCAA')) {
          targetDivision = 'JUCO';
        }
      }

      final existingBio = _bioCtrl.text.trim();

      await Supabase.instance.client.from('players').upsert({
        'user_id': userId,
        'grade': _selectedGrade != null ? int.tryParse(_selectedGrade!) : null,
        'graduation_year': _selectedTimeline != null
            ? int.tryParse(_selectedTimeline!.replaceAll('Class of ', ''))
            : null,
        'dominant_foot': dominantFoot,
        'height_cm': heightCm,
        'gpa': gpa,
        'sat_score': _satCtrl.text.trim().isEmpty ? null : int.tryParse(_satCtrl.text.trim()),
        'act_score': _actCtrl.text.trim().isEmpty ? null : int.tryParse(_actCtrl.text.trim()),
        'bio': existingBio.isEmpty ? null : existingBio,
        'target_division': targetDivision,
        'is_discoverable': true,
        'primary_position': _primaryPosition,
        'secondary_position': _secondaryPosition,
        'club_name': _clubNameCtrl.text.trim().isEmpty ? null : _clubNameCtrl.text.trim(),
        'league': _selectedLeague,
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
    final themeService = getIt<PlayerThemeService>();

    // Pushed routes sit outside PlayerDashboardPage's PlayerThemeScope,
    // so we re-establish Theme + scope here using the GetIt singleton.
    return ListenableBuilder(
      listenable: themeService,
      builder: (ctx, _) {
        final isDark = themeService.value == PlayerThemeMode.dark;
        return Theme(
          data: isDark ? PlayerThemeData.dark : AppTheme.lightTheme,
          child: PlayerThemeScope(
            service: themeService,
            child: _buildScaffold(ctx, isDark),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? PlayerColors.background : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? PlayerColors.surface : AppColors.surface,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                    size: 18),
                onPressed: _prevStep,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build Your Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: StepProgressIndicator(
            total: _totalSteps,
            current: _currentStep,
            color: isDark ? PlayerColors.accent : AppColors.playerColor,
          ),
        ),
      ),
      body: _isLoadingData
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
              ),
            )
          : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: PageView(
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: (_canProceed && !_isSaving) ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
                  foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: isDark ? PlayerColors.textOnAccent : Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_currentStep == _totalSteps - 1 ? 'Complete Profile' : 'Continue'),
              ),
              if (_currentStep < _totalSteps - 1 && _currentStep > 0)
                TextButton(
                  onPressed: _nextStep,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                    ),
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
    final isDark = PlayerThemeScope.isDark(context);
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
          Text(
            'Current Grade',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.gradeLevels.map((grade) {
              final selected = selectedGrade == grade.id;
              return _SelectChip(
                label: grade.label.replaceAll(' Grade', '').replaceAll(' (Freshman)', '\nFreshman').replaceAll(' (Sophomore)', '\nSophomore').replaceAll(' (Junior)', '\nJunior').replaceAll(' (Senior)', '\nSenior'),
                isSelected: selected,
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
                onTap: () => onGradeChanged(selected ? null : grade.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Graduation Year',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.targetTimelines.map((timeline) {
              final selected = selectedTimeline == timeline;
              return _SelectChip(
                label: timeline,
                isSelected: selected,
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
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
    final isDark = PlayerThemeScope.isDark(context);
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
          Text(
            'Primary Position *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.positions.map((pos) {
              final selected = primaryPosition == pos.id;
              return _SelectChip(
                label: '${pos.abbreviation}\n${pos.name}',
                isSelected: selected,
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
                onTap: () => onPrimaryChanged(selected ? null : pos.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Secondary Position (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
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
                color: isDark
                    ? PlayerColors.accent.withValues(alpha: 0.7)
                    : AppColors.playerColor.withValues(alpha: 0.7),
                onTap: () => onSecondaryChanged(selected ? null : pos.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Dominant Foot',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: PlayerProfileData.footPreferences.map((foot) {
              final selected = footPreference == foot;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SelectChip(
                  label: foot,
                  isSelected: selected,
                  color: isDark ? PlayerColors.accent : AppColors.playerColor,
                  onTap: () => onFootChanged(selected ? null : foot),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Height',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.heightRanges.map((h) {
              final selected = heightRange == h;
              return _SelectChip(
                label: h,
                isSelected: selected,
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
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
    final isDark = PlayerThemeScope.isDark(context);
    final leagues = PlayerProfileData.leagues;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            emoji: '🏟️',
            title: 'Your Club',
            subtitle: 'Where do you play currently?',
          ),
          const SizedBox(height: 32),

          // ── League selection ───────────────────────────────────────────
          Text(
            'Current League',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: leagues.map((league) {
              final selected = selectedLeague == league;
              return _SelectChip(
                label: league,
                isSelected: selected,
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
                onTap: () => onLeagueChanged(selected ? null : league),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Text(
            'Club / Team Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _ProfileTextField(
            controller: clubNameCtrl,
            label: 'Club / Team Name',
            hint: 'e.g. FC Dallas Academy, Real Colorado',
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? PlayerColors.accent.withValues(alpha: 0.06)
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? PlayerColors.accent.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'College coaches pay close attention to which leagues you play in. MLS NEXT and ECNL carry the most visibility.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
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
    final isDark = PlayerThemeScope.isDark(context);
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
          Text(
            'GPA (Unweighted)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerProfileData.gpaRanges.map((gpa) {
              final selected = gpaRange == gpa;
              return _SelectChip(
                label: gpa,
                isSelected: selected,
                color: isDark ? PlayerColors.accent : AppColors.playerColor,
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
              color: isDark
                  ? PlayerColors.gradientStart.withValues(alpha: 0.08)
                  : AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? PlayerColors.gradientStart.withValues(alpha: 0.3)
                    : AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'NCAA Eligibility Tip',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'NCAA D1 requires a minimum 2.3 GPA in 16 core courses. D2 requires a 2.2 GPA. '
                  'Register with the NCAA Eligibility Center (ncaaeligibilitycenter.org) by junior year.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
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
    final isDark = PlayerThemeScope.isDark(context);
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
          Text(
            'Target Division(s)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select all that apply',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
            ),
          ),
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
          Text(
            'About Me',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bioCtrl,
            maxLines: 4,
            maxLength: 300,
            style: TextStyle(
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Share your story, what makes you unique as a player, your work ethic...',
              hintStyle: TextStyle(
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? PlayerColors.surface : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? PlayerColors.border : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? PlayerColors.border : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                  width: 2,
                ),
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
    final isDark = PlayerThemeScope.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
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
    final isDark = PlayerThemeScope.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? PlayerColors.surfaceVariant : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? PlayerColors.border : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? PlayerColors.textOnAccent : Colors.white)
                : (isDark ? PlayerColors.textPrimary : AppColors.textPrimary),
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
    final isDark = PlayerThemeScope.isDark(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: isDark ? PlayerColors.surface : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? PlayerColors.border : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? PlayerColors.border : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? PlayerColors.accent : AppColors.primary,
            width: 2,
          ),
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
    final isDark = PlayerThemeScope.isDark(context);
    final accentColor = isDark ? PlayerColors.accent : AppColors.playerColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : (isDark ? PlayerColors.surfaceVariant : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? PlayerColors.border : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? accentColor
                  : (isDark ? PlayerColors.border : AppColors.border),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? accentColor
                    : (isDark ? PlayerColors.textPrimary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

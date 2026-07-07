import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Streamlined 3-step player onboarding wizard.
/// Collects only the fields the matching engine needs to compute match scores.
/// Everything else (club, bio, SAT/ACT, secondary position) is deferred
/// to the full profile editor, prompted via a dashboard completion nudge.
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

  static const int _totalSteps = 3;

  // ── Step 1 — Who You Are ────────────────────────────────────────────────────
  final _firstNameCtrl    = TextEditingController();
  final _lastNameCtrl     = TextEditingController();
  DateTime? _dateOfBirth;
  String?   _selectedTimeline; // 'Class of YYYY'

  // ── Step 2 — How You Play ───────────────────────────────────────────────────
  String? _primaryPosition;
  String? _footPreference;       // 'Right' | 'Left' | 'Both'
  final _heightCtrl = TextEditingController(); // exact cm
  final _weightCtrl = TextEditingController(); // exact kg
  int?    _speedRating;           // 1–10

  // ── Step 3 — Academic Goals ─────────────────────────────────────────────────
  final _gpaCtrl        = TextEditingController(); // exact decimal e.g. 3.7
  String? _targetDivision; // 'D1' | 'D2' | 'D3' | 'NAIA' | 'JUCO'

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final userData = await Supabase.instance.client
          .from('users')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      final playerData = await Supabase.instance.client
          .from('players')
          .select('graduation_year, date_of_birth, dominant_foot, height_cm, weight_kg, speed_rating, gpa, target_division, primary_position')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;

        if (userData != null) {
          _firstNameCtrl.text = userData['first_name'] as String? ?? '';
          _lastNameCtrl.text  = userData['last_name']  as String? ?? '';
        }

        if (playerData == null) return;

        final gradYear = playerData['graduation_year'] as int?;
        if (gradYear != null) {
          final label = 'Class of $gradYear';
          if (PlayerProfileData.targetTimelines.contains(label)) {
            _selectedTimeline = label;
          }
        }

        final dob = playerData['date_of_birth'] as String?;
        if (dob != null) _dateOfBirth = DateTime.tryParse(dob);

        final foot = playerData['dominant_foot'] as String?;
        if (foot == 'right')     _footPreference = 'Right';
        else if (foot == 'left') _footPreference = 'Left';
        else if (foot == 'both') _footPreference = 'Both';

        final heightCm = playerData['height_cm'] as int?;
        if (heightCm != null) _heightCtrl.text = heightCm.toString();

        final weightKg = playerData['weight_kg'] as int?;
        if (weightKg != null) _weightCtrl.text = weightKg.toString();

        _speedRating = playerData['speed_rating'] as int?;

        final gpa = (playerData['gpa'] as num?)?.toDouble();
        if (gpa != null) _gpaCtrl.text = gpa.toStringAsFixed(1);

        _targetDivision   = playerData['target_division'] as String?;
        _primaryPosition  = playerData['primary_position'] as String?;
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
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _gpaCtrl.dispose();
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

      await Supabase.instance.client.from('users').update({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name':  _lastNameCtrl.text.trim(),
        'onboarding_complete': true,
      }).eq('id', userId);

      String? dominantFoot;
      if (_footPreference == 'Right')     dominantFoot = 'right';
      else if (_footPreference == 'Left') dominantFoot = 'left';
      else if (_footPreference == 'Both') dominantFoot = 'both';

      final gradYear = _selectedTimeline != null
          ? int.tryParse(_selectedTimeline!.replaceAll('Class of ', ''))
          : null;

      await Supabase.instance.client.from('players').upsert({
        'user_id':          userId,
        'graduation_year':  gradYear,
        'date_of_birth':    _dateOfBirth?.toIso8601String().split('T').first,
        'dominant_foot':    dominantFoot,
        'height_cm':        int.tryParse(_heightCtrl.text.trim()),
        'weight_kg':        int.tryParse(_weightCtrl.text.trim()),
        'speed_rating':     _speedRating,
        'gpa':              double.tryParse(_gpaCtrl.text.trim()),
        'target_division':  _targetDivision,
        'primary_position': _primaryPosition,
        'is_discoverable':  true,
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
            _selectedTimeline != null;
      case 1:
        return _primaryPosition != null;
      case 2:
        return true; // GPA + division optional but encouraged
      default:
        return true;
    }
  }

  String get _stepLabel {
    switch (_currentStep) {
      case 0: return 'Who You Are';
      case 1: return 'How You Play';
      case 2: return 'Academic Goals';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
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
    final accentColor = isDark ? PlayerColors.accent : AppColors.playerColor;
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
              _stepLabel,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: TextStyle(
                fontSize: 11,
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
            color: accentColor,
          ),
        ),
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepWhoYouAre(
                    firstNameCtrl:    _firstNameCtrl,
                    lastNameCtrl:     _lastNameCtrl,
                    dateOfBirth:      _dateOfBirth,
                    selectedTimeline: _selectedTimeline,
                    onDobChanged:      (d) => setState(() => _dateOfBirth = d),
                    onTimelineChanged: (v) => setState(() => _selectedTimeline = v),
                    onChanged:         () => setState(() {}),
                  ),
                  _StepHowYouPlay(
                    primaryPosition: _primaryPosition,
                    footPreference:  _footPreference,
                    heightCtrl:      _heightCtrl,
                    weightCtrl:      _weightCtrl,
                    speedRating:     _speedRating,
                    onPositionChanged: (v) => setState(() => _primaryPosition = v),
                    onFootChanged:     (v) => setState(() => _footPreference = v),
                    onSpeedChanged:    (v) => setState(() => _speedRating = v),
                  ),
                  _StepAcademicGoals(
                    gpaCtrl:        _gpaCtrl,
                    targetDivision: _targetDivision,
                    onDivisionChanged: (v) => setState(() => _targetDivision = v),
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
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: isDark ? PlayerColors.textOnAccent : Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_currentStep == _totalSteps - 1
                        ? 'Find My Matches' : 'Continue'),
              ),
              if (_currentStep == 2)
                TextButton(
                  onPressed: _nextStep,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: isDark
                          ? PlayerColors.textSecondary : AppColors.textSecondary,
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

// ─── Step 1: Who You Are ────────────────────────────────────────────────────────

class _StepWhoYouAre extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final DateTime? dateOfBirth;
  final String? selectedTimeline;
  final ValueChanged<DateTime?> onDobChanged;
  final ValueChanged<String?> onTimelineChanged;
  final VoidCallback onChanged;

  const _StepWhoYouAre({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.dateOfBirth,
    required this.selectedTimeline,
    required this.onDobChanged,
    required this.onTimelineChanged,
    required this.onChanged,
  });

  String _formatDob(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accentColor = isDark ? PlayerColors.accent : AppColors.playerColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '👤',
            title: 'Who You Are',
            subtitle: 'The basics coaches need to find you',
          ),
          const SizedBox(height: 32),

          // Name
          Row(
            children: [
              Expanded(
                child: _ProfileTextField(
                  controller: firstNameCtrl,
                  label: 'First Name *',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileTextField(
                  controller: lastNameCtrl,
                  label: 'Last Name *',
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date of Birth
          _fieldLabel('Date of Birth', isDark),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateOfBirth ?? DateTime(2007, 1, 1),
                firstDate: DateTime(1995),
                lastDate: DateTime(2015),
                helpText: 'Select your date of birth',
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: ColorScheme.light(primary: accentColor),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onDobChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.surface : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dateOfBirth != null
                      ? accentColor
                      : (isDark ? PlayerColors.border : AppColors.border),
                  width: dateOfBirth != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined, size: 18,
                      color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    dateOfBirth != null
                        ? _formatDob(dateOfBirth!)
                        : 'Select date of birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: dateOfBirth != null
                          ? (isDark ? PlayerColors.textPrimary : AppColors.textPrimary)
                          : (isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 18,
                      color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Graduation year
          _fieldLabel('Graduation Year *', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PlayerProfileData.targetTimelines.map((timeline) {
              final selected = selectedTimeline == timeline;
              return _SelectChip(
                label: timeline,
                isSelected: selected,
                color: accentColor,
                onTap: () => onTimelineChanged(selected ? null : timeline),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          _matchingEngineNote(isDark,
            'Graduation year and age are used to match you with coaches actively recruiting your class.'),
        ],
      ),
    );
  }
}

// ─── Step 2: How You Play ───────────────────────────────────────────────────────

class _StepHowYouPlay extends StatelessWidget {
  final String? primaryPosition;
  final String? footPreference;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final int? speedRating;
  final ValueChanged<String?> onPositionChanged;
  final ValueChanged<String?> onFootChanged;
  final ValueChanged<int?> onSpeedChanged;

  const _StepHowYouPlay({
    required this.primaryPosition,
    required this.footPreference,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.speedRating,
    required this.onPositionChanged,
    required this.onFootChanged,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accentColor = isDark ? PlayerColors.accent : AppColors.playerColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '⚽',
            title: 'How You Play',
            subtitle: 'Your physical profile for the matching engine',
          ),
          const SizedBox(height: 28),

          // Primary Position
          _fieldLabel('Primary Position *', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PlayerProfileData.positions.map((pos) {
              final selected = primaryPosition == pos.id;
              return _SelectChip(
                label: '${pos.abbreviation}\n${pos.name}',
                isSelected: selected,
                color: accentColor,
                onTap: () => onPositionChanged(selected ? null : pos.id),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Height + Weight
          _fieldLabel('Physical Measurements', isDark),
          const SizedBox(height: 4),
          Text('Used to assess physical build — key for roles like CB, CDM, and ST',
            style: TextStyle(fontSize: 11,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ProfileTextField(
                  controller: heightCtrl,
                  label: 'Height (cm)',
                  hint: 'e.g. 178',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileTextField(
                  controller: weightCtrl,
                  label: 'Weight (kg)',
                  hint: 'e.g. 72',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dominant foot
          _fieldLabel('Dominant Foot', isDark),
          const SizedBox(height: 8),
          Row(
            children: ['Right', 'Left', 'Both'].map((foot) {
              final selected = footPreference == foot;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SelectChip(
                  label: foot,
                  isSelected: selected,
                  color: accentColor,
                  onTap: () => onFootChanged(selected ? null : foot),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Speed rating
          Row(
            children: [
              Expanded(
                child: _fieldLabel('Speed Rating', isDark),
              ),
              Text(
                speedRating != null ? '$speedRating / 10' : 'Not set',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: speedRating != null
                      ? accentColor
                      : (isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Rate your pace and acceleration honestly — 6 is average, 8 is fast',
            style: TextStyle(fontSize: 11,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary)),
          Slider(
            value: (speedRating ?? 0).toDouble(),
            min: 0, max: 10, divisions: 10,
            activeColor: accentColor,
            inactiveColor: isDark ? PlayerColors.border : AppColors.border,
            onChanged: (v) => onSpeedChanged(v == 0 ? null : v.round()),
          ),

          const SizedBox(height: 8),
          _matchingEngineNote(isDark,
            'Height, weight, foot preference, and speed are compared directly against each coach\'s position requirements.'),
        ],
      ),
    );
  }
}

// ─── Step 3: Academic Goals ─────────────────────────────────────────────────────

class _StepAcademicGoals extends StatelessWidget {
  final TextEditingController gpaCtrl;
  final String? targetDivision;
  final ValueChanged<String?> onDivisionChanged;

  const _StepAcademicGoals({
    required this.gpaCtrl,
    required this.targetDivision,
    required this.onDivisionChanged,
  });

  static const _divisions = [
    ('D1',   'NCAA Division I',    'Up to 9.9 scholarships (men) / 14 (women)'),
    ('D2',   'NCAA Division II',   'Up to 9.0 scholarships — competitive + academic balance'),
    ('D3',   'NCAA Division III',  'No athletic scholarships — strong academic merit aid'),
    ('NAIA', 'NAIA',               'Competitive scholarships, less strict eligibility'),
    ('JUCO', 'Junior College',     'Pathway to D1/D2 — great if grades need improvement'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accentColor = isDark ? PlayerColors.accent : AppColors.playerColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            emoji: '📚',
            title: 'Academic Goals',
            subtitle: 'Your GPA unlocks or closes programs',
          ),
          const SizedBox(height: 28),

          // GPA
          _fieldLabel('GPA (Unweighted)', isDark),
          const SizedBox(height: 4),
          Text('Enter your current unweighted GPA — e.g. 3.7',
            style: TextStyle(fontSize: 11,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: _ProfileTextField(
              controller: gpaCtrl,
              label: 'GPA',
              hint: '0.0 – 4.0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),

          const SizedBox(height: 20),

          // NCAA eligibility tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? PlayerColors.accentSubtle
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? PlayerColors.accent.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NCAA D1 requires a minimum 2.3 GPA in 16 core courses. '
                    'Register with the NCAA Eligibility Center by junior year.',
                    style: TextStyle(
                      fontSize: 12, height: 1.5,
                      color: isDark ? PlayerColors.accent : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Target division
          _fieldLabel('Target Division', isDark),
          const SizedBox(height: 8),
          ..._divisions.map((div) {
            final selected = targetDivision == div.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onDivisionChanged(selected ? null : div.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: 0.08)
                        : (isDark ? PlayerColors.surfaceVariant : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? accentColor
                          : (isDark ? PlayerColors.border : AppColors.border),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? accentColor : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? accentColor
                                : (isDark ? PlayerColors.border : AppColors.border),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Icon(Icons.check, size: 12,
                                color: isDark ? PlayerColors.textOnAccent : Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(div.$2,
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: selected
                                    ? accentColor
                                    : (isDark ? PlayerColors.textPrimary : AppColors.textPrimary),
                              )),
                            Text(div.$3,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? PlayerColors.textSecondary : AppColors.textSecondary,
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          _matchingEngineNote(isDark,
            'Your GPA is matched against each coach\'s academic minimum. Missing it generates a specific gap explanation so you know exactly what\'s holding your score down.'),
        ],
      ),
    );
  }
}

// ─── Shared Helpers ─────────────────────────────────────────────────────────────

Widget _fieldLabel(String label, bool isDark) => Text(
  label,
  style: TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
  ),
);

Widget _matchingEngineNote(bool isDark, String text) => Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: isDark ? PlayerColors.surface : AppColors.surface,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.auto_awesome, size: 14,
          color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
          style: TextStyle(
            fontSize: 11, height: 1.4,
            color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
          )),
      ),
    ],
  ),
);

// ─── Step Header ────────────────────────────────────────────────────────────────

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
        Text(title,
          style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800,
            color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
          )),
        const SizedBox(height: 4),
        Text(subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
          )),
      ],
    );
  }
}

// ─── Select Chip ────────────────────────────────────────────────────────────────

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
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12, height: 1.3,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? PlayerColors.textOnAccent : Colors.white)
                : (isDark ? PlayerColors.textPrimary : AppColors.textPrimary),
          )),
      ),
    );
  }
}

// ─── Profile Text Field ─────────────────────────────────────────────────────────

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accentColor = isDark ? PlayerColors.accent : AppColors.playerColor;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
          color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
            color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
        hintStyle: TextStyle(
            color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
        filled: true,
        fillColor: isDark ? PlayerColors.surface : AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? PlayerColors.border : AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? PlayerColors.border : AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2)),
      ),
    );
  }
}

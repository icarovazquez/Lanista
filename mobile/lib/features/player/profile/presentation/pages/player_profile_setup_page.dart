import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_data.dart';
import '../../../../../../core/theme/player_theme_scope.dart';

class PlayerProfileSetupPage extends StatefulWidget {
  final int startPage;
  const PlayerProfileSetupPage({super.key, this.startPage = 0});

  @override
  State<PlayerProfileSetupPage> createState() => _PlayerProfileSetupPageState();
}

class _PlayerProfileSetupPageState extends State<PlayerProfileSetupPage> {
  late final _pageController = PageController(initialPage: widget.startPage);
  int _page = 0;
  bool _isSaving = false;
  bool _isEditing = false; // true when launched from a nudge (not fresh onboarding)

  // Required
  final _firstNameCtrl = TextEditingController();

  final _lastNameCtrl = TextEditingController();
  int? _gradYear;
  String? _position;
  String? _secondaryPosition;

  // Optional
  String? _foot;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  int _speed = 5;
  final _clubCtrl = TextEditingController();
  String? _league;
  String? _division;
  final _school1Ctrl = TextEditingController();
  final _school2Ctrl = TextEditingController();
  final _school3Ctrl = TextEditingController();
  final Map<String, int> _skills = {
    'Dribbling': 3,
    'Passing': 3,
    'Shooting': 3,
    'Defending': 3,
    'Athleticism': 3,
  };
  final _gpaCtrl = TextEditingController();
  final _satCtrl = TextEditingController();
  final _actCtrl = TextEditingController();
  final _filmCtrl = TextEditingController();

  static const int _totalPages = 12;

  // Pages 0-3 required, 4+ optional
  bool get _requiredDone =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _lastNameCtrl.text.trim().isNotEmpty &&
      _gradYear != null &&
      _position != null;

  bool get _currentPageValid {
    switch (_page) {
      case 1: return _firstNameCtrl.text.trim().isNotEmpty && _lastNameCtrl.text.trim().isNotEmpty;
      case 2: return _gradYear != null;
      case 3: return _position != null;
      default: return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _page = widget.startPage;
    _isEditing = widget.startPage > 0;
    _firstNameCtrl.addListener(() => setState(() {}));
    _lastNameCtrl.addListener(() => setState(() {}));
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final u = await Supabase.instance.client
          .from('users')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();
      final p = await Supabase.instance.client
          .from('players')
          .select('graduation_year, primary_position, secondary_position, dominant_foot, height_cm, '
              'weight_kg, speed_rating, club_name, league, target_division, '
              'target_schools, technical_skills, gpa, sat_score, act_score, highlight_url')
          .eq('user_id', userId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        if (u != null) {
          _firstNameCtrl.text = u['first_name'] as String? ?? '';
          _lastNameCtrl.text  = u['last_name']  as String? ?? '';
        }
        if (p != null) {
          _gradYear           = p['graduation_year'] as int?;
          _position           = p['primary_position'] as String?;
          _secondaryPosition  = p['secondary_position'] as String?;
          _foot      = _footLabel(p['dominant_foot'] as String?);
          if (p['height_cm'] != null) _heightCtrl.text = '${p['height_cm']}';
          if (p['weight_kg'] != null) _weightCtrl.text = '${p['weight_kg']}';
          _speed     = (p['speed_rating'] as int?) ?? 5;
          _clubCtrl.text = p['club_name'] as String? ?? '';
          _league    = p['league'] as String?;
          _division  = p['target_division'] as String?;
          final schools = (p['target_schools'] as List?)?.cast<String>() ?? [];
          if (schools.isNotEmpty) _school1Ctrl.text = schools[0];
          if (schools.length > 1) _school2Ctrl.text = schools[1];
          if (schools.length > 2) _school3Ctrl.text = schools[2];
          final raw = p['technical_skills'] as Map<String, dynamic>?;
          if (raw != null) {
            for (final k in _skills.keys) {
              final v = raw[k.toLowerCase()];
              if (v != null) _skills[k] = (v as num).toInt();
            }
          }
          if (p['gpa'] != null) _gpaCtrl.text = '${p['gpa']}';
          if (p['sat_score'] != null) _satCtrl.text = '${p['sat_score']}';
          if (p['act_score'] != null) _actCtrl.text = '${p['act_score']}';
          _filmCtrl.text = p['highlight_url'] as String? ?? '';
        }
      });
    } catch (_) {}
  }

  String? _footLabel(String? v) {
    if (v == 'right') return 'Right';
    if (v == 'left') return 'Left';
    if (v == 'both') return 'Both (Ambidextrous)';
    return null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _clubCtrl.dispose();
    _gpaCtrl.dispose();
    _satCtrl.dispose();
    _actCtrl.dispose();
    _filmCtrl.dispose();
    _school1Ctrl.dispose();
    _school2Ctrl.dispose();
    _school3Ctrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_page < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goPrev() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('users').update({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'onboarding_complete': true,
      }).eq('id', userId);

      // Compute grade level from grad year
      final now = DateTime.now();
      final schoolYear = now.month >= 8 ? now.year + 1 : now.year;
      final gradeLevel = _gradYear != null
          ? (12 - (_gradYear! - schoolYear)).clamp(6, 13)
          : null;

      final schools = [
        _school1Ctrl.text.trim(),
        _school2Ctrl.text.trim(),
        _school3Ctrl.text.trim(),
      ].where((s) => s.isNotEmpty).toList();

      final skillsMap = _skills.entries.any((e) => e.value != 3)
          ? {for (final e in _skills.entries) e.key.toLowerCase(): e.value}
          : null;

      await Supabase.instance.client.from('players').upsert({
        'user_id': userId,
        'graduation_year': _gradYear,
        'grade_level': gradeLevel,
        'primary_position': _position,
        'secondary_position': _secondaryPosition,
        'dominant_foot': _foot?.toLowerCase().replaceAll(' (ambidextrous)', ''),
        'height_cm': int.tryParse(_heightCtrl.text.trim()),
        'weight_kg': int.tryParse(_weightCtrl.text.trim()),
        'speed_rating': _speed,
        'club_name': _clubCtrl.text.trim().isEmpty ? null : _clubCtrl.text.trim(),
        'league': _league,
        'target_division': _division,
        'target_schools': schools.isEmpty ? null : schools,
        'technical_skills': skillsMap,
        'gpa': double.tryParse(_gpaCtrl.text.trim()),
        'sat_score': int.tryParse(_satCtrl.text.trim()),
        'act_score': int.tryParse(_actCtrl.text.trim()),
        'highlight_url': _filmCtrl.text.trim().isEmpty ? null : _filmCtrl.text.trim(),
        'is_discoverable': true,
      }, onConflict: 'user_id');

      if (mounted) {
        if (_isEditing) {
          Navigator.of(context).pop();
        } else {
          context.go('/player/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
    return ListenableBuilder(
      listenable: themeService,
      builder: (_, __) => Theme(
        data: PlayerThemeData.dark,
        child: PlayerThemeScope(
          service: themeService,
          child: Scaffold(
            backgroundColor: PlayerColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    page: _page,
                    total: _totalPages,
                    onBack: _page > widget.startPage
                        ? _goPrev
                        : (_isEditing ? () => Navigator.of(context).pop() : null),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (p) => setState(() => _page = p),
                      children: [
                        _WelcomePage(onStart: _goNext),
                        _NamePage(first: _firstNameCtrl, last: _lastNameCtrl),
                        _GradYearPage(selected: _gradYear,
                            onSelect: (y) => setState(() => _gradYear = y)),
                        _PositionPage(
                            selected: _position,
                            secondarySelected: _secondaryPosition,
                            onSelect: (p) => setState(() {
                              _position = p;
                              if (_secondaryPosition == p) _secondaryPosition = null;
                            }),
                            onSecondarySelect: (p) => setState(() =>
                                _secondaryPosition = _secondaryPosition == p ? null : p)),
                        _PhysicalPage(foot: _foot, height: _heightCtrl,
                            weight: _weightCtrl, speed: _speed,
                            onFoot: (f) => setState(() => _foot = f),
                            onSpeed: (s) => setState(() => _speed = s)),
                        _ClubPage(club: _clubCtrl, league: _league,
                            onLeague: (l) => setState(() => _league = l)),
                        _DivisionPage(selected: _division,
                            onSelect: (d) => setState(() => _division = d)),
                        _SchoolsPage(s1: _school1Ctrl, s2: _school2Ctrl, s3: _school3Ctrl),
                        _AssessmentPage(skills: _skills,
                            onChange: (k, v) => setState(() => _skills[k] = v)),
                        _AcademicsPage(gpa: _gpaCtrl, sat: _satCtrl, act: _actCtrl),
                        _FilmPage(ctrl: _filmCtrl),
                        _DonePage(
                          firstName: _firstNameCtrl.text.trim(),
                          isSaving: _isSaving,
                          onFinish: _save,
                        ),
                      ],
                    ),
                  ),
                  if (_page > 0 && _page < _totalPages - 1)
                    _BottomActions(
                      canContinue: _currentPageValid,
                      isOptional: _page >= 4,
                      requiredDone: _requiredDone,
                      onContinue: _goNext,
                      onSkip: _goNext,
                      onSkipAll: _skipToEnd,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar with progress ──────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback? onBack;

  const _TopBar({required this.page, required this.total, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: PlayerColors.textSecondary,
              onPressed: onBack,
              splashRadius: 20,
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: page / (total - 1),
                backgroundColor: const Color(0xFF2A2A2A),
                valueColor: AlwaysStoppedAnimation(PlayerColors.accent),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${page > 0 ? page : 0}/${total - 1}',
            style: TextStyle(fontSize: 11, color: PlayerColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Bottom actions ─────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final bool canContinue;
  final bool isOptional;
  final bool requiredDone;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onSkipAll;

  const _BottomActions({
    required this.canContinue,
    required this.isOptional,
    required this.requiredDone,
    required this.onContinue,
    required this.onSkip,
    required this.onSkipAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canContinue ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayerColors.accent,
                disabledBackgroundColor: PlayerColors.accent.withValues(alpha: 0.3),
                foregroundColor: PlayerColors.textOnAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (isOptional) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text('Skip this step',
                      style: TextStyle(color: PlayerColors.textTertiary, fontSize: 13)),
                ),
                if (requiredDone) ...[
                  Text('·', style: TextStyle(color: PlayerColors.textTertiary)),
                  TextButton(
                    onPressed: onSkipAll,
                    child: Text('Skip to dashboard',
                        style: TextStyle(color: PlayerColors.textTertiary, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final String question;
  final String? hint;
  final Widget child;
  const _PageShell({
    required this.question,
    this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(hint!, style: TextStyle(fontSize: 14, color: PlayerColors.textSecondary, height: 1.4)),
          ],
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

Widget _darkField(TextEditingController ctrl, String label, {
  TextInputType? keyboardType,
  List<TextInputFormatter>? formatters,
  String? hint,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    style: const TextStyle(color: Colors.white, fontSize: 16),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: PlayerColors.textSecondary),
      hintStyle: TextStyle(color: PlayerColors.textTertiary),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PlayerColors.accent, width: 1.5),
      ),
    ),
  );
}

// ── Page 0: Welcome ────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: PlayerColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.sports_soccer_rounded, color: PlayerColors.accent, size: 30),
          ),
          const SizedBox(height: 28),
          const Text('Build your\nrecruiting profile.',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.15)),
          const SizedBox(height: 16),
          Text(
            'College coaches are looking for players like you. '
            'A complete profile gets you 4× more matches.',
            style: TextStyle(fontSize: 15, color: PlayerColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text('Takes about 3 minutes.',
            style: TextStyle(fontSize: 13, color: PlayerColors.textTertiary)),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayerColors.accent,
                foregroundColor: PlayerColors.textOnAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text("Let's go →",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 1: Name ───────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController first;
  final TextEditingController last;

  const _NamePage({required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: "What's your name?",
      child: Column(children: [
        _darkField(first, 'First name'),
        const SizedBox(height: 14),
        _darkField(last, 'Last name'),
      ]),
    );
  }
}

// ── Page 2: Graduation Year ────────────────────────────────────────────────────

class _GradYearPage extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelect;

  const _GradYearPage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const years = [2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032];
    return _PageShell(
      question: 'When do you graduate?',
      hint: 'This helps us personalize your recruiting roadmap.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: years.map((y) {
          final sel = selected == y;
          return GestureDetector(
            onTap: () => onSelect(y),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: sel ? PlayerColors.accent.withValues(alpha: 0.15) : const Color(0xFF1A1A1A),
                border: Border.all(
                  color: sel ? PlayerColors.accent : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Class of $y',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? PlayerColors.accent : PlayerColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Page 3: Position ───────────────────────────────────────────────────────────

class _PositionPage extends StatelessWidget {
  final String? selected;
  final String? secondarySelected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onSecondarySelect;

  const _PositionPage({
    required this.selected,
    required this.secondarySelected,
    required this.onSelect,
    required this.onSecondarySelect,
  });

  static const _groups = [
    ('Goalkeeper', [('GK', 'Goalkeeper')]),
    ('Defense', [('CB', 'Center Back'), ('RB', 'Right Back'), ('LB', 'Left Back'), ('RWB', 'R Wing Back'), ('LWB', 'L Wing Back')]),
    ('Midfield', [('CDM', 'Def. Mid'), ('CM', 'Central Mid'), ('CAM', 'Attack. Mid'), ('RM', 'Right Mid'), ('LM', 'Left Mid')]),
    ('Attack', [('RW', 'Right Wing'), ('LW', 'Left Wing'), ('CF', 'Center Fwd'), ('ST', 'Striker')]),
  ];

  Widget _positionGrid(String? active, ValueChanged<String> onTap, {String? disabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groups.map((group) {
        final (groupName, positions) = group;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupName.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: PlayerColors.textTertiary, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: positions.map((pos) {
                final (abbr, name) = pos;
                final sel = active == abbr;
                final isDisabled = abbr == disabled;
                return GestureDetector(
                  onTap: isDisabled ? null : () => onTap(abbr),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? const Color(0xFF111111)
                          : sel
                              ? const Color(0xFF4A9D6F).withValues(alpha: 0.15)
                              : const Color(0xFF1A1A1A),
                      border: Border.all(
                        color: isDisabled
                            ? Colors.transparent
                            : sel
                                ? const Color(0xFF4A9D6F)
                                : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(abbr, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: isDisabled
                              ? PlayerColors.textTertiary.withValues(alpha: 0.3)
                              : sel
                                  ? const Color(0xFF4A9D6F)
                                  : Colors.white)),
                        Text(name, style: TextStyle(
                          fontSize: 9,
                          color: isDisabled
                              ? PlayerColors.textTertiary.withValues(alpha: 0.2)
                              : sel
                                  ? const Color(0xFF4A9D6F).withValues(alpha: 0.8)
                                  : PlayerColors.textTertiary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: "What's your position?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary position (accent = lime)
          _positionGrid(selected, onSelect),
          const SizedBox(height: 8),
          // Secondary position
          Text('Also plays (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: PlayerColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Tap to select a secondary position. Tap again to remove.',
            style: TextStyle(fontSize: 12, color: PlayerColors.textTertiary)),
          const SizedBox(height: 16),
          _positionGrid(secondarySelected, onSecondarySelect, disabled: selected),
        ],
      ),
    );
  }
}

// ── Page 4: Physical ───────────────────────────────────────────────────────────

class _PhysicalPage extends StatelessWidget {
  final String? foot;
  final TextEditingController height;
  final TextEditingController weight;
  final int speed;
  final ValueChanged<String> onFoot;
  final ValueChanged<int> onSpeed;

  const _PhysicalPage({
    required this.foot, required this.height, required this.weight,
    required this.speed, required this.onFoot, required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    const feet = ['Right', 'Left', 'Both (Ambidextrous)'];
    return _PageShell(
      question: 'Physical profile',
      hint: 'Coaches filter by height and speed — fill in what you know.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dominant foot', style: TextStyle(fontSize: 13,
              color: PlayerColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: feet.map((f) {
              final sel = foot == f;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onFoot(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: sel ? PlayerColors.accent.withValues(alpha: 0.15) : const Color(0xFF1A1A1A),
                      border: Border.all(
                          color: sel ? PlayerColors.accent : Colors.transparent, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      f == 'Both (Ambidextrous)' ? 'Both' : f,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? PlayerColors.accent : PlayerColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _darkField(height, 'Height (cm)',
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: 12),
            Expanded(child: _darkField(weight, 'Weight (kg)',
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly])),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Text('Speed / Pace', style: TextStyle(fontSize: 13,
                color: PlayerColors.textSecondary, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$speed / 10', style: TextStyle(
                fontSize: 13, color: PlayerColors.accent, fontWeight: FontWeight.w700)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: PlayerColors.accent,
              inactiveTrackColor: const Color(0xFF2A2A2A),
              thumbColor: PlayerColors.accent,
              overlayColor: PlayerColors.accent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: speed.toDouble(),
              min: 1, max: 10, divisions: 9,
              onChanged: (v) => onSpeed(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Average', style: TextStyle(fontSize: 10, color: PlayerColors.textTertiary)),
              Text('Elite pace', style: TextStyle(fontSize: 10, color: PlayerColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 5: Club & League ──────────────────────────────────────────────────────

class _ClubPage extends StatelessWidget {
  final TextEditingController club;
  final String? league;
  final ValueChanged<String?> onLeague;

  const _ClubPage({required this.club, required this.league, required this.onLeague});

  static const _leagues = [
    'MLS NEXT', 'ECNL Boys', 'ECNL Girls',
    'Girls Academy', 'ECRL', 'NPL', 'State / High School', 'Regional Club', 'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: 'What club do you play for?',
      hint: 'MLS NEXT and ECNL players get priority visibility with D1 coaches.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _darkField(club, 'Club name', hint: 'e.g. LA Galaxy Academy'),
          const SizedBox(height: 24),
          Text('League', style: TextStyle(fontSize: 13,
              color: PlayerColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _leagues.map((l) {
              final sel = league == l;
              return GestureDetector(
                onTap: () => onLeague(sel ? null : l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? PlayerColors.accent.withValues(alpha: 0.15) : const Color(0xFF1A1A1A),
                    border: Border.all(
                        color: sel ? PlayerColors.accent : Colors.transparent, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(l, style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? PlayerColors.accent : PlayerColors.textPrimary,
                  )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Page 6: Division ───────────────────────────────────────────────────────────

class _DivisionPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _DivisionPage({required this.selected, required this.onSelect});

  static const _divs = [
    ('D1', 'NCAA Division I', 'The most competitive. Scholarship available.'),
    ('D2', 'NCAA Division II', 'Competitive with partial scholarships.'),
    ('D3', 'NCAA Division III', 'No athletic scholarships — academic focus.'),
    ('NAIA', 'NAIA', 'Scholarship programs at smaller colleges.'),
    ('JUCO', 'Junior College', 'Develop first, transfer to 4-year later.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: 'What level do you want to play at?',
      hint: 'Be honest — it helps us match you with programs where you can actually play.',
      child: Column(
        children: _divs.map((d) {
          final (id, name, desc) = d;
          final sel = selected == id;
          return GestureDetector(
            onTap: () => onSelect(sel ? null : id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: sel ? PlayerColors.accent.withValues(alpha: 0.12) : const Color(0xFF1A1A1A),
                border: Border.all(
                    color: sel ? PlayerColors.accent : Colors.transparent, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: sel ? PlayerColors.accent : Colors.white)),
                        const SizedBox(height: 2),
                        Text(desc, style: TextStyle(
                          fontSize: 11, color: PlayerColors.textTertiary)),
                      ],
                    ),
                  ),
                  if (sel) Icon(Icons.check_circle_rounded,
                      color: PlayerColors.accent, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Page 7: Target Schools ─────────────────────────────────────────────────────

class _SchoolsPage extends StatelessWidget {
  final TextEditingController s1;
  final TextEditingController s2;
  final TextEditingController s3;

  const _SchoolsPage({required this.s1, required this.s2, required this.s3});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: 'Any schools on your radar?',
      hint: 'Add up to 3 programs you\'re targeting. We\'ll prioritize those coaches in your matches.',
      child: Column(children: [
        _darkField(s1, 'School #1', hint: 'e.g. University of Virginia'),
        const SizedBox(height: 14),
        _darkField(s2, 'School #2 (optional)', hint: 'e.g. Wake Forest'),
        const SizedBox(height: 14),
        _darkField(s3, 'School #3 (optional)', hint: 'e.g. Georgetown'),
      ]),
    );
  }
}

// ── Page 8: Self-Assessment ────────────────────────────────────────────────────

class _AssessmentPage extends StatelessWidget {
  final Map<String, int> skills;
  final void Function(String, int) onChange;

  const _AssessmentPage({required this.skills, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: 'Rate your skills honestly.',
      hint: 'Coaches respect self-awareness. This is for your roadmap, not your public profile.',
      child: Column(
        children: skills.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(e.key, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  _SkillBadge(value: e.value),
                ]),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (i) {
                    final v = i + 1;
                    final sel = e.value == v;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChange(e.key, v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? PlayerColors.accent.withValues(alpha: 0.2)
                                : const Color(0xFF1A1A1A),
                            border: Border.all(
                                color: sel ? PlayerColors.accent : Colors.transparent,
                                width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$v',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                              color: sel ? PlayerColors.accent : PlayerColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final int value;
  const _SkillBadge({required this.value});

  String get _label {
    switch (value) {
      case 1: return 'Beginner';
      case 2: return 'Below avg';
      case 3: return 'Average';
      case 4: return 'Above avg';
      case 5: return 'Elite';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PlayerColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PlayerColors.accent)),
    );
  }
}

// ── Page 9: Academics ──────────────────────────────────────────────────────────

class _AcademicsPage extends StatelessWidget {
  final TextEditingController gpa;
  final TextEditingController sat;
  final TextEditingController act;

  const _AcademicsPage({required this.gpa, required this.sat, required this.act});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: 'How are your grades?',
      hint: 'D3 and NAIA programs weight academics heavily. D1 coaches need NCAA-eligible GPAs.',
      child: Column(children: [
        _darkField(gpa, 'GPA (e.g. 3.7)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _darkField(sat, 'SAT score',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly])),
          const SizedBox(width: 12),
          Expanded(child: _darkField(act, 'ACT score',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly])),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: PlayerColors.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Academic info is never shared with coaches without your permission.',
                  style: TextStyle(fontSize: 12, color: PlayerColors.textTertiary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Page 10: Film ──────────────────────────────────────────────────────────────

class _FilmPage extends StatelessWidget {
  final TextEditingController ctrl;
  const _FilmPage({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      question: 'Got a highlight reel?',
      hint: 'Paste a Hudl or YouTube link. Coaches with film are 3× more likely to reach out.',
      child: Column(children: [
        _darkField(ctrl, 'Hudl or YouTube URL',
            hint: 'https://www.hudl.com/...',
            keyboardType: TextInputType.url),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.videocam_outlined, size: 16, color: PlayerColors.accent.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Don't have one yet? You can add it later from the Film tab in the dashboard.",
                  style: TextStyle(fontSize: 12, color: PlayerColors.textTertiary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Page 11: Done ──────────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  final String firstName;
  final bool isSaving;
  final VoidCallback onFinish;

  const _DonePage({required this.firstName, required this.isSaving, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: PlayerColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: PlayerColors.accent, size: 34),
          ),
          const SizedBox(height: 28),
          Text(
            firstName.isNotEmpty ? 'You\'re all set, $firstName!' : 'You\'re all set!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Your profile is live. College coaches can already start finding you.',
            style: TextStyle(fontSize: 15, color: PlayerColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'You can complete or edit any section from your profile settings anytime.',
            style: TextStyle(fontSize: 13, color: PlayerColors.textTertiary, height: 1.4),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isSaving ? null : onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayerColors.accent,
                foregroundColor: PlayerColors.textOnAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                  : const Text('Go to dashboard →',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}


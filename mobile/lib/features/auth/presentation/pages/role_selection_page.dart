import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/config/app_config_service.dart';
import '../../../../../shared/models/user_role.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _confirmRole() async {
    if (_selectedRole == null) return;
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;

      // Guard: if session was lost, redirect to login
      if (currentUser == null) {
        if (mounted) context.go('/auth/login');
        return;
      }

      final userId = currentUser.id;
      final userEmail = currentUser.email ?? '';
      final userMeta = currentUser.userMetadata ?? {};
      final firstName = (userMeta['first_name'] as String?) ?? '';
      final lastName = (userMeta['last_name'] as String?) ?? '';

      debugPrint('=== ROLE SELECT: userId=$userId role=${_selectedRole!.name}');

      // Try UPDATE first (row likely exists from auth trigger).
      // If it doesn't exist yet, fall back to INSERT.
      List<Map<String, dynamic>> updateRes = [];
      try {
        updateRes = await client
            .from('users')
            .update({
              'role': _selectedRole!.name,
              'first_name': firstName,
              'last_name': lastName,
              'language': 'en',
              'is_active': true,
            })
            .eq('id', userId)
            .select('id');
        debugPrint('=== UPDATE result: $updateRes');
      } catch (updateErr) {
        debugPrint('=== UPDATE error: $updateErr');
        // If update fails, try insert
      }

      if (updateRes.isEmpty) {
        debugPrint('=== Trying INSERT...');
        try {
          await client.from('users').insert({
            'id': userId,
            'email': userEmail,
            'role': _selectedRole!.name,
            'first_name': firstName,
            'last_name': lastName,
            'language': 'en',
            'is_active': true,
          });
          debugPrint('=== INSERT done');
        } catch (insertErr) {
          debugPrint('=== INSERT error: $insertErr');
          // Row likely already exists, continue anyway
        }
      }

      debugPrint('=== Navigating to dashboard...');

      if (!mounted) return;
      switch (_selectedRole!) {
        case UserRole.player:
          // New players go through profile setup first
          context.go('/player/profile/setup');
          break;
        case UserRole.coach:
          // New coaches go through tactical blueprint first
          context.go('/coach/tactical-blueprint');
          break;
        case UserRole.parent:
          context.go('/parent/dashboard');
          break;
        case UserRole.mentor:
          context.go('/mentor/dashboard');
          break;
        case UserRole.admin:
          context.go('/player/dashboard');
          break;
      }
    } catch (e, st) {
      debugPrint('Role selection error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 8),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCoachWaitlistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CoachWaitlistSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('⚽', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LANISTA',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(l10n.whoAreYou, style: theme.textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(l10n.selectYourRole, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      role: UserRole.player,
                      title: l10n.iAmAPlayer,
                      description: l10n.playerDescription,
                      icon: '⚽',
                      color: AppColors.playerColor,
                      isSelected: _selectedRole == UserRole.player,
                      onTap: () => setState(() => _selectedRole = UserRole.player),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      role: UserRole.parent,
                      title: l10n.iAmAParent,
                      description: l10n.parentDescription,
                      icon: '👨‍👩‍👧',
                      color: AppColors.parentColor,
                      isSelected: _selectedRole == UserRole.parent,
                      onTap: () => setState(() => _selectedRole = UserRole.parent),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      role: UserRole.coach,
                      title: l10n.iAmACoach,
                      description: l10n.coachDescription,
                      icon: '📋',
                      color: AppColors.coachColor,
                      isSelected: _selectedRole == UserRole.coach,
                      onTap: () {
                        if (AppConfigService.coachAccessEnabled) {
                          setState(() => _selectedRole = UserRole.coach);
                        } else {
                          _showCoachWaitlistSheet(context);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      role: UserRole.mentor,
                      title: l10n.iAmAMentor,
                      description: l10n.mentorDescription,
                      icon: '🎓',
                      color: AppColors.mentorColor,
                      isSelected: _selectedRole == UserRole.mentor,
                      onTap: () => setState(() => _selectedRole = UserRole.mentor),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _selectedRole == null || _isLoading
                    ? null
                    : _confirmRole,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(l10n.next),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coach Waitlist Bottom Sheet ────────────────────────────────────────────────

class _CoachWaitlistSheet extends StatefulWidget {
  const _CoachWaitlistSheet();

  @override
  State<_CoachWaitlistSheet> createState() => _CoachWaitlistSheetState();
}

class _CoachWaitlistSheetState extends State<_CoachWaitlistSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  String? _division;
  bool _isSubmitting = false;
  bool _submitted = false;

  static const _divisions = ['NCAA D1', 'NCAA D2', 'NCAA D3', 'NAIA', 'JUCO'];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client.from('coach_waitlist').insert({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'school': _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
        'division': _division,
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + bottomPad),
      child: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.coachColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('🎉', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 20),
        const Text(
          "You're on the list!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          "We're launching the coach side soon. We'll email you the moment access opens.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.coachColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('📋', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach Access Coming Soon',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      "Join the waitlist — we'll notify you when it's live.",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _field(_firstNameCtrl, 'First name', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_lastNameCtrl, 'Last name', required: true)),
            ],
          ),
          const SizedBox(height: 12),
          _field(_emailCtrl, 'Email', keyboardType: TextInputType.emailAddress, required: true),
          const SizedBox(height: 12),
          _field(_schoolCtrl, 'School / Program (optional)'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _division,
            decoration: _inputDecoration('Division (optional)'),
            items: _divisions
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _division = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coachColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Join Waitlist', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      );
}

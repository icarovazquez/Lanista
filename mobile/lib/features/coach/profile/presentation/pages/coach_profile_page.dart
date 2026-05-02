import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Coach profile page — shows the logged-in coach's profile info.
/// Accessible via the "M" avatar menu → "My Profile".
class CoachProfilePage extends StatefulWidget {
  const CoachProfilePage({super.key});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _coach;
  Map<String, dynamic>? _college;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final userRow = await Supabase.instance.client
          .from('users')
          .select('first_name, last_name, email, language')
          .eq('id', userId)
          .single();

      final coachRow = await Supabase.instance.client
          .from('coaches')
          .select(
            'id, coach_type, gender_program, bio, min_gpa, min_sat, min_act, '
            'subscription_tier, primary_formation, playing_styles, '
            'recruiting_class_years, recruiting_notes, website_url, '
            'college_id',
          )
          .eq('user_id', userId)
          .maybeSingle();

      Map<String, dynamic>? collegeRow;
      final collegeId = coachRow?['college_id'];
      if (collegeId != null) {
        try {
          collegeRow = await Supabase.instance.client
              .from('colleges')
              .select('name, city, state, division_id')
              .eq('id', collegeId)
              .maybeSingle();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _user = userRow;
          _coach = coachRow;
          _college = collegeRow;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _fullName {
    final first = _user?['first_name'] as String? ?? '';
    final last = _user?['last_name'] as String? ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Coach' : name;
  }

  String get _initials {
    final first = _user?['first_name'] as String? ?? '';
    final last = _user?['last_name'] as String? ?? '';
    if (first.isEmpty && last.isEmpty) return 'C';
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }

  String get _coachTypeLabel {
    final t = _coach?['coach_type'] as String? ?? 'assistant';
    return t == 'head' ? 'Head Coach' : 'Assistant Coach';
  }

  String get _subscriptionLabel {
    switch (_coach?['subscription_tier'] as String? ?? 'free') {
      case 'premium': return 'Premium';
      case 'institutional': return 'Institutional';
      default: return 'Free';
    }
  }

  Color get _subscriptionColor {
    switch (_coach?['subscription_tier'] as String? ?? 'free') {
      case 'premium': return const Color(0xFFFFAA00);
      case 'institutional': return AppColors.coachColor;
      default: return AppColors.textSecondary;
    }
  }

  String _formatGpa(dynamic val) {
    if (val == null) return '—';
    final d = double.tryParse(val.toString());
    return d != null ? d.toStringAsFixed(2) : val.toString();
  }

  String _formatList(dynamic val) {
    if (val == null) return '—';
    if (val is List && val.isNotEmpty) {
      return val.map((e) => e.toString()).join(', ');
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero App Bar ─────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.coachColor,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.coachColor,
                            AppColors.coachColor.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.25),
                                    child: Text(
                                      _initials,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _coachTypeLabel,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                        ),
                                        if (_college != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              _college!['name'] as String?,
                                              _college!['city'] as String?,
                                              _college!['state'] as String?,
                                            ]
                                                .where((s) =>
                                                    s != null && s.isNotEmpty)
                                                .join(', '),
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Body ─────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Subscription badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _subscriptionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_outlined,
                                  size: 14, color: _subscriptionColor),
                              const SizedBox(width: 6),
                              Text(
                                '$_subscriptionLabel Plan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _subscriptionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bio
                        if (_coach?['bio'] != null &&
                            (_coach!['bio'] as String).isNotEmpty) ...[
                          _SectionHeader(title: 'About', emoji: '💬'),
                          const SizedBox(height: 12),
                          _ProfileCard(
                            child: Text(
                              _coach!['bio'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Recruiting criteria
                        _SectionHeader(
                            title: 'Recruiting Criteria', emoji: '🎯'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Min GPA',
                                value: _formatGpa(_coach?['min_gpa']),
                              ),
                              _InfoRow(
                                label: 'Min SAT',
                                value: _coach?['min_sat']?.toString() ?? '—',
                              ),
                              _InfoRow(
                                label: 'Min ACT',
                                value: _coach?['min_act']?.toString() ?? '—',
                              ),
                              _InfoRow(
                                label: 'Program',
                                value: _coach?['gender_program'] != null
                                    ? _capitalize(
                                        _coach!['gender_program'] as String)
                                    : '—',
                              ),
                              _InfoRow(
                                label: 'Recruiting Classes',
                                value: _formatList(
                                    _coach?['recruiting_class_years']),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tactical preferences — tap to open blueprint wizard
                        _SectionHeader(
                            title: 'Tactical Preferences', emoji: '📋'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/coach/tactical-blueprint'),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.coachColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _InfoRow(
                                        label: 'Primary Formation',
                                        value: _coach?['primary_formation']
                                                as String? ??
                                            '—',
                                      ),
                                      _InfoRow(
                                        label: 'Playing Styles',
                                        value: _formatList(
                                            _coach?['playing_styles']),
                                        isLast: true,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.coachColor
                                        .withValues(alpha: 0.06),
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(16)),
                                    border: Border(
                                      top: BorderSide(
                                        color: AppColors.coachColor
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Edit Tactical Blueprint',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.coachColor,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios,
                                          size: 12,
                                          color: AppColors.coachColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Account
                        _SectionHeader(title: 'Account', emoji: '👤'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Email',
                                value: _user?['email'] as String? ?? '—',
                              ),
                              if (_coach?['website_url'] != null &&
                                  (_coach!['website_url'] as String)
                                      .isNotEmpty) ...[
                                _InfoRow(
                                  label: 'Program Website',
                                  value:
                                      _coach!['website_url'] as String,
                                  isLast: true,
                                ),
                              ] else ...[
                                const _InfoRow(
                                  label: 'Program Website',
                                  value: '—',
                                  isLast: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionHeader({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;
  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

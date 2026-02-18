import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../data/player_profile_data.dart';

/// Displays the saved player profile with all data from the DB.
/// Accessible from the "My Profile" menu on the player dashboard.
class PlayerProfilePage extends StatefulWidget {
  const PlayerProfilePage({super.key});

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _player;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait([
        Supabase.instance.client
            .from('users')
            .select('first_name, last_name, email, language, created_at')
            .eq('id', userId)
            .single(),
        Supabase.instance.client
            .from('players')
            .select(
              'grade, graduation_year, primary_position, secondary_position, '
              'dominant_foot, club_name, league, gpa, sat_score, act_score, '
              'bio, target_divisions, is_discoverable, height_cm',
            )
            .eq('user_id', userId)
            .maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0];
          _player = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _positionLabel(String? id) {
    if (id == null) return '—';
    try {
      return PlayerProfileData.positions
          .firstWhere((p) => p.id == id)
          .name;
    } catch (_) {
      return id;
    }
  }

  String _gradeLabel(dynamic grade) {
    if (grade == null) return '—';
    final id = grade.toString();
    try {
      return PlayerProfileData.gradeLevels
          .firstWhere((g) => g.id == id)
          .label;
    } catch (_) {
      return 'Grade $id';
    }
  }

  String _footLabel(String? foot) {
    if (foot == null) return '—';
    switch (foot) {
      case 'right': return 'Right';
      case 'left': return 'Left';
      case 'both': return 'Both (Ambidextrous)';
      default: return foot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero App Bar ─────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => context.push('/player/profile/setup'),
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 16),
                      label: const Text('Edit',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
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
                                      _user?['first_name'] != null &&
                                              (_user!['first_name'] as String)
                                                  .isNotEmpty
                                          ? (_user!['first_name'] as String)[0]
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 28,
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
                                          '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}'
                                              .trim()
                                              .isEmpty
                                              ? 'Player'
                                              : '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}'
                                                  .trim(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (_player?['primary_position'] !=
                                            null)
                                          Text(
                                            _positionLabel(
                                                _player!['primary_position']),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
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

                // ── Profile Sections ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Discoverable badge
                        if (_player != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (_player!['is_discoverable'] == true
                                      ? AppColors.success
                                      : AppColors.textSecondary)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _player!['is_discoverable'] == true
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 14,
                                  color: _player!['is_discoverable'] == true
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _player!['is_discoverable'] == true
                                      ? 'Visible to coaches'
                                      : 'Hidden from coaches',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _player!['is_discoverable'] == true
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Bio
                        if (_player?['bio'] != null &&
                            (_player!['bio'] as String).isNotEmpty) ...[
                          _SectionHeader(title: 'About Me', emoji: '💬'),
                          const SizedBox(height: 12),
                          _ProfileCard(
                            child: Text(
                              _player!['bio'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Soccer info
                        _SectionHeader(title: 'Soccer', emoji: '⚽'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Primary Position',
                                value: _positionLabel(
                                    _player?['primary_position']),
                              ),
                              if (_player?['secondary_position'] != null)
                                _InfoRow(
                                  label: 'Secondary Position',
                                  value: _positionLabel(
                                      _player!['secondary_position']),
                                ),
                              _InfoRow(
                                label: 'Dominant Foot',
                                value: _footLabel(_player?['dominant_foot']),
                              ),
                              _InfoRow(
                                label: 'Current Club',
                                value: _player?['club_name'] ?? '—',
                                isLast: _player?['league'] == null,
                              ),
                              if (_player?['league'] != null)
                                _InfoRow(
                                  label: 'League',
                                  value: _player!['league'],
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Academic info
                        _SectionHeader(title: 'Academics', emoji: '📚'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Grade',
                                value: _gradeLabel(_player?['grade']),
                              ),
                              _InfoRow(
                                label: 'Graduation Year',
                                value: _player?['graduation_year']?.toString() ?? '—',
                              ),
                              _InfoRow(
                                label: 'GPA (Unweighted)',
                                value: _player?['gpa']?.toString() ?? '—',
                              ),
                              _InfoRow(
                                label: 'SAT Score',
                                value: _player?['sat_score']?.toString() ?? '—',
                              ),
                              _InfoRow(
                                label: 'ACT Score',
                                value: _player?['act_score']?.toString() ?? '—',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Target divisions
                        if (_player?['target_divisions'] != null &&
                            (_player!['target_divisions'] as List).isNotEmpty) ...[
                          _SectionHeader(
                              title: 'Target Divisions', emoji: '🎯'),
                          const SizedBox(height: 12),
                          _ProfileCard(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_player!['target_divisions'] as List)
                                  .map((div) => _DivisionChip(label: div.toString()))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Contact / account info
                        _SectionHeader(title: 'Account', emoji: '👤'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Email',
                                value: _user?['email'] ?? '—',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Edit profile button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/player/profile/setup'),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

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
        if (!isLast)
          const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _DivisionChip extends StatelessWidget {
  final String label;
  const _DivisionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.playerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.playerColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.playerColor,
        ),
      ),
    );
  }
}

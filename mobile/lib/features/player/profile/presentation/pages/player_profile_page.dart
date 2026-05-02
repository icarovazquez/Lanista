import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_data.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';
import '../../data/player_profile_data.dart';
import '../../../video/presentation/pages/player_video_page.dart';
import '../../../schedule/presentation/pages/player_schedule_page.dart';

/// Displays the saved player profile with all data from the DB.
/// Accessible from the "My Profile" menu on the player dashboard.
///
/// This is a GoRouter PUSHED route (context.push('/player/profile')), meaning
/// it sits outside the PlayerThemeScope tree in PlayerDashboardPage. The
/// pushed-route pattern wraps build() in ListenableBuilder + Theme +
/// PlayerThemeScope so dark-mode changes propagate correctly here too.
class PlayerProfilePage extends StatefulWidget {
  const PlayerProfilePage({super.key});

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _player;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _gameFilm = [];
  List<Map<String, dynamic>> _events = [];

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
              'id, grade, graduation_year, primary_position, secondary_position, '
              'dominant_foot, club_name, league, gpa, sat_score, act_score, '
              'bio, target_divisions, is_discoverable, height_cm',
            )
            .eq('user_id', userId)
            .maybeSingle(),
      ]);

      final userResult = results[0];
      final Map<String, dynamic>? playerResult = results[1];

      // Load videos + events if player record exists
      List<Map<String, dynamic>> videos = [];
      List<Map<String, dynamic>> gameFilm = [];
      List<Map<String, dynamic>> events = [];
      if (playerResult != null) {
        final playerId = playerResult['id'] as String;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final extras = await Future.wait([
          Supabase.instance.client
              .from('player_videos')
              .select('id, title, external_url, source, is_primary, analysis_status, analysis_result')
              .eq('player_id', playerId)
              .eq('video_type', 'highlight')
              .order('is_primary', ascending: false)
              .order('uploaded_at', ascending: false)
              .limit(3),
          Supabase.instance.client
              .from('player_videos')
              .select('id, title, external_url, source, is_primary, analysis_status, analysis_result')
              .eq('player_id', playerId)
              .eq('video_type', 'game_film')
              .order('is_primary', ascending: false)
              .order('uploaded_at', ascending: false)
              .limit(3),
          Supabase.instance.client
              .from('player_schedule')
              .select('id, title, event_date, event_time, location, event_type')
              .eq('player_id', playerId)
              .gte('event_date', today)
              .order('event_date', ascending: true)
              .limit(3),
        ]);
        videos = List<Map<String, dynamic>>.from(extras[0] as List);
        gameFilm = List<Map<String, dynamic>>.from(extras[1] as List);
        events = List<Map<String, dynamic>>.from(extras[2] as List);
      }

      if (mounted) {
        setState(() {
          _user = userResult;
          _player = playerResult;
          _videos = videos;
          _gameFilm = gameFilm;
          _events = events;
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

  // ── Pushed-route dark mode pattern ──────────────────────────────────────────
  // Because this page is pushed via GoRouter it is outside the
  // PlayerThemeScope that wraps PlayerDashboardPage. We therefore
  // re-create both Theme and PlayerThemeScope here, driven by a
  // ListenableBuilder on the singleton PlayerThemeService.
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
            child: _buildPage(ctx, isDark),
          ),
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? PlayerColors.background : AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero App Bar ─────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor:
                      isDark ? PlayerColors.gradientStart : AppColors.primary,
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  PlayerColors.gradientStart,
                                  PlayerColors.gradientEnd,
                                ]
                              : [AppColors.primary, AppColors.primaryLight],
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
                                      ? (isDark
                                          ? PlayerColors.success
                                          : AppColors.success)
                                      : (isDark
                                          ? PlayerColors.textSecondary
                                          : AppColors.textSecondary))
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
                                      ? (isDark
                                          ? PlayerColors.success
                                          : AppColors.success)
                                      : (isDark
                                          ? PlayerColors.textSecondary
                                          : AppColors.textSecondary),
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
                                        ? (isDark
                                            ? PlayerColors.success
                                            : AppColors.success)
                                        : (isDark
                                            ? PlayerColors.textSecondary
                                            : AppColors.textSecondary),
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
                                color: isDark
                                    ? PlayerColors.textPrimary
                                    : AppColors.textPrimary,
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
                                  .map((div) =>
                                      _DivisionChip(label: div.toString()))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Video Highlights section
                        _SectionHeader(title: 'Highlights', emoji: '🎬'),
                        const SizedBox(height: 12),
                        _HighlightsSection(
                          videos: _videos,
                          playerId: _player?['id'] as String? ?? '',
                        ),
                        const SizedBox(height: 24),

                        // Full Game Film section
                        _SectionHeader(title: 'Full Game Film', emoji: '🎥'),
                        const SizedBox(height: 12),
                        _GameFilmSection(
                          videos: _gameFilm,
                          playerId: _player?['id'] as String? ?? '',
                        ),
                        const SizedBox(height: 24),

                        // Upcoming Games section
                        _SectionHeader(title: 'Upcoming Games', emoji: '📅'),
                        const SizedBox(height: 12),
                        _EventsSection(
                          events: _events,
                          playerId: _player?['id'] as String? ?? '',
                        ),
                        const SizedBox(height: 24),

                        // Preferences section
                        _SectionHeader(title: 'Preferences', emoji: '🎨'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          child: const _DarkModeToggleRow(),
                        ),
                        const SizedBox(height: 24),

                        // Account section
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
                              side: BorderSide(
                                color: isDark
                                    ? PlayerColors.accent
                                    : AppColors.primary,
                              ),
                              foregroundColor: isDark
                                  ? PlayerColors.accent
                                  : AppColors.primary,
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
// All sub-widgets below are inside PlayerThemeScope (via _buildPage), so they
// use PlayerThemeScope.isDark(context) rather than receiving isDark directly.

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionHeader({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
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
    final isDark = PlayerThemeScope.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? PlayerColors.border : AppColors.border,
        ),
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
    final isDark = PlayerThemeScope.isDark(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? PlayerColors.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? PlayerColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isDark ? PlayerColors.border : AppColors.border,
          ),
      ],
    );
  }
}

class _DivisionChip extends StatelessWidget {
  final String label;
  const _DivisionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? PlayerColors.accentSubtle
            : AppColors.playerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? PlayerColors.borderAccent
              : AppColors.playerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? PlayerColors.accent : AppColors.playerColor,
        ),
      ),
    );
  }
}

// ── Highlights Section ────────────────────────────────────────────────────────

class _HighlightsSection extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final String playerId;

  const _HighlightsSection({required this.videos, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);

    if (videos.isEmpty) {
      return _ProfileCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerVideoPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? PlayerColors.gradientStart.withValues(alpha: 0.15)
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🎬', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No highlights yet',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? PlayerColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Add Hudl, YouTube, or any video link',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? PlayerColors.textSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...videos.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _VideoCard(video: v, icon: Icons.play_circle_outline),
        )),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerVideoPage()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Manage Highlights →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Game Film Section ─────────────────────────────────────────────────────────

class _GameFilmSection extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final String playerId;

  const _GameFilmSection({required this.videos, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);

    if (videos.isEmpty) {
      return _ProfileCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerVideoPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? PlayerColors.gradientStart.withValues(alpha: 0.15)
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🎥', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No game film yet',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? PlayerColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Add a YouTube or Hudl full-game link',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? PlayerColors.textSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...videos.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _VideoCard(video: v, icon: Icons.videocam_outlined),
        )),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerVideoPage()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Manage Game Film →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Video Card with AI Analysis ──────────────────────────────────────────────

class _VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  final IconData icon;

  const _VideoCard({required this.video, required this.icon});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  late String _analysisStatus;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _analysisStatus = widget.video['analysis_status'] as String? ?? 'pending';
    final raw = widget.video['analysis_result'];
    if (raw is Map<String, dynamic>) _analysisResult = raw;
  }

  String _sourceLabel(String? source) {
    switch (source) {
      case 'hudl': return 'Hudl';
      case 'youtube': return 'YouTube';
      default: return source ?? 'Link';
    }
  }

  Future<void> _analyze() async {
    setState(() => _isAnalyzing = true);
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'video-analysis',
        body: {'video_id': widget.video['id']},
      );
      if (res.status == 200 && res.data?['analysis'] != null) {
        setState(() {
          _analysisStatus = 'complete';
          _analysisResult = Map<String, dynamic>.from(res.data['analysis'] as Map);
        });
      } else {
        setState(() => _analysisStatus = 'failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Analysis failed (${res.status}): ${res.data}')),
          );
        }
      }
    } catch (e) {
      setState(() => _analysisStatus = 'failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showResults() {
    if (_analysisResult == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AnalysisResultsSheet(
        title: widget.video['title'] as String? ?? 'Video',
        result: _analysisResult!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final title = widget.video['title'] as String? ?? 'Untitled';
    final url = widget.video['external_url'] as String?;
    final source = widget.video['source'] as String?;
    final isPrimary = widget.video['is_primary'] as bool? ?? false;
    final isComplete = _analysisStatus == 'complete';

    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (url == null || url.isEmpty) return;
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? PlayerColors.gradientStart.withValues(alpha: 0.15)
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(widget.icon, color: Colors.white70, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isPrimary) ...[
                              const Text('⭐', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? PlayerColors.accent : AppColors.primary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _sourceLabel(source),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? PlayerColors.accent : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 16,
                      color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // AI Analysis button
          SizedBox(
            width: double.infinity,
            child: isComplete
                ? OutlinedButton.icon(
                    onPressed: _showResults,
                    icon: const Text('✨', style: TextStyle(fontSize: 13)),
                    label: const Text('View AI Analysis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? PlayerColors.accent : AppColors.primary,
                      side: BorderSide(
                          color: isDark ? PlayerColors.accent : AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyze,
                    icon: _isAnalyzing
                        ? SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? PlayerColors.accent : AppColors.primary,
                            ),
                          )
                        : const Text('✨', style: TextStyle(fontSize: 13)),
                    label: Text(_isAnalyzing ? 'Analyzing… (2-4 min)' : 'Analyze with AI'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                      side: BorderSide(
                          color: isDark ? PlayerColors.border : AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Analysis Results Sheet ────────────────────────────────────────────────────

class _AnalysisResultsSheet extends StatelessWidget {
  final String title;
  final Map<String, dynamic> result;

  const _AnalysisResultsSheet({required this.title, required this.result});

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final bg = isDark ? PlayerColors.surface : Colors.white;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;

    final summary = result['summary'] as String? ?? '';
    final dominantFoot = result['dominant_foot'] as String? ?? '—';
    final position = result['primary_position'] as String? ?? '—';
    final style = result['playing_style'] as String? ?? '';
    final skills = (result['skills_detected'] as List?)?.cast<String>() ?? [];
    final strengths = (result['strengths'] as List?)?.cast<String>() ?? [];
    final improvements = (result['areas_for_improvement'] as List?)?.cast<String>() ?? [];
    final projection = result['college_level_projection'] as String? ?? '—';
    final rating = result['scout_rating'];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('AI Scout Report',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                ),
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$rating / 10',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: textSecondary)),
            const SizedBox(height: 16),

            // Quick stats row
            Row(
              children: [
                Expanded(child: _QuickStat(label: 'Position', value: position, isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _QuickStat(label: 'Dominant Foot', value: dominantFoot.capitalize(), isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _QuickStat(label: 'Projection', value: projection, isDark: isDark)),
              ],
            ),
            const SizedBox(height: 16),

            if (summary.isNotEmpty) ...[
              Text('Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 6),
              Text(summary, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
              const SizedBox(height: 16),
            ],

            if (style.isNotEmpty) ...[
              Text('Playing Style', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 6),
              Text(style, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
              const SizedBox(height: 16),
            ],

            if (skills.isNotEmpty) ...[
              Text('Skills Detected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                children: skills.map((s) => _chip(context, s, accent)).toList(),
              ),
              const SizedBox(height: 16),
            ],

            if (strengths.isNotEmpty) ...[
              Text('Strengths', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 8),
              ...strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ ', style: TextStyle(fontSize: 13, color: accent)),
                    Expanded(child: Text(s, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],

            if (improvements.isNotEmpty) ...[
              Text('Areas to Develop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 8),
              ...improvements.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📈 ', style: TextStyle(fontSize: 13)),
                    Expanded(child: Text(s, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4))),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 16),
            Text(
              'Powered by Twelve Labs AI · For scouting purposes only',
              style: TextStyle(fontSize: 10, color: textSecondary.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _QuickStat({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surfaceElevated : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? PlayerColors.accent : AppColors.primary,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 9, color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ── Events Section ────────────────────────────────────────────────────────────

class _EventsSection extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final String playerId;

  const _EventsSection({required this.events, required this.playerId});

  static const _monthAbbr = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  String _typeEmoji(String? type) {
    switch (type) {
      case 'showcase': return '🏟️';
      case 'tournament': return '🏆';
      case 'league_game': return '⚽';
      case 'friendly': return '🤝';
      default: return '📅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);

    if (events.isEmpty) {
      return _ProfileCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerSchedulePage()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? PlayerColors.gradientStart.withValues(alpha: 0.15)
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('📅', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming games',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? PlayerColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Add your games and showcases',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? PlayerColors.textSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...events.map((ev) {
          final title = ev['title'] as String? ?? 'Event';
          final dateStr = ev['event_date'] as String? ?? '';
          final location = ev['location'] as String?;
          final type = ev['event_type'] as String?;

          DateTime? date;
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {}

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProfileCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Date block
                  if (date != null)
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? PlayerColors.accent : AppColors.primary)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _monthAbbr[date.month - 1],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? PlayerColors.accent
                                  : AppColors.primary,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? PlayerColors.accent
                                  : AppColors.primary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_typeEmoji(type),
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? PlayerColors.textPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12,
                                  color: isDark
                                      ? PlayerColors.textSecondary
                                      : AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? PlayerColors.textSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerSchedulePage()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Manage Schedule →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dark Mode Toggle ──────────────────────────────────────────────────────────

class _DarkModeToggleRow extends StatelessWidget {
  const _DarkModeToggleRow();

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Dark Mode',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? PlayerColors.textSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => getIt<PlayerThemeService>().toggle(),
            activeThumbColor: PlayerColors.textOnAccent,
            activeTrackColor: PlayerColors.accent,
          ),
        ],
      ),
    );
  }
}

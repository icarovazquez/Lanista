import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../messaging/presentation/pages/conversation_detail_page.dart';
import '../../../../../features/player/video/data/video_models.dart';
import '../../../../../features/player/schedule/data/schedule_models.dart';

/// Coach-facing player detail page.
/// Shown when a coach taps a player card in the search results.
class CoachPlayerDetailPage extends StatefulWidget {
  final String playerId;

  const CoachPlayerDetailPage({super.key, required this.playerId});

  @override
  State<CoachPlayerDetailPage> createState() => _CoachPlayerDetailPageState();
}

class _CoachPlayerDetailPageState extends State<CoachPlayerDetailPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isContacting = false;
  Map<String, dynamic>? _player;
  List<PlayerVideo> _videos = [];
  List<PlayerVideo> _gameFilms = [];
  List<PlayerEvent> _schedule = [];
  List<Map<String, dynamic>> _leagueEvents = [];
  String? _playerLeagueName;
  String? _playerClubName;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    try {
      final data = await _supabase.from('players').select('''
        id, user_id, grade, graduation_year, dominant_foot, height_cm, weight_kg,
        gpa, sat_score, act_score, bio, target_division, speed_rating,
        clubs(name), leagues(name),
        player_positions(is_primary, positions(abbreviation, name)),
        users!inner(first_name, last_name, id)
      ''').eq('id', widget.playerId).single();

      if (mounted) {
        setState(() {
          _player = Map<String, dynamic>.from(data);
          _isLoading = false;
        });
      }
      await Future.wait([_loadVideos(), _loadSchedule(), _recordProfileView(widget.playerId)]);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load player: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadVideos() async {
    try {
      final rows = await _supabase
          .from('player_videos')
          .select('*')
          .eq('player_id', widget.playerId)
          .order('is_primary', ascending: false)
          .order('uploaded_at', ascending: false);
      if (mounted) {
        final all =
            (rows as List).map((r) => PlayerVideo.fromMap(r)).toList();
        setState(() {
          _videos = all
              .where((v) => v.videoType == 'highlight')
              .toList();
          _gameFilms = all
              .where((v) => v.videoType == 'game_film')
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSchedule() async {
    try {
      final today    = DateTime.now().toIso8601String().substring(0, 10);
      final in90days = DateTime.now().add(const Duration(days: 90))
          .toIso8601String().substring(0, 10);

      final results = await Future.wait([
        // Manually-added player events
        _supabase
            .from('player_schedule')
            .select('*')
            .eq('player_id', widget.playerId)
            .gte('event_date', today)
            .order('event_date', ascending: true)
            .limit(5),

        // Club affiliation → upcoming league events
        _supabase
            .from('player_club_affiliations')
            .select('league_clubs(league, club_name)')
            .eq('player_id', widget.playerId)
            .eq('is_active', true)
            .limit(1),
      ]);

      final manualRows   = results[0] as List;
      final affiliations = results[1] as List;

      List<Map<String, dynamic>> leagueEvents = [];
      String? leagueName;
      String? clubName;

      if (affiliations.isNotEmpty) {
        final club   = (affiliations.first as Map)['league_clubs'] as Map?;
        final league = club?['league'] as String?;
        clubName     = club?['club_name'] as String?;
        leagueName   = _leagueLabel(league);

        if (league != null) {
          final evRows = await _supabase
              .from('league_events')
              .select('id, league, event_name, event_type, start_date, end_date, city, state, age_groups')
              .eq('league', league)
              .gte('start_date', today)
              .lte('start_date', in90days)
              .order('start_date')
              .limit(5);
          leagueEvents = List<Map<String, dynamic>>.from(evRows as List);
        }
      }

      if (mounted) {
        setState(() {
          _schedule         = manualRows.map((r) => PlayerEvent.fromMap(r as Map<String,dynamic>)).toList();
          _leagueEvents     = leagueEvents;
          _playerLeagueName = leagueName;
          _playerClubName   = clubName;
        });
      }
    } catch (_) {}
  }

  Future<void> _recordProfileView(String playerId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final coachRow = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (coachRow == null) return;
      await _supabase.from('profile_views').insert({
        'coach_id': coachRow['id'],
        'player_id': playerId,
      });
    } catch (_) {
      // Fire-and-forget — never block the UI for view tracking
    }
  }

  String _leagueLabel(String? league) {
    switch (league) {
      case 'mlsnext': return 'MLS Next';
      case 'ecnl':    return 'ECNL';
      case 'ecrl':    return 'ECRL';
      case 'ga':      return 'Girls Academy';
      case 'npl':     return 'NPL';
      default:        return league?.toUpperCase() ?? '';
    }
  }

  Color _leagueColor(String? league) {
    switch (league) {
      case 'mlsnext': return const Color(0xFF003087);
      case 'ecnl':    return const Color(0xFF006B3C);
      case 'ecrl':    return const Color(0xFF8B0000);
      default:        return AppColors.coachColor;
    }
  }

  Future<void> _contactPlayer() async {
    if (_player == null) return;
    final coachUserId = _supabase.auth.currentUser?.id;
    if (coachUserId == null) return;

    setState(() => _isContacting = true);
    try {
      // Get coach record
      final coachData = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', coachUserId)
          .maybeSingle();
      if (coachData == null) return;
      final coachId = coachData['id'] as String;

      final playerUserId =
          (_player!['users'] as Map<String, dynamic>?)?['id'] as String? ??
              _player!['user_id'] as String;
      final playerId = _player!['id'] as String;

      // Check or create conversation
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('player_id', playerId)
          .eq('coach_id', coachId)
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
      } else {
        final created = await _supabase
            .from('conversations')
            .insert({
              'player_id': playerId,
              'coach_id': coachId,
              'contact_window_valid': true,
              'initiated_by': 'coach',
            })
            .select('id')
            .single();
        conversationId = created['id'] as String;
      }

      if (mounted) {
        final playerUser =
            (_player!['users'] as Map<String, dynamic>?) ?? {};
        final playerName =
            '${playerUser['first_name'] ?? ''} ${playerUser['last_name'] ?? ''}'
                .trim();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailPage(
              conversationId: conversationId,
              otherUserId: playerUserId,
              otherUserName: playerName,
              otherUserRole: 'player',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isContacting = false);
    }
  }

  String _gradeLabel(dynamic grade) {
    if (grade == null) return '—';
    final g = int.tryParse(grade.toString());
    if (g == null) return '—';
    if (g == 9) return '9th Grade (Freshman)';
    if (g == 10) return '10th Grade (Sophomore)';
    if (g == 11) return '11th Grade (Junior)';
    if (g == 12) return '12th Grade (Senior)';
    return 'Grade $g';
  }

  String _footLabel(String? foot) {
    switch (foot) {
      case 'right':
        return 'Right';
      case 'left':
        return 'Left';
      case 'both':
        return 'Both (Ambidextrous)';
      default:
        return '—';
    }
  }

  /// Returns e.g. "180 cm (5'11")" or "—" if null.
  static String _cmToHeight(int? cm) {
    if (cm == null) return '—';
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$cm cm ($feet'$inches\")";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.coachColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_player == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.coachColor,
          foregroundColor: Colors.white,
          title: const Text('Player Profile'),
        ),
        body: const Center(child: Text('Player not found.')),
      );
    }

    final userMap =
        (_player!['users'] as Map<String, dynamic>?) ?? {};
    final firstName = userMap['first_name'] as String? ?? '';
    final lastName = userMap['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Positions
    final pps = (_player!['player_positions'] as List?) ?? [];
    pps.sort((a, b) {
      final aP = (a['is_primary'] as bool?) == true ? 0 : 1;
      final bP = (b['is_primary'] as bool?) == true ? 0 : 1;
      return aP.compareTo(bP);
    });
    String? primaryPos;
    if (pps.isNotEmpty) {
      final posMap = pps.first['positions'] as Map<String, dynamic>?;
      primaryPos = posMap?['name'] as String?;
    }
    String? secondaryPos;
    if (pps.length > 1) {
      final posMap = pps[1]['positions'] as Map<String, dynamic>?;
      secondaryPos = posMap?['name'] as String?;
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.coachColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.coachColor,
                      Color(0xFF1E88E5),
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
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName.isEmpty ? 'Player' : fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (primaryPos != null)
                                    Text(
                                      primaryPos,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
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

          // ── Profile Sections ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // About Me
                  if ((_player!['bio'] as String?)?.isNotEmpty == true) ...[
                    _SectionHeader(title: 'About', emoji: '💬'),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      child: Text(
                        _player!['bio'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Soccer
                  _SectionHeader(title: 'Soccer', emoji: '⚽'),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Primary Position',
                          value: primaryPos ?? '—',
                        ),
                        if (secondaryPos != null)
                          _InfoRow(
                            label: 'Secondary Position',
                            value: secondaryPos,
                          ),
                        _InfoRow(
                          label: 'Dominant Foot',
                          value: _footLabel(
                              _player!['dominant_foot'] as String?),
                        ),
                        _InfoRow(
                          label: 'Height',
                          value: _cmToHeight(_player!['height_cm'] as int?),
                        ),
                        _InfoRow(
                          label: 'Current Club',
                          value: (_player!['clubs']
                                  as Map<String, dynamic>?)?['name'] ??
                              '—',
                          isLast: _player!['leagues'] == null,
                        ),
                        if (_player!['leagues'] != null)
                          _InfoRow(
                            label: 'League',
                            value: (_player!['leagues']
                                    as Map<String, dynamic>)['name'] ??
                                '—',
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Academics
                  _SectionHeader(title: 'Academics', emoji: '📚'),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Grade',
                          value: _gradeLabel(_player!['grade']),
                        ),
                        _InfoRow(
                          label: 'Graduation Year',
                          value: _player!['graduation_year']?.toString() ?? '—',
                        ),
                        _InfoRow(
                          label: 'GPA (Unweighted)',
                          value: (_player!['gpa'] as num?) != null
                              ? (_player!['gpa'] as num)
                                  .toStringAsFixed(2)
                              : '—',
                        ),
                        _InfoRow(
                          label: 'SAT Score',
                          value: _player!['sat_score']?.toString() ?? '—',
                        ),
                        _InfoRow(
                          label: 'ACT Score',
                          value: _player!['act_score']?.toString() ?? '—',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Target Division
                  if (_player!['target_division'] != null) ...[
                    _SectionHeader(title: 'Target Division', emoji: '🎯'),
                    const SizedBox(height: 12),
                    _ProfileCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DivisionChip(
                            label: _player!['target_division'] as String,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Highlights
                  _SectionHeader(title: 'Highlights', emoji: '🎬'),
                  const SizedBox(height: 12),
                  if (_videos.isEmpty)
                    _ProfileCard(
                      child: Row(
                        children: [
                          const Icon(Icons.videocam_off_outlined,
                              size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          const Text(
                            'No highlights added yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _videos
                          .map<Widget>((v) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CoachVideoCard(video: v),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 24),

                  // Game Film
                  _SectionHeader(title: 'Game Film', emoji: '🎥'),
                  const SizedBox(height: 12),
                  if (_gameFilms.isEmpty)
                    _ProfileCard(
                      child: Row(
                        children: [
                          const Icon(Icons.videocam_off_outlined,
                              size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          const Text(
                            'No game film uploaded yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _gameFilms
                          .map<Widget>((v) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CoachVideoCard(video: v),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 24),

                  // Schedule
                  _SectionHeader(title: 'Upcoming Schedule', emoji: '📅'),
                  const SizedBox(height: 12),

                  if (_leagueEvents.isEmpty && _schedule.isEmpty)
                    _ProfileCard(
                      child: Row(
                        children: const [
                          Icon(Icons.event_busy_outlined,
                              size: 16, color: AppColors.textTertiary),
                          SizedBox(width: 8),
                          Text(
                            'No upcoming events added yet',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // League events — automatically derived from club affiliation
                    if (_leagueEvents.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              _playerLeagueName != null
                                  ? '$_playerLeagueName Events'
                                  : 'League Events',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary),
                            ),
                            if (_playerClubName != null) ...[
                              const Text(' · ',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              Flexible(
                                child: Text(
                                  _playerClubName!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ..._leagueEvents.map<Widget>((ev) {
                        final league = ev['league'] as String?;
                        final color  = _leagueColor(league);
                        final start  = DateTime.parse(ev['start_date'] as String);
                        final end    = DateTime.parse(ev['end_date'] as String);
                        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                                        'Jul','Aug','Sep','Oct','Nov','Dec'];
                        final dateStr = start.month == end.month
                            ? '${months[start.month-1]} ${start.day}–${end.day}'
                            : '${months[start.month-1]} ${start.day} – ${months[end.month-1]} ${end.day}';
                        final daysLeft = start.difference(DateTime.now()).inDays;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ['Jan','Feb','Mar','Apr','May','Jun',
                                       'Jul','Aug','Sep','Oct','Nov','Dec']
                                          [start.month-1],
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ev['event_name'] as String? ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${ev['city']}, ${ev['state']}  ·  $dateStr',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    daysLeft <= 0
                                        ? 'Now'
                                        : 'in $daysLeft d',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    // Manually-added events
                    if (_schedule.isNotEmpty) ...[
                      if (_leagueEvents.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Added by Player',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                      ..._schedule.map<Widget>((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CoachEventCard(event: e),
                          )),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // Contact button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isContacting ? null : _contactPlayer,
                      icon: _isContacting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(
                          _isContacting ? 'Opening…' : 'Contact Player'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coachColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
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

class _DivisionChip extends StatelessWidget {
  final String label;
  const _DivisionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.coachColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coachColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.coachColor,
        ),
      ),
    );
  }
}

class _CoachVideoCard extends StatelessWidget {
  final PlayerVideo video;
  const _CoachVideoCard({required this.video});

  Future<void> _open(BuildContext context) async {
    // Prefer Mux stream URL, fall back to external URL
    final url = video.streamUrl ?? video.externalUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video link.')),
      );
    }
  }

  void _showAnalysis(BuildContext context) {
    final result = video.analysisResult;
    if (result == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CoachAnalysisSheet(
        title: video.displayTitle,
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnalysis = video.analysisStatus == 'complete' && video.analysisResult != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: _buildThumbnail(),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (video.isPrimary) ...[
                            const Text('⭐', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                          ],
                          _SourceBadge(label: video.sourceLabel),
                          if (hasAnalysis) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('✨ AI',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        video.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Watch button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: () => _open(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.coachColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.coachColor.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: const Text('Watch',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (hasAnalysis)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAnalysis(context),
                  icon: const Text('✨', style: TextStyle(fontSize: 13)),
                  label: const Text('View AI Scout Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: video.thumbnailUrl!,
        width: 90,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 72,
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            color: AppColors.coachColor, size: 28),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String label;
  const _SourceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.coachColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.coachColor,
        ),
      ),
    );
  }
}

// ── AI Analysis Sheet (Coach View) ────────────────────────────────────────────

class _CoachAnalysisSheet extends StatelessWidget {
  final String title;
  final Map<String, dynamic> result;

  const _CoachAnalysisSheet({required this.title, required this.result});

  Widget _chip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = result['summary'] as String? ?? '';
    final dominantFoot = result['dominant_foot'] as String? ?? '—';
    final position = result['primary_position'] as String? ?? '—';
    final style = result['playing_style'] as String? ?? '';
    final skills = (result['skills_detected'] as List?)?.cast<String>() ?? [];
    final strengths = (result['strengths'] as List?)?.cast<String>() ?? [];
    final improvements = (result['areas_for_improvement'] as List?)?.cast<String>() ?? [];
    final projection = result['college_level_projection'] as String? ?? '—';
    final rating = result['scout_rating'];
    final foot = dominantFoot == 'unknown' ? '—'
        : dominantFoot.isEmpty ? '—'
        : dominantFoot[0].toUpperCase() + dominantFoot.substring(1);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('AI Scout Report',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ),
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$rating / 10',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            // Quick stats
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Position', value: position)),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(label: 'Foot', value: foot)),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(label: 'Projection', value: projection)),
              ],
            ),
            const SizedBox(height: 16),

            if (summary.isNotEmpty) ...[
              const Text('Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(summary, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
            ],

            if (style.isNotEmpty) ...[
              const Text('Playing Style', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(style, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
            ],

            if (skills.isNotEmpty) ...[
              const Text('Skills Detected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(children: skills.map(_chip).toList()),
              const SizedBox(height: 16),
            ],

            if (strengths.isNotEmpty) ...[
              const Text('Strengths', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              ...strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('✅ ', style: TextStyle(fontSize: 13)),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
                ]),
              )),
              const SizedBox(height: 16),
            ],

            if (improvements.isNotEmpty) ...[
              const Text('Areas to Develop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              ...improvements.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📈 ', style: TextStyle(fontSize: 13)),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
                ]),
              )),
            ],

            const SizedBox(height: 16),
            const Text(
              'Powered by AI · For scouting purposes only',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Coach Event Card ───────────────────────────────────────────────────────────

class _CoachEventCard extends StatelessWidget {
  final PlayerEvent event;
  const _CoachEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isShowcase = event.isShowcase;
    final color = isShowcase ? AppColors.mentorColor : AppColors.coachColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date block
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _monthAbbr(event.eventDate.month),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '${event.eventDate.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '${event.eventDate.year}',
                    style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${event.typeEmoji} ${event.typeLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      if (event.competition != null) ...[
                        const Text('  ·  ',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Flexible(
                          child: Text(
                            event.competition!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (event.displayTime != null ||
                      event.location != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (event.displayTime != null) ...[
                          const Icon(Icons.schedule_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            event.displayTime!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (event.location != null)
                            const Text('  ·  ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                        ],
                        if (event.location != null) ...[
                          GestureDetector(
                            onTap: () async {
                              final encoded =
                                  Uri.encodeComponent(event.location!);
                              final appleUri = Uri.parse(
                                  'https://maps.apple.com/?q=$encoded');
                              final googleUri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$encoded');
                              if (await canLaunchUrl(appleUri)) {
                                await launchUrl(appleUri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                await launchUrl(googleUri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.coachColor),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    event.location!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.coachColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
  }

  String _monthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/schedule_models.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import 'player_schedule_add_page.dart';

class PlayerSchedulePage extends StatefulWidget {
  const PlayerSchedulePage({super.key});

  @override
  State<PlayerSchedulePage> createState() => _PlayerSchedulePageState();
}

class _PlayerSchedulePageState extends State<PlayerSchedulePage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _playerId;
  List<PlayerEvent> _myEvents = [];
  List<Map<String, dynamic>> _leagueEvents = [];
  String? _clubName;
  String? _leagueName;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final playerRow = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerRow == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      _playerId = playerRow['id'] as String;

      final now = DateTime.now();
      final todayStr = now.toIso8601String().substring(0, 10);
      final in90Days = now.add(const Duration(days: 90))
          .toIso8601String().substring(0, 10);

      // Load manually-added events and club affiliation in parallel
      final results = await Future.wait([
        _supabase
            .from('player_schedule')
            .select('*')
            .eq('player_id', _playerId!)
            .gte('event_date', todayStr)
            .order('event_date', ascending: true),

        _supabase
            .from('player_club_affiliations')
            .select('club_id, age_group, league_clubs(league, club_name)')
            .eq('player_id', _playerId!)
            .eq('is_active', true)
            .limit(1),
      ]);

      final manualEvents = results[0] as List;
      final affiliations = results[1] as List;

      List<Map<String, dynamic>> leagueEvents = [];
      if (affiliations.isNotEmpty) {
        final affil = affiliations.first as Map;
        final club  = affil['league_clubs'] as Map?;
        final league = club?['league'] as String?;
        _clubName  = club?['club_name'] as String?;
        _leagueName = _leagueLabel(league);

        if (league != null) {
          // Fetch upcoming events for the player's league
          final evRows = await _supabase
              .from('league_events')
              .select('id, league, event_name, event_type, start_date, end_date, city, state, age_groups, venue_name')
              .eq('league', league)
              .gte('start_date', todayStr)
              .lte('start_date', in90Days)
              .order('start_date');
          leagueEvents = List<Map<String, dynamic>>.from(evRows as List);
        }
      }

      if (mounted) {
        setState(() {
          _myEvents     = manualEvents.map((r) => PlayerEvent.fromMap(r as Map<String,dynamic>)).toList();
          _leagueEvents = leagueEvents;
          _loading      = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load schedule: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
      default:        return AppColors.primary;
    }
  }

  String _formatDateRange(String start, String end) {
    final s = DateTime.parse(start);
    final e = DateTime.parse(end);
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    if (s.month == e.month) return '${m[s.month-1]} ${s.day}–${e.day}, ${s.year}';
    return '${m[s.month-1]} ${s.day} – ${m[e.month-1]} ${e.day}, ${s.year}';
  }

  String _eventTypeIcon(String? type) {
    switch (type) {
      case 'showcase':     return '🏟️';
      case 'playoff':      return '🥊';
      case 'championship': return '🏆';
      case 'id_camp':      return '⚽';
      default:             return '📅';
    }
  }

  Future<void> _deleteEvent(PlayerEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Event?'),
        content: Text('Remove "${event.title}" from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('player_schedule').delete().eq('id', event.id);
      await _loadEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final hasAnything = _myEvents.isNotEmpty || _leagueEvents.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? PlayerColors.background : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Schedule',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PlayerScheduleAddPage(playerId: _playerId ?? ''),
          ));
          _loadEvents();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: isDark ? PlayerColors.accent : AppColors.primary))
          : !hasAnything
              ? _EmptyState(
                  onAdd: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          PlayerScheduleAddPage(playerId: _playerId ?? ''),
                    ));
                    _loadEvents();
                  },
                  isDark: isDark,
                )
              : RefreshIndicator(
                  color: isDark ? PlayerColors.accent : AppColors.primary,
                  onRefresh: _loadEvents,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [

                      // ── Upcoming League Events ─────────────────────────
                      if (_leagueEvents.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_leagueName Events',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  if (_clubName != null)
                                    Text(
                                      _clubName!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isDark ? PlayerColors.accent : AppColors.primary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_leagueEvents.length} upcoming',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? PlayerColors.accent : AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        ..._leagueEvents.map((ev) {
                          final league = ev['league'] as String?;
                          final color  = _leagueColor(league);
                          final ages   = (ev['age_groups'] as List?)?.join(' · ') ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDark ? PlayerColors.surface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date block
                                  Container(
                                    width: 52,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _eventTypeIcon(ev['event_type'] as String?),
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateTime.parse(ev['start_date'] as String).day.toString(),
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: color,
                                              height: 1.1),
                                        ),
                                        Text(
                                          ['Jan','Feb','Mar','Apr','May','Jun',
                                           'Jul','Aug','Sep','Oct','Nov','Dec']
                                              [DateTime.parse(ev['start_date'] as String).month - 1],
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Event info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                _leagueLabel(league),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ev['event_name'] as String? ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 12,
                                                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${ev['city']}, ${ev['state']}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDateRange(
                                              ev['start_date'] as String,
                                              ev['end_date'] as String),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                                        ),
                                        if (ages.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(ages,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        if (_myEvents.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                        ],
                      ],

                      // ── My Custom Events ───────────────────────────────
                      if (_myEvents.isNotEmpty) ...[
                        const Text('My Added Events',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ..._myEvents.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EventCard(
                            event: event,
                            onDelete: () => _deleteEvent(event),
                            isDark: isDark,
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final bool isDark;
  const _EmptyState({required this.onAdd, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.gradientStart.withValues(alpha: 0.15) : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No upcoming games',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your upcoming games and showcases so coaches know when and where to see you play live.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Maps helper ────────────────────────────────────────────────────────────────

Future<void> _openMaps(String location) async {
  final encoded = Uri.encodeComponent(location);
  // Try Apple Maps first (iOS), fall back to Google Maps
  final appleUri = Uri.parse('https://maps.apple.com/?q=$encoded');
  final googleUri =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  if (await canLaunchUrl(appleUri)) {
    await launchUrl(appleUri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(googleUri, mode: LaunchMode.externalApplication);
  }
}

// ── Event Card ─────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final PlayerEvent event;
  final VoidCallback onDelete;
  final bool isDark;

  const _EventCard({required this.event, required this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isShowcase = event.isShowcase;
    final color =
        isShowcase ? AppColors.mentorColor : (isDark ? PlayerColors.accent : AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date column
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    _monthAbbr(event.eventDate.month),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '${event.eventDate.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '${event.eventDate.year}',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(
                          label: event.typeLabel,
                          emoji: event.typeEmoji,
                          color: color),
                      if (event.competition != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            event.competition!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                    ),
                  ),
                  if (event.displayTime != null ||
                      event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (event.displayTime != null) ...[
                          Icon(Icons.schedule_outlined,
                              size: 13,
                              color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            event.displayTime!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                            ),
                          ),
                          if (event.location != null)
                            Text('  ·  ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary)),
                        ],
                        if (event.location != null) ...[
                          GestureDetector(
                            onTap: () => _openMaps(event.location!),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13,
                                    color: isDark ? PlayerColors.accent : AppColors.primary),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    event.location!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? PlayerColors.accent : AppColors.primary,
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
                  if (event.notes != null &&
                      event.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.close,
                  size: 18, color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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

class _TypeBadge extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const _TypeBadge(
      {required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

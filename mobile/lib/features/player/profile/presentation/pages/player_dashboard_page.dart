import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_data.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../messaging/presentation/pages/conversations_page.dart';
import '../../../roadmap/presentation/pages/player_roadmap_page.dart';
import '../../../matches/presentation/pages/player_matches_page.dart';
import '../../../video/presentation/pages/player_game_film_page.dart';
import '../../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../openings/presentation/pages/player_openings_page.dart';

class PlayerDashboardPage extends StatefulWidget {
  const PlayerDashboardPage({super.key});

  @override
  State<PlayerDashboardPage> createState() => _PlayerDashboardPageState();
}

class _PlayerDashboardPageState extends State<PlayerDashboardPage> {
  int _currentIndex = 0; // 0=Home 1=Roadmap 2=Openings 3=Messages
  String _firstName = '';
  String _playerId = '';
  int _unreadCount = 0;
  RealtimeChannel? _msgChannel;

  @override
  void initState() {
    super.initState();
    // C-lite: lock player app to dark mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<PlayerThemeService>().setMode(PlayerThemeMode.dark);
    });
    _loadUser();
    _loadUnread();
    _subscribeUnread();
    _registerFcmToken();
  }

  Future<void> _registerFcmToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id':  userId,
        'token':    token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, onConflict: 'user_id,token');
    } catch (_) {}
  }

  @override
  void dispose() {
    _msgChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('users')
          .select('first_name')
          .eq('id', userId)
          .single();
      final playerRow = await Supabase.instance.client
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _firstName = data['first_name'] as String? ?? '';
          _playerId = playerRow?['id'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUnread() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final rows = await Supabase.instance.client
          .from('messages')
          .select('id')
          .neq('sender_id', userId)
          .isFilter('read_at', null);
      if (mounted) setState(() => _unreadCount = (rows as List).length);
    } catch (_) {}
  }

  void _subscribeUnread() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _msgChannel = Supabase.instance.client
        .channel('dashboard_unread:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadUnread(),
        )
        .subscribe();
  }

  void _openFilmPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlayerGameFilmPage()),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: PlayerColors.textTertiary.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'View Profile',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/player/profile');
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.visibility_outlined,
                  label: 'Who Viewed Me',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/player/profile-views');
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.videocam_rounded,
                  label: 'My Film',
                  onTap: () {
                    Navigator.pop(ctx);
                    _openFilmPage();
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/player/settings');
                  },
                ),
                const Divider(color: Color(0xFF2A2A2A), height: 8),
                _ProfileMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  destructive: true,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) context.go('/');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
    return ListenableBuilder(
      listenable: themeService,
      builder: (ctx, _) {
        return Theme(
          data: PlayerThemeData.dark,
          child: PlayerThemeScope(
            service: themeService,
            child: _buildScaffold(ctx),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final hasUnread = _unreadCount > 0;
    final badgeLabel = _unreadCount > 9 ? '9+' : '$_unreadCount';

    return Scaffold(
      backgroundColor: PlayerColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _GenZHomeTab(
            firstName: _firstName,
            playerId: _playerId,
          ),
          const PlayerRoadmapPage(),
          const PlayerOpeningsPage(),
          const ConversationsPage(),
        ],
      ),
      bottomNavigationBar: _PlayerBottomBar(
        currentIndex: _currentIndex,
        hasUnread: hasUnread,
        badgeLabel: badgeLabel,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 3) setState(() => _unreadCount = 0);
        },
        onProfile: _showProfileMenu,
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────────

class _PlayerBottomBar extends StatelessWidget {
  final int currentIndex;
  final bool hasUnread;
  final String badgeLabel;
  final ValueChanged<int> onTap;
  final VoidCallback onProfile;

  const _PlayerBottomBar({
    required this.currentIndex,
    required this.hasUnread,
    required this.badgeLabel,
    required this.onTap,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: PlayerColors.surface,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _NavTile(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavTile(
              icon: Icons.route_outlined,
              activeIcon: Icons.route,
              label: 'Roadmap',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavTile(
              icon: Icons.sports_soccer_outlined,
              activeIcon: Icons.sports_soccer_rounded,
              label: 'Openings',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavTile(
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Messages',
              selected: currentIndex == 3,
              badge: hasUnread ? badgeLabel : null,
              onTap: () => onTap(3),
            ),
            _NavTile(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              selected: false,
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? PlayerColors.accent : PlayerColors.textTertiary;
    Widget iconWidget = Icon(selected ? activeIcon : icon, color: color, size: 22);
    if (badge != null) {
      iconWidget = Badge(
        label: Text(
          badge!,
          style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w800,
            color: PlayerColors.textOnAccent,
          ),
        ),
        backgroundColor: Colors.red,
        child: iconWidget,
      );
    }
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Menu Item ──────────────────────────────────────────────────────────

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : PlayerColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      onTap: onTap,
      minLeadingWidth: 20,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}

// ── Gen Z Home Tab ─────────────────────────────────────────────────────────────

enum _ActivityType { match, event, film }

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final String? timestamp;

  const _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.timestamp,
  });
}

class _GenZHomeTab extends StatefulWidget {
  final String firstName;
  final String playerId;

  const _GenZHomeTab({required this.firstName, required this.playerId});

  @override
  State<_GenZHomeTab> createState() => _GenZHomeTabState();
}

class _GenZHomeTabState extends State<_GenZHomeTab> {
  int _matchCount = 0;
  int _filmCount = 0;
  int _profileViewCount = 0;
  bool _hasBio = false;
  bool _hasClub = false;
  List<_NudgeItem> _nudges = [];
  List<Map<String, dynamic>> _topMatches = [];
  List<_ActivityItem> _activityItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.playerId.isNotEmpty) _loadData();
  }

  @override
  void didUpdateWidget(_GenZHomeTab old) {
    super.didUpdateWidget(old);
    if (old.playerId != widget.playerId && widget.playerId.isNotEmpty) {
      _loadData();
    }
  }

  int get _exposureScore {
    if (_loading) return 0;
    final completeness = (_hasBio ? 10 : 0) + (_hasClub ? 10 : 0);
    final filmPts = (_filmCount * 10).clamp(0, 20);
    final matchPts = (_matchCount * 3).clamp(0, 30);
    final viewPts = (_profileViewCount * 3).clamp(0, 30);
    return (completeness + filmPts + matchPts + viewPts).clamp(0, 100);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // Each query is independently fault-tolerant so one failure won't blank the screen.
    Map<String, dynamic>? profile;
    List<Map<String, dynamic>> topMatches = [];
    int filmCount = 0;
    int profileViewCount = 0;
    int matchCount = 0;
    Map<String, dynamic>? nextEvent;

    try {
      profile = await Supabase.instance.client
          .from('players')
          .select('bio, club_name, league, target_division, target_schools, '
              'technical_skills, gpa, sat_score, highlight_url, height_cm')
          .eq('id', widget.playerId)
          .maybeSingle();
    } catch (_) {}

    try {
      final data = await Supabase.instance.client
          .from('player_coach_matches')
          .select('total_score, last_computed_at, coaches!inner(id, school_name, division)')
          .eq('player_id', widget.playerId)
          .order('total_score', ascending: false)
          .limit(5);
      topMatches = List<Map<String, dynamic>>.from(data as List);
    } catch (_) {}

    try {
      final films = await Supabase.instance.client
          .from('player_videos')
          .select('id')
          .eq('player_id', widget.playerId)
          .eq('video_type', 'game_film');
      filmCount = (films as List).length;
    } catch (_) {}

    try {
      final since30 = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final views = await Supabase.instance.client
          .from('profile_views')
          .select('coach_id')
          .eq('player_id', widget.playerId)
          .gte('viewed_at', since30);
      profileViewCount = (views as List).map((r) => r['coach_id']).toSet().length;
    } catch (_) {}

    try {
      final all = await Supabase.instance.client
          .from('player_coach_matches')
          .select('id')
          .eq('player_id', widget.playerId);
      matchCount = (all as List).length;
    } catch (_) {}

    try {
      final nowDate = DateTime.now().toIso8601String().substring(0, 10);
      final events = await Supabase.instance.client
          .from('league_events')
          .select('event_name, start_date, city, state')
          .gte('start_date', nowDate)
          .order('start_date', ascending: true)
          .limit(1);
      if (events.isNotEmpty) {
        nextEvent = events[0];
      }
    } catch (_) {}

    // Build activity feed
    final items = <_ActivityItem>[];

    for (final m in topMatches.take(3)) {
      final coach = m['coaches'] as Map<String, dynamic>?;
      if (coach == null) continue;
      final score = (m['total_score'] as num? ?? 0).round();
      items.add(_ActivityItem(
        type: _ActivityType.match,
        title: 'New match',
        subtitle: '${coach['school_name']} at $score%',
        timestamp: m['last_computed_at'] as String?,
      ));
    }

    if (nextEvent != null) {
      final startDate = DateTime.parse(nextEvent['start_date'] as String);
      final daysUntil = startDate.difference(DateTime.now()).inDays;
      items.add(_ActivityItem(
        type: _ActivityType.event,
        title: nextEvent['event_name'] as String,
        subtitle: 'in $daysUntil days — ${nextEvent['city']}, ${nextEvent['state']}',
      ));
    }

    if (filmCount < 2) {
      items.add(_ActivityItem(
        type: _ActivityType.film,
        title: filmCount == 0 ? 'No game film yet' : 'Add more game film',
        subtitle: 'Coaches with film are 3× more likely to match',
      ));
    }

    if (mounted) {
      final nudges = <_NudgeItem>[];
      if ((profile?['height_cm']) == null) {
        nudges.add(const _NudgeItem(icon: Icons.height_rounded, title: 'Add your height', benefit: 'Coaches filter by position size', startPage: 4));
      }
      if ((profile?['club_name'] as String?)?.isEmpty ?? true) {
        nudges.add(const _NudgeItem(icon: Icons.sports_soccer_rounded, title: 'Add your club', benefit: 'MLS Next & ECNL → priority with D1 coaches', startPage: 5));
      }
      if ((profile?['target_division']) == null) {
        nudges.add(const _NudgeItem(icon: Icons.school_outlined, title: 'Set your target level', benefit: 'Get matched with the right programs', startPage: 6));
      }
      if ((profile?['target_schools'] as List?)?.isEmpty ?? true) {
        nudges.add(const _NudgeItem(icon: Icons.bookmark_outline_rounded, title: 'Add target schools', benefit: 'Those coaches see you first', startPage: 7));
      }
      if ((profile?['technical_skills']) == null) {
        nudges.add(const _NudgeItem(icon: Icons.auto_graph_rounded, title: 'Rate your skills', benefit: 'Personalizes your recruiting roadmap', startPage: 8));
      }
      if ((profile?['gpa']) == null && (profile?['sat_score']) == null) {
        nudges.add(const _NudgeItem(icon: Icons.menu_book_outlined, title: 'Add academics', benefit: 'D3 & NAIA weigh grades heavily', startPage: 9));
      }
      if ((profile?['highlight_url'] as String?)?.isEmpty ?? true) {
        nudges.add(const _NudgeItem(icon: Icons.videocam_outlined, title: 'Add a highlight reel', benefit: 'Film → 3× more coach contact', startPage: 10));
      }

      setState(() {
        _hasBio = (profile?['bio'] as String?)?.isNotEmpty ?? false;
        _hasClub = (profile?['club_name'] as String?)?.isNotEmpty ?? false;
        _nudges = nudges;
        _topMatches = topMatches;
        _matchCount = matchCount;
        _filmCount = filmCount;
        _profileViewCount = profileViewCount;
        _activityItems = items;
        _loading = false;
      });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final name = widget.firstName.isNotEmpty ? widget.firstName : 'Player';

    return CustomScrollView(
      slivers: [
        // ── Greeting header ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, safePadding.top + 14, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: TextStyle(
                          fontSize: 12,
                          color: PlayerColors.textTertiary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$name 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                NotificationBell(iconColor: PlayerColors.textSecondary),
              ],
            ),
          ),
        ),

        // ── Exposure ring ──────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _ExposureHeroCard(
          score: _exposureScore,
          firstName: name,
          loading: _loading,
          viewCount: _profileViewCount,
          onViewsTap: () => context.push('/player/profile-views'),
        )),

        // ── Profile nudges ─────────────────────────────────────────────────────
        if (_nudges.isNotEmpty)
          SliverToBoxAdapter(
            child: _ProfileNudges(
              nudges: _nudges,
              onTap: (page) async {
                await context.push('/player/profile/setup',
                    extra: {'startPage': page});
                if (mounted) _loadData();
              },
            ),
          ),

        // ── Coach cards ────────────────────────────────────────────────────────
        if (_topMatches.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: '👀 Coaches watching you',
              action: 'See all →',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerMatchesPage()),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _CoachCardRow(matches: _topMatches)),
        ],

        // ── Activity feed ──────────────────────────────────────────────────────
        if (_activityItems.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(title: 'Activity'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActivityCard(
                    item: _activityItems[i],
                    onTap: () {
                      if (_activityItems[i].type == _ActivityType.match) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlayerMatchesPage()),
                        );
                      } else if (_activityItems[i].type == _ActivityType.film) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlayerGameFilmPage()),
                        );
                      }
                      // events: no detail page yet, tap does nothing
                    },
                  ),
                ),
                childCount: _activityItems.length,
              ),
            ),
          ),
        ] else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 140),
            sliver: const SliverToBoxAdapter(child: SizedBox()),
          ),
      ],
    );
  }
}

// ── Profile nudges ─────────────────────────────────────────────────────────────

class _NudgeItem {
  final IconData icon;
  final String title;
  final String benefit;
  final int startPage;

  const _NudgeItem({
    required this.icon,
    required this.title,
    required this.benefit,
    required this.startPage,
  });
}

class _ProfileNudges extends StatelessWidget {
  final List<_NudgeItem> nudges;
  final void Function(int startPage) onTap;

  const _ProfileNudges({required this.nudges, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: PlayerColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Complete your profile',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PlayerColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                '${nudges.length} left',
                style: TextStyle(fontSize: 11, color: PlayerColors.textTertiary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nudges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _NudgeCard(item: nudges[i], onTap: onTap),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final _NudgeItem item;
  final void Function(int) onTap;

  const _NudgeCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(item.startPage),
      child: Container(
        width: 180,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border.all(color: PlayerColors.accent.withValues(alpha: 0.22), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(item.icon, size: 15, color: PlayerColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              item.benefit,
              style: TextStyle(
                fontSize: 11, color: PlayerColors.textTertiary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Add now →',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: PlayerColors.accent.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exposure hero card ─────────────────────────────────────────────────────────

class _ExposureHeroCard extends StatelessWidget {
  final int score;
  final String firstName;
  final bool loading;
  final int viewCount;
  final VoidCallback? onViewsTap;

  const _ExposureHeroCard({
    required this.score,
    required this.firstName,
    required this.loading,
    this.viewCount = 0,
    this.onViewsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E0E0E), Color(0xFF111A07)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: PlayerColors.accent.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _ExposureRing(score: score, loading: loading),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _Pill(label: 'Exposure Score', accent: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loading
                      ? 'Calculating…'
                      : score >= 70
                          ? 'Strong profile — coaches are finding you'
                          : score >= 40
                              ? 'Keep building — add film to boost your score'
                              : 'Complete your profile to get discovered',
                  style: TextStyle(
                    fontSize: 11,
                    color: PlayerColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (!loading && viewCount > 0) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onViewsTap,
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 12,
                            color: PlayerColors.accent.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '$viewCount coach${viewCount == 1 ? '' : 'es'} viewed you',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PlayerColors.accent.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.chevron_right_rounded, size: 13,
                            color: PlayerColors.accent.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool accent;

  const _Pill({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent
            ? PlayerColors.accent.withValues(alpha: 0.15)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent ? PlayerColors.accent : PlayerColors.textTertiary,
        ),
      ),
    );
  }
}

// ── Exposure ring (arc painter) ────────────────────────────────────────────────

class _ExposureRing extends StatelessWidget {
  final int score;
  final bool loading;

  const _ExposureRing({required this.score, required this.loading});

  static const double _size = 80;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _ArcPainter(score: loading ? 0 : score),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loading ? '—' : '$score',
                style: TextStyle(
                  fontSize: _size * 0.27,
                  fontWeight: FontWeight.w900,
                  color: PlayerColors.accent,
                  height: 1,
                ),
              ),
              Text(
                'EXPOSURE',
                style: TextStyle(
                  fontSize: _size * 0.09,
                  fontWeight: FontWeight.w700,
                  color: PlayerColors.accent.withValues(alpha: 0.55),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final int score;
  _ArcPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -pi / 2; // top

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, 2 * pi, false,
      Paint()
        ..color = const Color(0xFF1A2A0A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc
    if (score > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * pi * (score / 100),
        false,
        Paint()
          ..color = const Color(0xFFC8F135)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.score != score;
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PlayerColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Coach cards (horizontal scroll) ───────────────────────────────────────────

class _CoachCardRow extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const _CoachCardRow({required this.matches});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final m = matches[i];
          final coach = m['coaches'] as Map<String, dynamic>;
          final score = (m['total_score'] as num? ?? 0).round();
          final isHot = i == 0 && score >= 75;
          return _CoachCard(
            schoolName: coach['school_name'] as String? ?? '',
            division: coach['division'] as String? ?? '',
            matchPct: score,
            isHot: isHot,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerMatchesPage()),
            ),
          );
        },
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final String schoolName;
  final String division;
  final int matchPct;
  final bool isHot;
  final VoidCallback onTap;

  const _CoachCard({
    required this.schoolName,
    required this.division,
    required this.matchPct,
    required this.isHot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(
            color: isHot
                ? PlayerColors.accent.withValues(alpha: 0.4)
                : const Color(0xFF1E1E1E),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A0D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🎓', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  schoolName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                if (division.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    division,
                    style: TextStyle(fontSize: 9, color: PlayerColors.textTertiary),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '$matchPct%',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: PlayerColors.accent,
                  ),
                ),
                Text(
                  'match',
                  style: TextStyle(fontSize: 8, color: PlayerColors.textTertiary),
                ),
              ],
            ),
            if (isHot)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: PlayerColors.accent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFF0A0A0A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Activity feed card ─────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  final VoidCallback? onTap;

  const _ActivityCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMatch = item.type == _ActivityType.match;
    final isEvent = item.type == _ActivityType.event;

    final iconBg = isMatch
        ? PlayerColors.accent.withValues(alpha: 0.1)
        : isEvent
            ? const Color(0xFF1A1000)
            : const Color(0xFF001020);
    final iconEmoji = isMatch ? '🏆' : isEvent ? '📅' : '🎬';
    final tappable = onTap != null && item.type != _ActivityType.event;

    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Container(
      decoration: BoxDecoration(
        color: isMatch
            ? PlayerColors.accent.withValues(alpha: 0.04)
            : const Color(0xFF0E0E0E),
        border: Border.all(
          color: isMatch
              ? PlayerColors.accent.withValues(alpha: 0.2)
              : const Color(0xFF1A1A1A),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(iconEmoji, style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB), height: 1.3),
                    children: [
                      TextSpan(
                        text: '${item.title}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      TextSpan(
                        text: item.subtitle,
                        style: isMatch
                            ? TextStyle(
                                color: PlayerColors.accent, fontWeight: FontWeight.w700)
                            : null,
                      ),
                    ],
                  ),
                ),
                if (item.timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(item.timestamp!),
                    style: TextStyle(fontSize: 10, color: PlayerColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: tappable ? PlayerColors.textTertiary : const Color(0xFF2A2A2A),
          ),
        ],
      ),
    ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_data.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../roadmap/presentation/pages/player_roadmap_page.dart';
import '../../../matches/presentation/pages/player_matches_page.dart';
import '../../../../messaging/presentation/pages/conversations_page.dart';
import '../../../search/presentation/pages/player_search_page.dart';
import '../../../../notifications/presentation/widgets/notification_bell.dart';

class PlayerDashboardPage extends StatefulWidget {
  const PlayerDashboardPage({super.key});

  @override
  State<PlayerDashboardPage> createState() => _PlayerDashboardPageState();
}

class _PlayerDashboardPageState extends State<PlayerDashboardPage> {
  int _currentIndex = 0;
  String _firstName = '';
  bool _onboardingComplete = false;
  int _unreadCount = 0;
  RealtimeChannel? _msgChannel;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnread();
    _subscribeUnread();
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
          .select('first_name, onboarding_complete')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _firstName = data['first_name'] ?? '';
          _onboardingComplete = data['onboarding_complete'] as bool? ?? false;
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

  List<Widget> get _pages => [
    _PlayerHomeTab(
      onboardingComplete: _onboardingComplete,
      firstName: _firstName,
      onNavigate: (index) => setState(() => _currentIndex = index),
    ),
    const PlayerMatchesPage(),
    const PlayerRoadmapPage(),
    const PlayerSearchPage(),
    const ConversationsPage(),
  ];

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
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width >= 700;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;

    final appBar = AppBar(
      backgroundColor: isDark ? PlayerColors.surface : AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isDark ? PlayerColors.accentDim : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(isDark ? '⚡' : '⚽', style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Text('LANISTA', style: TextStyle(
            color: accent, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16,
          )),
        ],
      ),
      actions: [
        NotificationBell(iconColor: isDark ? PlayerColors.textSecondary : AppColors.textPrimary),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: isDark ? PlayerColors.accentDim : AppColors.primaryContainer,
            child: Text(
              _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'P',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          onPressed: () => _showProfileMenu(context, isDark),
        ),
        const SizedBox(width: 8),
      ],
    );

    final hasUnread = _unreadCount > 0;
    final badgeLabel = _unreadCount > 9 ? '9+' : '$_unreadCount';
    final badgeColor = isDark ? PlayerColors.accent : AppColors.primary;
    final badgeFg = isDark ? PlayerColors.textOnAccent : Colors.white;

    // Helper: wrap icon with unread badge for the Messages tab (index 4)
    Widget msgIcon(IconData icon, {bool selected = false}) => Badge(
          isLabelVisible: hasUnread,
          label: Text(badgeLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: badgeFg)),
          backgroundColor: badgeColor,
          child: Icon(icon, color: selected ? accent : null),
        );

    if (isTablet) {
      return Scaffold(
        backgroundColor: isDark ? PlayerColors.background : AppColors.background,
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) {
                setState(() => _currentIndex = i);
                if (i == 4) setState(() => _unreadCount = 0); // optimistic clear
              },
              backgroundColor: isDark ? PlayerColors.surface : AppColors.surface,
              indicatorColor: isDark ? PlayerColors.accentDim : AppColors.primaryContainer,
              selectedIconTheme: IconThemeData(color: accent),
              selectedLabelTextStyle: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelTextStyle: TextStyle(
                  color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                  fontSize: 11),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(icon: const Icon(Icons.home_outlined),           selectedIcon: const Icon(Icons.home),           label: Text(l10n.dashboard)),
                NavigationRailDestination(icon: const Icon(Icons.compare_arrows_outlined), selectedIcon: const Icon(Icons.compare_arrows), label: Text(l10n.matches)),
                NavigationRailDestination(icon: const Icon(Icons.map_outlined),            selectedIcon: const Icon(Icons.map),            label: Text(l10n.roadmap)),
                NavigationRailDestination(icon: const Icon(Icons.search_outlined),         selectedIcon: const Icon(Icons.search),         label: Text(l10n.search)),
                NavigationRailDestination(
                  icon: msgIcon(Icons.chat_bubble_outline),
                  selectedIcon: msgIcon(Icons.chat_bubble, selected: true),
                  label: Text(l10n.messages),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? PlayerColors.background : AppColors.background,
      appBar: appBar,
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 4) setState(() => _unreadCount = 0); // optimistic clear
        },
        backgroundColor: isDark ? PlayerColors.surface : AppColors.surface,
        indicatorColor: isDark ? PlayerColors.accentDim : AppColors.primaryContainer,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined),           selectedIcon: Icon(Icons.home,           color: accent), label: l10n.dashboard),
          NavigationDestination(icon: const Icon(Icons.compare_arrows_outlined), selectedIcon: Icon(Icons.compare_arrows, color: accent), label: l10n.matches),
          NavigationDestination(icon: const Icon(Icons.map_outlined),            selectedIcon: Icon(Icons.map,            color: accent), label: l10n.roadmap),
          NavigationDestination(icon: const Icon(Icons.search_outlined),         selectedIcon: Icon(Icons.search,         color: accent), label: l10n.search),
          NavigationDestination(
            icon: msgIcon(Icons.chat_bubble_outline),
            selectedIcon: msgIcon(Icons.chat_bubble, selected: true),
            label: l10n.messages,
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? PlayerColors.surfaceElevated : Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person_outline, color: isDark ? PlayerColors.textPrimary : null),
              title: Text('My Profile', style: TextStyle(color: isDark ? PlayerColors.textPrimary : null)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/player/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: isDark ? PlayerColors.textPrimary : null),
              title: Text('Settings', style: TextStyle(color: isDark ? PlayerColors.textPrimary : null)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: isDark ? PlayerColors.error : AppColors.error),
              title: Text('Sign Out', style: TextStyle(color: isDark ? PlayerColors.error : AppColors.error)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/auth/login', extra: {'skipBiometrics': true});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHomeTab extends StatefulWidget {
  final bool onboardingComplete;
  final String firstName;
  final void Function(int index) onNavigate;

  const _PlayerHomeTab({
    this.onboardingComplete = false,
    this.firstName = '',
    required this.onNavigate,
  });

  @override
  State<_PlayerHomeTab> createState() => _PlayerHomeTabState();
}

class _PlayerHomeTabState extends State<_PlayerHomeTab> {
  int _matchCount = 0;
  int _roadmapStepsCompleted = 0;
  int _messageCount = 0;
  int _profileViewCount = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // On Android the session may still be restoring — wait up to 3s for it
      String? userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        userId = Supabase.instance.client.auth.currentUser?.id;
      }
      if (userId == null) return;

      final playerResult = await Supabase.instance.client
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (playerResult == null) return;
      final playerId = playerResult['id'] as String;

      final since30 = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final results = await Future.wait([
        Supabase.instance.client
            .from('player_coach_matches')
            .select('id')
            .eq('player_id', playerId),
        Supabase.instance.client
            .from('player_roadmaps')
            .select('roadmap_milestones(id)')
            .eq('player_id', playerId)
            .eq('roadmap_milestones.is_completed', true),
        Supabase.instance.client
            .from('conversations')
            .select('id')
            .eq('player_id', playerId),
        Supabase.instance.client
            .from('profile_views')
            .select('coach_id')
            .eq('player_id', playerId)
            .gte('viewed_at', since30),
      ]);

      final matches = results[0] as List;
      final roadmaps = results[1] as List;
      int completedSteps = 0;
      for (final r in roadmaps) {
        final milestones = r['roadmap_milestones'] as List? ?? [];
        completedSteps += milestones.length;
      }
      final convos = results[2] as List;
      // Deduplicate views by coach_id
      final viewCoaches = (results[3] as List).map((r) => r['coach_id']).toSet();

      if (mounted) {
        setState(() {
          _matchCount = matches.length;
          _roadmapStepsCompleted = completedSteps;
          _messageCount = convos.length;
          _profileViewCount = viewCoaches.length;
          _statsLoaded = true;
        });
      }
    } catch (e, st) {
      debugPrint('Dashboard _loadStats error: $e\n$st');
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final isTablet = MediaQuery.of(context).size.width >= 700;
    return isTablet ? _buildTablet(context, isDark) : _buildPhone(context, isDark);
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────

  Widget _heroCard(BuildContext context, bool isDark) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [PlayerColors.gradientStart, PlayerColors.gradientEnd]
            : [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.onboardingComplete && widget.firstName.isNotEmpty
              ? 'Welcome back, ${widget.firstName}! 👋'
              : 'Welcome to Lanista! 👋',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          widget.onboardingComplete
              ? 'Your profile is live. Coaches can discover you now.'
              : 'Complete your profile to get matched with college programs.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? PlayerColors.accent : Colors.white,
            foregroundColor: isDark ? PlayerColors.textOnAccent : AppColors.primary,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => context.push(
            widget.onboardingComplete ? '/player/profile' : '/player/profile/setup',
          ),
          child: Text(
            widget.onboardingComplete ? 'View Profile' : 'Complete Profile',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  List<Widget> _statCards(bool isDark) => [
    _StatCard(label: 'Program Matches', value: _statsLoaded ? '$_matchCount' : '—',
        icon: Icons.compare_arrows,
        color: isDark ? PlayerColors.accent : AppColors.primary,
        onTap: () => widget.onNavigate(1)),
    _StatCard(label: 'Roadmap Steps', value: _statsLoaded ? '$_roadmapStepsCompleted' : '—',
        icon: Icons.map_outlined,
        color: isDark ? PlayerColors.info : AppColors.secondary,
        onTap: () => widget.onNavigate(2)),
    _StatCard(label: 'Profile Views', value: _statsLoaded ? '$_profileViewCount' : '—',
        icon: Icons.visibility_outlined,
        color: isDark ? PlayerColors.warning : AppColors.coachColor,
        onTap: () => context.push('/player/profile-views')),
    _StatCard(label: 'Messages', value: _statsLoaded ? '$_messageCount' : '—',
        icon: Icons.chat_bubble_outline,
        color: isDark ? PlayerColors.success : AppColors.mentorColor,
        onTap: () => widget.onNavigate(4)),
  ];

  List<Widget> _educationCards(bool isDark) => [
    _EducationCard(title: 'The State of College Soccer Recruiting in 2026',
        readTime: '5 min read', onTap: () => context.push('/education/e1')),
    _EducationCard(title: 'D1 vs D2 vs D3: Which Is Right for You?',
        readTime: '4 min read', onTap: () => context.push('/education/e2')),
    _EducationCard(title: 'ID Camps: Genuine or Just a Money Grab?',
        readTime: '6 min read', onTap: () => context.push('/education/e3')),
    _EducationCard(title: 'See all articles →',
        readTime: 'Education hub', onTap: () => context.push('/education')),
  ];

  // ── Phone layout ────────────────────────────────────────────────────────────

  Widget _buildPhone(BuildContext context, bool isDark) {
    final cards = _statCards(isDark);
    final textColor = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroCard(context, isDark),
          const SizedBox(height: 24),
          Text('Your Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
          const SizedBox(height: 24),
          Text('Learn the Process',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 12),
          ..._educationCards(isDark).map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)),
        ],
      ),
    );
  }

  // ── Tablet layout ───────────────────────────────────────────────────────────

  Widget _buildTablet(BuildContext context, bool isDark) {
    final cards = _statCards(isDark);
    final textColor = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column — hero + education
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCard(context, isDark),
                const SizedBox(height: 24),
                Text('Learn the Process',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 12),
                ..._educationCards(isDark).map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column — stat cards
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final String title;
  final String readTime;
  final VoidCallback onTap;

  const _EducationCard({
    required this.title,
    required this.readTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? PlayerColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.accentDim : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📚', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    readTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

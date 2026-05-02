import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/coach_analytics_scope.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../messaging/presentation/pages/conversations_page.dart';
import '../../../search/presentation/pages/coach_search_page.dart';
import '../../../matches/presentation/pages/coach_matches_page.dart';
import '../../../pipeline/presentation/pages/coach_pipeline_page.dart';
import 'coach_roster_map_page.dart';
import '../../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../roi/presentation/pages/coach_roi_page.dart';

class CoachDashboardPage extends StatefulWidget {
  const CoachDashboardPage({super.key});

  @override
  State<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends State<CoachDashboardPage> {
  int _currentIndex = 0;
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  bool _onboardingComplete = false;

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

  List<Widget> get _pages => [
    _CoachHomeTab(
      onboardingComplete: _onboardingComplete,
      firstName: _firstName,
      onGoToMatches:   () => setState(() => _currentIndex = 1),
      onGoToRoster:    () => setState(() => _currentIndex = 2),
      onGoToPipeline:  () => setState(() => _currentIndex = 3),
      onGoToMessages:  () => setState(() => _currentIndex = 5),
    ),
    const CoachMatchesPage(),
    const CoachRosterMapPage(),
    const CoachPipelinePage(),
    const CoachSearchPage(),
    const ConversationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width >= 700;
    final analyticsService = GetIt.instance<CoachAnalyticsService>();

    final appBar = AppBar(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.coachColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('📋', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          const Text('LANISTA', style: TextStyle(
            color: AppColors.coachColor, fontWeight: FontWeight.w900,
            letterSpacing: 2, fontSize: 16,
          )),
        ],
      ),
      actions: [
        NotificationBell(iconColor: AppColors.textPrimary),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.coachColor.withValues(alpha: 0.1),
            child: Text(
              _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'C',
              style: const TextStyle(color: AppColors.coachColor,
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          onPressed: () => _showProfileMenu(context),
        ),
        const SizedBox(width: 8),
      ],
    );

    final navDestinations = [
      (Icons.home_outlined,      Icons.home,           l10n.dashboard),
      (Icons.auto_awesome_outlined, Icons.auto_awesome, l10n.matches),
      (Icons.grid_view_outlined, Icons.grid_view,      l10n.rosterMap),
      (Icons.view_kanban_outlined, Icons.view_kanban,  l10n.pipeline),
      (Icons.search_outlined,    Icons.search,         l10n.search),
      (Icons.chat_bubble_outline, Icons.chat_bubble,   l10n.messages),
    ];

    if (isTablet) {
      return CoachAnalyticsScope(
        service: analyticsService,
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.coachColor.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(color: AppColors.coachColor),
              selectedLabelTextStyle: const TextStyle(
                  color: AppColors.coachColor, fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelTextStyle: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
              labelType: NavigationRailLabelType.all,
              destinations: navDestinations.map((d) => NavigationRailDestination(
                icon: Icon(d.$1),
                selectedIcon: Icon(d.$2),
                label: Text(d.$3),
              )).toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      ),
    );
    }

    // Phone layout
    return CoachAnalyticsScope(
      service: analyticsService,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.coachColor.withValues(alpha: 0.1),
        destinations: navDestinations.map((d) => NavigationDestination(
          icon: Icon(d.$1),
          selectedIcon: Icon(d.$2, color: AppColors.coachColor),
          label: d.$3,
        )).toList(),
      ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final analyticsService = GetIt.instance<CoachAnalyticsService>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Analytics Mode toggle
              ValueListenableBuilder<bool>(
                valueListenable: analyticsService,
                builder: (_, isAnalytics, __) => ListTile(
                  leading: Icon(
                    Icons.trending_up,
                    color: isAnalytics ? AppColors.coachColor : AppColors.textSecondary,
                  ),
                  title: const Text('Analytics Mode'),
                  subtitle: Text(
                    isAnalytics
                        ? 'Deep metrics, ROI charts & benchmarks'
                        : 'Standard view — tap to unlock analytics',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Switch(
                    value: isAnalytics,
                    activeColor: AppColors.coachColor,
                    onChanged: (_) => analyticsService.toggle(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My Profile'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (ctx.mounted) ctx.go('/auth/login', extra: {'skipBiometrics': true});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachHomeTab extends StatefulWidget {
  final bool onboardingComplete;
  final String firstName;
  final VoidCallback? onGoToMatches;
  final VoidCallback? onGoToRoster;
  final VoidCallback? onGoToPipeline;
  final VoidCallback? onGoToMessages;
  const _CoachHomeTab({
    this.onboardingComplete = false,
    this.firstName = '',
    this.onGoToMatches,
    this.onGoToRoster,
    this.onGoToPipeline,
    this.onGoToMessages,
  });

  @override
  State<_CoachHomeTab> createState() => _CoachHomeTabState();
}

class _CoachHomeTabState extends State<_CoachHomeTab> {
  int _rosterGaps = 0;
  int _playerMatches = 0;
  int _inPipeline = 0;
  int _messages = 0;
  bool _statsLoaded = false;

  // Analytics Mode — ROI summary
  double _avgRoi = 0;
  int _portalRisks = 0;
  int _foundationPlayers = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final coachResult = await Supabase.instance.client
          .from('coaches')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (coachResult == null) return;
      final coachId = coachResult['id'] as String;

      final results = await Future.wait([
        Supabase.instance.client
            .from('roster_slots')
            .select('id')
            .eq('coach_id', coachId)
            .eq('needs_recruit', true),
        Supabase.instance.client
            .from('player_coach_matches')
            .select('id')
            .eq('coach_id', coachId),
        Supabase.instance.client
            .from('recruiting_pipeline')
            .select('id')
            .eq('coach_id', coachId)
            .not('stage', 'in', '(declined,lost)'),
        Supabase.instance.client
            .from('conversations')
            .select('id')
            .eq('coach_id', coachId),
      ]);

      // ROI summary (always loaded, shown only in analytics mode)
      final roiRows = await Supabase.instance.client
          .from('player_roi_records')
          .select('roi_score, portal_risk, retention_quadrant, career_status')
          .eq('coach_id', coachId);

      final active = (roiRows as List).where((r) => r['career_status'] == 'active').toList();
      final avgRoi = active.isEmpty ? 0.0
          : active.map((r) => (r['roi_score'] as num).toDouble()).reduce((a, b) => a + b) / active.length;

      if (mounted) {
        setState(() {
          _rosterGaps         = (results[0] as List).length;
          _playerMatches      = (results[1] as List).length;
          _inPipeline         = (results[2] as List).length;
          _messages           = (results[3] as List).length;
          _avgRoi             = avgRoi;
          _portalRisks        = (roiRows as List).where((r) => r['portal_risk'] == true).length;
          _foundationPlayers  = (roiRows as List).where((r) => r['retention_quadrant'] == 'foundation').length;
          _statsLoaded        = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 700;
    return isTablet ? _buildTablet(context) : _buildPhone(context);
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────

  Widget _heroCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.coachColor, AppColors.coachColor.withValues(alpha: 0.7)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.onboardingComplete && widget.firstName.isNotEmpty
              ? 'Welcome back, ${widget.firstName}! 📋'
              : 'Welcome, Coach! 📋',
          style: const TextStyle(color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          widget.onboardingComplete
              ? 'Your blueprint is live. The matching engine is finding players for you.'
              : 'Set up your tactical blueprint and roster map to start finding your next recruits.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.coachColor,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => context.push('/coach/tactical-blueprint'),
          child: Text(
            widget.onboardingComplete ? 'Edit Blueprint' : 'Setup Tactical Blueprint',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _matchesCta() => GestureDetector(
    onTap: widget.onGoToMatches,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coachColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coachColor.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Text('⚡', style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('View Blueprint Matches',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 14, color: AppColors.coachColor)),
                SizedBox(height: 2),
                Text('See players ranked by position, graduation year, and GPA fit',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.coachColor),
        ],
      ),
    ),
  );

  List<Widget> _statCards() => [
    _CoachStatCard(label: 'Roster Gaps',    value: _statsLoaded ? '$_rosterGaps' : '—',
        icon: Icons.grid_view_outlined,     color: AppColors.coachColor,  onTap: widget.onGoToRoster),
    _CoachStatCard(label: 'Player Matches', value: _statsLoaded ? '$_playerMatches' : '—',
        icon: Icons.auto_awesome_outlined,  color: AppColors.primary,     onTap: widget.onGoToMatches),
    _CoachStatCard(label: 'In Pipeline',    value: _statsLoaded ? '$_inPipeline' : '—',
        icon: Icons.view_kanban_outlined,   color: AppColors.secondary,   onTap: widget.onGoToPipeline),
    _CoachStatCard(label: 'Messages',       value: _statsLoaded ? '$_messages' : '—',
        icon: Icons.chat_bubble_outline,    color: AppColors.mentorColor, onTap: widget.onGoToMessages),
  ];

  // ── Analytics Mode widget ────────────────────────────────────────────────────

  Widget _analyticsWidget(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CoachRoiPage())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.coachColor.withValues(alpha: 0.07),
                     AppColors.coachColor.withValues(alpha: 0.02)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.coachColor.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.trending_up, color: AppColors.coachColor, size: 18),
            const SizedBox(width: 8),
            const Text('Recruiting ROI',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                    color: AppColors.coachColor)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.coachColor.withValues(alpha: 0.6)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _roiMiniStat('Avg ROI',
                _statsLoaded ? _avgRoi.toStringAsFixed(1) : '—',
                AppColors.coachColor)),
            const SizedBox(width: 12),
            Expanded(child: _roiMiniStat('Foundation',
                _statsLoaded ? '$_foundationPlayers' : '—',
                const Color(0xFF2E7D32))),
            const SizedBox(width: 12),
            Expanded(child: _roiMiniStat('Portal Risk',
                _statsLoaded ? '$_portalRisks' : '—',
                _portalRisks > 0 ? const Color(0xFFC62828) : AppColors.textSecondary)),
          ]),
          if (_portalRisks > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Text('🔴', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text('$_portalRisks player${_portalRisks > 1 ? 's' : ''} flagged — tap to view retention matrix',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFC62828),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.coachColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('View Retention Matrix →',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _roiMiniStat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ],
  );

  // ── Phone layout ────────────────────────────────────────────────────────────

  Widget _buildPhone(BuildContext context) {
    final cards = _statCards();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroCard(context),
          const SizedBox(height: 24),
          const Text('Recruiting Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3]),
          ]),
          if (widget.onboardingComplete) ...[
            const SizedBox(height: 20),
            _matchesCta(),
          ],
          if (CoachAnalyticsScope.isEnabled(context)) ...[
            const SizedBox(height: 20),
            _analyticsWidget(context),
          ],
        ],
      ),
    );
  }

  // ── Tablet layout ───────────────────────────────────────────────────────────

  Widget _buildTablet(BuildContext context) {
    final cards = _statCards();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card — full width
          _heroCard(context),
          const SizedBox(height: 24),
          // 4 stat cards in a single row
          const Text('Recruiting Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: cards[0]), const SizedBox(width: 12),
            Expanded(child: cards[1]), const SizedBox(width: 12),
            Expanded(child: cards[2]), const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ]),
          // Matches CTA — full width
          if (widget.onboardingComplete) ...[
            const SizedBox(height: 20),
            _matchesCta(),
          ],
          // Analytics Mode widget — full width
          if (CoachAnalyticsScope.isEnabled(context)) ...[
            const SizedBox(height: 20),
            _analyticsWidget(context),
          ],
        ],
      ),
    );
  }
}

class _CoachStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CoachStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 10, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _CoachRosterMapTab extends StatelessWidget {
  const _CoachRosterMapTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('📊', style: TextStyle(fontSize: 64)),
      SizedBox(height: 16),
      Text('Roster Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      Text('Build your multi-year roster map\nto identify recruiting gaps.',
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
    ]));
  }
}




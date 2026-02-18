import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../messaging/presentation/pages/conversations_page.dart';

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

  Future<void> _loadUser() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('users')
          .select('first_name')
          .eq('id', userId)
          .single();
      if (mounted) setState(() => _firstName = data['first_name'] ?? '');
    } catch (_) {}
  }

  List<Widget> get _pages => [
    const _CoachHomeTab(),
    const _CoachRosterMapTab(),
    const _CoachPipelineTab(),
    const _CoachSearchTab(),
    const ConversationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
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
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.coachColor.withValues(alpha: 0.1),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.coachColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view, color: AppColors.coachColor),
            label: l10n.rosterMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_kanban_outlined),
            selectedIcon: const Icon(Icons.view_kanban, color: AppColors.coachColor),
            label: l10n.pipeline,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search, color: AppColors.coachColor),
            label: l10n.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble, color: AppColors.coachColor),
            label: l10n.messages,
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/auth/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachHomeTab extends StatelessWidget {
  const _CoachHomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                const Text('Welcome, Coach! 📋',
                    style: TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Set up your tactical blueprint and roster map\nto start finding your next recruits.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.coachColor,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.push('/coach/tactical-blueprint'),
                  child: const Text('Setup Tactical Blueprint',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recruiting Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _CoachStatCard(label: 'Roster Gaps', value: '0',
                  icon: Icons.grid_view_outlined, color: AppColors.coachColor)),
              const SizedBox(width: 12),
              Expanded(child: _CoachStatCard(label: 'Player Matches', value: '0',
                  icon: Icons.people_outline, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _CoachStatCard(label: 'In Pipeline', value: '0',
                  icon: Icons.view_kanban_outlined, color: AppColors.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _CoachStatCard(label: 'Messages', value: '0',
                  icon: Icons.chat_bubble_outline, color: AppColors.mentorColor)),
            ],
          ),
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

  const _CoachStatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
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

class _CoachPipelineTab extends StatelessWidget {
  const _CoachPipelineTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('📈', style: TextStyle(fontSize: 64)),
      SizedBox(height: 16),
      Text('Recruiting Pipeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      Text('Track prospects from identified\nto committed.',
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
    ]));
  }
}

class _CoachSearchTab extends StatelessWidget {
  const _CoachSearchTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('🔍', style: TextStyle(fontSize: 64)),
      SizedBox(height: 16),
      Text('Search Players', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      Text('Search players by position, grade,\nleague, GPA, and more.',
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
    ]));
  }
}


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Parent companion mode — links to a player's account, monitors progress,
/// approves messages, and tracks the financial roadmap.
class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  int _currentIndex = 0;
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final userData = await Supabase.instance.client
          .from('users')
          .select('first_name')
          .eq('id', userId)
          .single();
      if (mounted) setState(() => _firstName = userData['first_name'] ?? '');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.parentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
            const Text('LANISTA',
                style: TextStyle(
                    color: AppColors.parentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 16)),
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
              backgroundColor: AppColors.parentColor.withValues(alpha: 0.1),
              child: Text(
                _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'P',
                style: const TextStyle(
                    color: AppColors.parentColor, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            onPressed: () => _showSignOut(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _ParentHomeTab(),
          _ParentPlayerTab(),
          _ParentFinancialTab(),
          _ParentMessagesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.parentColor.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.parentColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.parentColor),
            label: 'My Player',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money, color: AppColors.parentColor),
            label: 'Financial',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.parentColor),
            label: 'Messages',
          ),
        ],
      ),
    );
  }

  void _showSignOut(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (ctx.mounted) ctx.go('/auth/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ───────────────────────────────────────────────────────────────────

class _ParentHomeTab extends StatelessWidget {
  const _ParentHomeTab();

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
                colors: [AppColors.parentColor, AppColors.parentColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parent Companion Mode 👨‍👩‍👧',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(
                  'Monitor your player\'s recruiting journey, approve coach messages, and plan the financial roadmap.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.parentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🔗', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Link Your Player',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Ask your player to send you an invitation from their account.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('How Can I Help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...[
            ('👀', 'Monitor Recruiting Progress', 'See your player\'s matches, roadmap, and profile views'),
            ('✅', 'Approve Coach Messages', 'COPPA compliance — review and approve messages from coaches'),
            ('💰', 'Financial Roadmap', 'Plan the full cost — clubs, camps, travel, tuition'),
            ('📚', 'Education Module', 'Learn the recruiting process — divisions, ID camps, transfer portal'),
            ('🌍', 'Gap Year Options', 'Research European gap year academies'),
          ].map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(action.$1, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(action.$2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(action.$3,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Player Tab ─────────────────────────────────────────────────────────────────

class _ParentPlayerTab extends StatelessWidget {
  const _ParentPlayerTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔗', style: TextStyle(fontSize: 52)),
            SizedBox(height: 16),
            Text('Link Your Player',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Ask your player to send you an invitation from their Lanista account. Once linked, you\'ll see their full profile here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Financial Tab ──────────────────────────────────────────────────────────────

class _ParentFinancialTab extends StatelessWidget {
  const _ParentFinancialTab();

  static const _years = [
    ('6th–8th Grade', 'Foundation', 3500, 8000, 'Club fees, uniforms, travel tournaments'),
    ('9th–10th Grade', 'Development', 5000, 12000, 'Higher club, private training, exposure events'),
    ('11th Grade', 'Recruitment', 6000, 15000, 'ID camps, official visits, recruiting travel'),
    ('12th Grade', 'Commitment', 2000, 5000, 'NLI prep, campus visits, decision costs'),
  ];

  @override
  Widget build(BuildContext context) {
    // Range: $16,500 – $40,000 across all phases

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.parentColor, AppColors.parentColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Recruiting Journey',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text('\$20k – \$40k',
                    style: TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                Text('Estimated total across all phases',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Year-by-Year Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._years.map((year) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(year.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(year.$2,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          Text(
                            '\$${_fmt(year.$3)}–\$${_fmt(year.$4)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.parentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(year.$5,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '💡 Athletic scholarships can offset 5–100% of tuition. D3 and NAIA programs offer merit-based academic aid instead. Lanista surfaces programs matching your budget and target division.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) => n >= 1000 ? '\$${(n / 1000).toStringAsFixed(0)}k' : '\$$n';
}

// ─── Messages Tab ───────────────────────────────────────────────────────────────

class _ParentMessagesTab extends StatelessWidget {
  const _ParentMessagesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅', style: TextStyle(fontSize: 52)),
            SizedBox(height: 16),
            Text('Message Approvals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'When a college coach messages your under-18 player, it appears here for your review first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 16),
            Text('No pending approvals',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

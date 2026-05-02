import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/player_colors.dart';
import '../../../../../core/theme/player_theme_scope.dart';
import '../../../../../core/di/injection.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

class _ProfileView {
  final String coachId;
  final String schoolName;
  final String division;
  final DateTime viewedAt;

  const _ProfileView({
    required this.coachId,
    required this.schoolName,
    required this.division,
    required this.viewedAt,
  });
}

class PlayerProfileViewsPage extends StatefulWidget {
  const PlayerProfileViewsPage({super.key});

  @override
  State<PlayerProfileViewsPage> createState() => _PlayerProfileViewsPageState();
}

class _PlayerProfileViewsPageState extends State<PlayerProfileViewsPage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<_ProfileView> _views = [];
  int _totalLast30 = 0;
  int _totalLast7 = 0;

  @override
  void initState() {
    super.initState();
    _loadViews();
  }

  Future<void> _loadViews() async {
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

      final playerId = playerRow['id'] as String;
      final since30 = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      // Fetch views with coach info — most recent view per coach
      final rows = await _supabase
          .from('profile_views')
          .select('coach_id, viewed_at, coaches(school_name, division)')
          .eq('player_id', playerId)
          .gte('viewed_at', since30)
          .order('viewed_at', ascending: false);

      if (!mounted) return;

      // Deduplicate: keep only the most recent view per coach
      final seen = <String>{};
      final deduped = <_ProfileView>[];
      final now = DateTime.now();

      for (final r in rows as List) {
        final coachId = r['coach_id'] as String;
        if (seen.contains(coachId)) continue;
        seen.add(coachId);

        final coach = r['coaches'] as Map<String, dynamic>?;
        final viewedAt = DateTime.tryParse(r['viewed_at'] as String? ?? '') ?? now;

        deduped.add(_ProfileView(
          coachId: coachId,
          schoolName: coach?['school_name'] as String? ?? 'Unknown Program',
          division: coach?['division'] as String? ?? '',
          viewedAt: viewedAt,
        ));
      }

      setState(() {
        _views = deduped;
        _totalLast30 = seen.length;
        _totalLast7 = deduped
            .where((v) => now.difference(v.viewedAt).inDays < 7)
            .length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
    return PlayerThemeScope(
      service: themeService,
      child: _ProfileViewsContent(loading: _loading, views: _views,
          totalLast30: _totalLast30, totalLast7: _totalLast7,
          onRefresh: _loadViews),
    );
  }
}

class _ProfileViewsContent extends StatelessWidget {
  final bool loading;
  final List<_ProfileView> views;
  final int totalLast30;
  final int totalLast7;
  final Future<void> Function() onRefresh;

  const _ProfileViewsContent({
    required this.loading,
    required this.views,
    required this.totalLast30,
    required this.totalLast7,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final bg = isDark ? PlayerColors.background : AppColors.background;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    final appBarBg = isDark ? PlayerColors.surface : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile Views',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : RefreshIndicator(
              color: accent,
              onRefresh: onRefresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSummary(isDark, accent)),
                  if (views.isEmpty)
                    SliverFillRemaining(child: _buildEmpty(isDark, accent))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _ViewTile(view: views[i], isDark: isDark, accent: accent),
                        childCount: views.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary(bool isDark, Color accent) {
    final surface = isDark ? PlayerColors.surface : Colors.white;
    final border = isDark ? PlayerColors.border : AppColors.border;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '$totalLast7',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                Text(
                  'Last 7 days',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: border),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$totalLast30',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Last 30 days',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color accent) {
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
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.visibility_outlined, size: 40, color: accent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No views yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When coaches view your profile, they\'ll appear here. Complete your profile and upload a highlight film to get noticed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewTile extends StatelessWidget {
  final _ProfileView view;
  final bool isDark;
  final Color accent;

  const _ViewTile({required this.view, required this.isDark, required this.accent});

  void _showProgramSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProgramSheet(
        coachId: view.coachId,
        isDark: isDark,
        accent: accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? PlayerColors.surface : Colors.white;
    final border = isDark ? PlayerColors.border : AppColors.border;

    return GestureDetector(
      onTap: () => _showProgramSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.school_outlined, color: accent, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.schoolName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    view.division.isNotEmpty ? view.division : 'College Program',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeAgo(view.viewedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, size: 16,
                    color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Program Bottom Sheet ──────────────────────────────────────────────────────

class _ProgramSheet extends StatefulWidget {
  final String coachId;
  final bool isDark;
  final Color accent;

  const _ProgramSheet({
    required this.coachId,
    required this.isDark,
    required this.accent,
  });

  @override
  State<_ProgramSheet> createState() => _ProgramSheetState();
}

class _ProgramSheetState extends State<_ProgramSheet> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _coach;
  String? _coachName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await _supabase
          .from('coaches')
          .select('''
            school_name, division, state, primary_formation,
            playing_style, min_gpa, min_sat, min_act, bio,
            gender_program, coach_type,
            users(first_name, last_name)
          ''')
          .eq('id', widget.coachId)
          .single();

      final u = row['users'] as Map<String, dynamic>?;
      final name = u != null
          ? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim()
          : null;

      if (mounted) {
        setState(() {
          _coach = row;
          _coachName = name;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? PlayerColors.surface : Colors.white;
    final textPrimary = widget.isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = widget.isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    final border = widget.isDark ? PlayerColors.border : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            Center(child: CircularProgressIndicator(color: widget.accent))
          else if (_coach == null)
            Center(child: Text('Program not found', style: TextStyle(color: textSecondary)))
          else
            _buildContent(textPrimary, textSecondary, border),
        ],
      ),
    );
  }

  Widget _buildContent(Color textPrimary, Color textSecondary, Color border) {
    final c = _coach!;
    final schoolName = c['school_name'] as String? ?? 'Unknown Program';
    final division = c['division'] as String? ?? '';
    final state = c['state'] as String? ?? '';
    final formation = c['primary_formation'] as String? ?? '';
    final style = c['playing_style'] as String? ?? '';
    final minGpa = c['min_gpa'];
    final bio = c['bio'] as String? ?? '';
    final genderProgram = c['gender_program'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School + icon
        Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.school, color: widget.accent, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schoolName,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  if (division.isNotEmpty || state.isNotEmpty)
                    Text(
                      [division, state].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_coachName != null && _coachName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _chip(Icons.person_outline, _coachName!, textSecondary),
        ],
        const SizedBox(height: 16),
        // Tags row
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            if (genderProgram.isNotEmpty)
              _tag(genderProgram == 'male' ? "Men's Program" : "Women's Program",
                  widget.accent),
            if (formation.isNotEmpty) _tag(formation, widget.accent),
            if (style.isNotEmpty) _tag(style, widget.accent),
            if (minGpa != null) _tag('Min GPA $minGpa', widget.accent),
          ],
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(bio,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5)),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  Widget _tag(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

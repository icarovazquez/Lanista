import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../messaging/presentation/pages/conversation_detail_page.dart';
import '../../../search/presentation/pages/coach_player_detail_page.dart';

/// Coach's "Matches" tab — shows players ranked by the blueprint matching engine.
/// Calls the `coach_player_matches()` PostgreSQL function via RPC.
class CoachMatchesPage extends StatefulWidget {
  const CoachMatchesPage({super.key});

  @override
  State<CoachMatchesPage> createState() => _CoachMatchesPageState();
}

class _CoachMatchesPageState extends State<CoachMatchesPage>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _error;
  bool _onboardingComplete = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Check if coach has completed onboarding
      final coachData = await _supabase
          .from('coaches')
          .select('onboarding_complete')
          .eq('user_id', userId)
          .maybeSingle();

      _onboardingComplete = coachData?['onboarding_complete'] as bool? ?? false;

      if (!_onboardingComplete) {
        setState(() => _isLoading = false);
        return;
      }

      // Call the matching engine function
      final data = await _supabase.rpc('coach_player_matches');

      if (mounted) {
        setState(() {
          _matches = List<Map<String, dynamic>>.from(data as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coachColor),
      );
    }

    if (!_onboardingComplete) {
      return _buildSetupPrompt(context);
    }

    if (_error != null) {
      return _buildError();
    }

    if (_matches.isEmpty) {
      return _buildEmpty();
    }

    return _buildMatchList();
  }

  Widget _buildSetupPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.coachColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🧩', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Set Up Your Blueprint First',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'The matching engine uses your tactical blueprint — formation, position requirements, and recruiting class years — to find the best players for your program.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coachColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // Navigate to blueprint (go_router not available here, use Navigator)
                // The dashboard handles this via tab index; we just show the prompt.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Go to Dashboard → Setup Tactical Blueprint'),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Complete Tactical Blueprint',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Could not load matches',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coachColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'No matches yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'No discoverable players match your blueprint yet. As more players join and set their profiles as discoverable, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList() {
    // Group by match label for section headers
    final excellent =
        _matches.where((m) => m['match_label'] == 'Excellent').toList();
    final strong =
        _matches.where((m) => m['match_label'] == 'Strong').toList();
    final good = _matches.where((m) => m['match_label'] == 'Good').toList();
    final possible =
        _matches.where((m) => m['match_label'] == 'Possible').toList();

    return RefreshIndicator(
      color: AppColors.coachColor,
      onRefresh: _loadMatches,
      child: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blueprint Matches',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_matches.length} player${_matches.length == 1 ? '' : 's'} found',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  _MatchLegend(),
                ],
              ),
            ),
          ),

          // ── Excellent matches ─────────────────────────────────────────────
          if (excellent.isNotEmpty) ...[
            _buildSectionHeader('⚡ Excellent Match', excellent.length,
                AppColors.coachColor),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MatchCard(
                  player: excellent[i],
                  onViewProfile: () => _viewPlayerProfile(excellent[i]),
                  onContact: () => _contactPlayer(excellent[i]),
                  onAddToPipeline: () => _addToPipeline(excellent[i]),
                ),
                childCount: excellent.length,
              ),
            ),
          ],

          // ── Strong matches ────────────────────────────────────────────────
          if (strong.isNotEmpty) ...[
            _buildSectionHeader(
                '✅ Strong Match', strong.length, AppColors.success),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MatchCard(
                  player: strong[i],
                  onViewProfile: () => _viewPlayerProfile(strong[i]),
                  onContact: () => _contactPlayer(strong[i]),
                  onAddToPipeline: () => _addToPipeline(strong[i]),
                ),
                childCount: strong.length,
              ),
            ),
          ],

          // ── Good matches ──────────────────────────────────────────────────
          if (good.isNotEmpty) ...[
            _buildSectionHeader('👍 Good Match', good.length, AppColors.primary),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MatchCard(
                  player: good[i],
                  onViewProfile: () => _viewPlayerProfile(good[i]),
                  onContact: () => _contactPlayer(good[i]),
                  onAddToPipeline: () => _addToPipeline(good[i]),
                ),
                childCount: good.length,
              ),
            ),
          ],

          // ── Possible matches ──────────────────────────────────────────────
          if (possible.isNotEmpty) ...[
            _buildSectionHeader(
                '🔎 Possible Match', possible.length, AppColors.textSecondary),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _MatchCard(
                  player: possible[i],
                  onViewProfile: () => _viewPlayerProfile(possible[i]),
                  onContact: () => _contactPlayer(possible[i]),
                  onAddToPipeline: () => _addToPipeline(possible[i]),
                ),
                childCount: possible.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(
      String title, int count, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add to pipeline ────────────────────────────────────────────────────────

  Future<void> _addToPipeline(Map<String, dynamic> match) async {
    final coachUserId = _supabase.auth.currentUser?.id;
    if (coachUserId == null) return;

    try {
      final coachData = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', coachUserId)
          .maybeSingle();
      if (coachData == null) return;
      final coachId = coachData['id'] as String;

      final playerUserId = match['player_user_id'] as String;
      final playerRecord = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', playerUserId)
          .maybeSingle();
      if (playerRecord == null) return;
      final playerId = playerRecord['id'] as String;

      // Upsert — ignore if already in pipeline
      await _supabase.from('recruiting_pipeline').upsert({
        'coach_id': coachId,
        'player_id': playerId,
        'stage': 'identified',
      }, onConflict: 'coach_id,player_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to Pipeline → Identified'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add to pipeline: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── View player profile ────────────────────────────────────────────────────

  Future<void> _viewPlayerProfile(Map<String, dynamic> match) async {
    final playerUserId = match['player_user_id'] as String?;
    if (playerUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player profile not available')),
        );
      }
      return;
    }

    try {
      final playerRecord = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', playerUserId)
          .maybeSingle();
      if (!mounted) return;
      if (playerRecord == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player profile not found')),
        );
        return;
      }
      final playerId = playerRecord['id'] as String;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoachPlayerDetailPage(playerId: playerId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Contact player ─────────────────────────────────────────────────────────

  Future<void> _contactPlayer(Map<String, dynamic> match) async {
    final coachUserId = _supabase.auth.currentUser?.id;
    if (coachUserId == null) return;

    try {
      final coachData = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', coachUserId)
          .maybeSingle();
      if (coachData == null) return;
      final coachId = coachData['id'] as String;

      final playerUserId = match['player_user_id'] as String;

      // Get the player's players.id (PK), not user_id
      final playerRecord = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', playerUserId)
          .maybeSingle();
      if (playerRecord == null) return;
      final playerId = playerRecord['id'] as String;

      // Check / create conversation
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
        final firstName = match['first_name'] as String? ?? '';
        final lastName = match['last_name'] as String? ?? '';
        final name = '$firstName $lastName'.trim();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailPage(
              conversationId: conversationId,
              otherUserId: playerUserId,
              otherUserName: name,
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
    }
  }
}

// ── Match score legend ────────────────────────────────────────────────────────

class _MatchLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLegend(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.coachColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.coachColor.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                size: 14, color: AppColors.coachColor),
            SizedBox(width: 4),
            Text(
              'How scores work',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.coachColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How Match Scores Work',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _LegendRow(
              emoji: '⚡',
              label: 'Excellent (75–100)',
              desc:
                  'Player\'s position, graduation year, and academics are a near-perfect fit for your blueprint.',
              color: AppColors.coachColor,
            ),
            const SizedBox(height: 12),
            _LegendRow(
              emoji: '✅',
              label: 'Strong (60–74)',
              desc:
                  'Most criteria align well. Could be a great recruit with minor compromises.',
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            _LegendRow(
              emoji: '👍',
              label: 'Good (45–59)',
              desc:
                  'Partial fit — position or timeline may differ, but worth evaluating.',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _LegendRow(
              emoji: '🔎',
              label: 'Possible (0–44)',
              desc:
                  'Low overlap with your current needs, but player is discoverable.',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scores are computed from: Position (35%), Timeline (30%), Academics (20%), Physical (15%)',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String desc;
  final Color color;

  const _LegendRow({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Match Card ────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> player;
  final VoidCallback onViewProfile;
  final VoidCallback onContact;
  final VoidCallback onAddToPipeline;

  const _MatchCard({
    required this.player,
    required this.onViewProfile,
    required this.onContact,
    required this.onAddToPipeline,
  });

  Color get _labelColor {
    switch (player['match_label'] as String?) {
      case 'Excellent':
        return AppColors.coachColor;
      case 'Strong':
        return AppColors.success;
      case 'Good':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = player['first_name'] as String? ?? '';
    final lastName = player['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final position = player['primary_position'] as String? ?? '';
    final secondary = player['secondary_position'] as String? ?? '';
    final gradYear = player['graduation_year'] as int?;
    final gpa = (player['gpa'] as num?)?.toDouble();
    final club = player['club_name'] as String? ?? '';
    final league = player['league'] as String? ?? '';
    final bio = player['bio'] as String? ?? '';
    final score = (player['overall_score'] as num?)?.toDouble() ?? 0;
    final label = player['match_label'] as String? ?? '';
    final posMatched = player['position_matched'] as bool? ?? false;
    final timelineMatched = player['timeline_matched'] as bool? ?? false;

    return GestureDetector(
      onTap: onViewProfile,
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: label == 'Excellent'
              ? AppColors.coachColor.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      _labelColor.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _labelColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Anonymous Player',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (club.isNotEmpty)
                        Text(
                          club,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Score badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _labelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _labelColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _labelColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Tags ────────────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (position.isNotEmpty)
                  _Tag(
                    label: position,
                    color: posMatched
                        ? AppColors.coachColor
                        : AppColors.textSecondary,
                    highlighted: posMatched,
                  ),
                if (secondary.isNotEmpty)
                  _Tag(
                    label: secondary,
                    color: AppColors.textSecondary,
                    highlighted: false,
                  ),
                if (gradYear != null)
                  _Tag(
                    label: 'Class of $gradYear',
                    color: timelineMatched
                        ? AppColors.success
                        : AppColors.textSecondary,
                    highlighted: timelineMatched,
                  ),
                if (gpa != null)
                  _Tag(
                    label: 'GPA ${gpa.toStringAsFixed(1)}',
                    color: AppColors.primary,
                    highlighted: false,
                  ),
                if (league.isNotEmpty)
                  _Tag(
                    label: league,
                    color: AppColors.mentorColor,
                    highlighted: false,
                  ),
              ],
            ),

            // ── Match signals ───────────────────────────────────────────────
            const SizedBox(height: 8),
            Row(
              children: [
                _SignalDot(
                  label: 'Position',
                  matched: posMatched,
                ),
                const SizedBox(width: 12),
                _SignalDot(
                  label: 'Timeline',
                  matched: timelineMatched,
                ),
                if (gpa != null) ...[
                  const SizedBox(width: 12),
                  _SignalDot(
                    label: 'Academics',
                    matched: true, // if GPA is present, it passed the filter
                  ),
                ],
              ],
            ),

            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Action buttons ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onViewProfile,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_chart_outlined, size: 16),
                    label: const Text('Pipeline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onAddToPipeline,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coachColor,
                      side: const BorderSide(color: AppColors.coachColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onContact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool highlighted;

  const _Tag({
    required this.label,
    required this.color,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: highlighted
            ? Border.all(color: color.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SignalDot extends StatelessWidget {
  final String label;
  final bool matched;

  const _SignalDot({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: matched ? AppColors.success : AppColors.border,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                matched ? AppColors.success : AppColors.textSecondary,
            fontWeight:
                matched ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../messaging/presentation/pages/conversation_detail_page.dart';
import 'coach_player_detail_page.dart';

/// Coach's "Search Players" tab — search recruits by position, graduation year,
/// GPA, league, foot preference, and division interest.
class CoachSearchPage extends StatefulWidget {
  const CoachSearchPage({super.key});

  @override
  State<CoachSearchPage> createState() => _CoachSearchPageState();
}

class _CoachSearchPageState extends State<CoachSearchPage> {
  final _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;

  // Filter state
  String? _selectedPosition;
  String? _selectedGradYear;
  String? _selectedGpa;
  String? _selectedFoot;
  String? _selectedLeague;

  List<Map<String, dynamic>> _allResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  List<Map<String, dynamic>> get _results {
    var r = _allResults;
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      r = r.where((p) {
        final user = (p['users'] as Map<String, dynamic>?) ?? {};
        final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.toLowerCase();
        final club = (p['club_name'] as String? ?? '').toLowerCase();
        final league = (p['league'] as String? ?? '').toLowerCase();
        return name.contains(keyword) || club.contains(keyword) || league.contains(keyword);
      }).toList();
    }
    if (_selectedPosition != null) {
      final pos = _selectedPosition!.toUpperCase();
      r = r.where((p) {
        final primary   = (p['primary_position']   as String? ?? '').toUpperCase();
        final secondary = (p['secondary_position'] as String? ?? '').toUpperCase();
        // Also check full positions list as fallback
        final allPositions = (p['positions'] as List? ?? []);
        final anyMatch = allPositions.any((pos2) =>
          (pos2['abbreviation'] as String? ?? '').toUpperCase() == pos);
        return primary == pos || secondary == pos || anyMatch;
      }).toList();
    }
    if (_selectedGradYear != null) {
      r = r.where((p) =>
        p['graduation_year']?.toString() == _selectedGradYear).toList();
    }
    if (_selectedFoot != null) {
      r = r.where((p) =>
        (p['preferred_foot'] as String? ?? '').toLowerCase() ==
        _selectedFoot!.toLowerCase()).toList();
    }
    if (_selectedLeague != null) {
      r = r.where((p) =>
        (p['league'] as String? ?? '').toLowerCase()
        .contains(_selectedLeague!.toLowerCase())).toList();
    }
    if (_selectedGpa != null) {
      r = r.where((p) {
        final gpa = (p['gpa'] as num?)?.toDouble() ?? 0.0;
        return _matchesGpaFilter(gpa, _selectedGpa!);
      }).toList();
    }
    return r;
  }

  static const _positions = [
    'GK', 'CB', 'RB', 'LB', 'CDM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'CF',
  ];
  static const _gradYears = ['2025', '2026', '2027', '2028', '2029', '2030'];
  static const _gpaRanges = ['3.9+', '3.5–3.9', '3.0–3.5', '2.5–3.0', 'Below 2.5'];
  static const _footOptions = ['Right', 'Left', 'Both'];
  static const _leagues = [
    'ECNL', 'GA', 'MLS Next', 'USYS', 'National League', 'Regional League', 'State League',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Fetch players, leagues, clubs, and player positions in parallel
      final fetched = await Future.wait([
        _supabase.from('players').select('''
          id, user_id, graduation_year, gpa, dominant_foot,
          height_cm, league_id, bio, target_division,
          clubs(name)
        ''').order('graduation_year', ascending: true).limit(200),
        _supabase.from('leagues').select('id, name'),
        _supabase.from('player_positions').select(
          'player_id, is_primary, positions(abbreviation, position_type)',
        ),
      ]);

      final players = List<Map<String, dynamic>>.from(fetched[0] as List);
      if (players.isEmpty) {
        if (mounted) setState(() { _allResults = []; _isLoading = false; });
        return;
      }

      // League ID → name map
      final leagueMap = <String, String>{
        for (final l in (fetched[1] as List))
          (l['id'] as String): (l['name'] as String),
      };

      // Player ID → positions list [{abbreviation, is_primary}]
      final posMap = <String, List<Map<String, dynamic>>>{};
      for (final pp in (fetched[2] as List)) {
        final pid = pp['player_id'] as String;
        final pos = (pp['positions'] as Map<String, dynamic>?) ?? {};
        posMap.putIfAbsent(pid, () => []).add({
          'abbreviation': pos['abbreviation'] as String? ?? '',
          'position_type': pos['position_type'] as String? ?? '',
          'is_primary': pp['is_primary'] as bool? ?? false,
        });
      }

      // User ID → name map
      final userIds = players.map((p) => p['user_id'] as String).toSet().toList();
      final userData = await _supabase
          .from('users').select('id, first_name, last_name')
          .inFilter('id', userIds);
      final userMap = <String, Map<String, dynamic>>{
        for (final u in (userData as List))
          (u['id'] as String): u as Map<String, dynamic>,
      };

      // Merge everything into player records
      final merged = players.map((p) {
        final pid      = p['id'] as String;
        final userId   = p['user_id'] as String? ?? '';
        final leagueId = p['league_id'] as String? ?? '';
        final positions = posMap[pid] ?? [];
        final primary   = positions.where((x) => x['is_primary'] == true).firstOrNull;
        final secondary = positions.where((x) => x['is_primary'] == false).firstOrNull;
        final clubData  = p['clubs'] as Map<String, dynamic>?;
        return {
          ...p,
          'users':             userMap[userId] ?? {},
          'league':            leagueMap[leagueId] ?? '',
          'club_name':         clubData?['name'] as String? ?? '',
          'positions':         positions,
          'primary_position':  (primary?['abbreviation']   ?? '').toString().toUpperCase(),
          'secondary_position':(secondary?['abbreviation'] ?? '').toString().toUpperCase(),
          'preferred_foot':    p['dominant_foot'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allResults = merged;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Search failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  bool _matchesGpaFilter(double gpa, String filter) {
    switch (filter) {
      case '3.9+':
        return gpa >= 3.9;
      case '3.5–3.9':
        return gpa >= 3.5 && gpa < 3.9;
      case '3.0–3.5':
        return gpa >= 3.0 && gpa < 3.5;
      case '2.5–3.0':
        return gpa >= 2.5 && gpa < 3.0;
      case 'Below 2.5':
        return gpa < 2.5;
      default:
        return true;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedPosition = null;
      _selectedGradYear = null;
      _selectedGpa = null;
      _selectedFoot = null;
      _selectedLeague = null;
      _searchController.clear();
      _allResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, club, or league…',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18,
                            color: AppColors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coachColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _search,
            child: const Text('Search',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final hasFilters = _selectedPosition != null ||
        _selectedGradYear != null ||
        _selectedGpa != null ||
        _selectedFoot != null ||
        _selectedLeague != null;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: _selectedPosition ?? 'Position',
              isActive: _selectedPosition != null,
              activeColor: AppColors.coachColor,
              onTap: () => _showPickerSheet(
                title: 'Select Position',
                options: _positions,
                selected: _selectedPosition,
                onSelect: (v) => setState(
                    () => _selectedPosition = v == _selectedPosition ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: _selectedGradYear ?? 'Grad Year',
              isActive: _selectedGradYear != null,
              activeColor: AppColors.coachColor,
              onTap: () => _showPickerSheet(
                title: 'Graduation Year',
                options: _gradYears,
                selected: _selectedGradYear,
                onSelect: (v) => setState(
                    () => _selectedGradYear = v == _selectedGradYear ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: _selectedGpa ?? 'GPA',
              isActive: _selectedGpa != null,
              activeColor: AppColors.coachColor,
              onTap: () => _showPickerSheet(
                title: 'GPA Range',
                options: _gpaRanges,
                selected: _selectedGpa,
                onSelect: (v) =>
                    setState(() => _selectedGpa = v == _selectedGpa ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: _selectedFoot ?? 'Foot',
              isActive: _selectedFoot != null,
              activeColor: AppColors.coachColor,
              onTap: () => _showPickerSheet(
                title: 'Preferred Foot',
                options: _footOptions,
                selected: _selectedFoot,
                onSelect: (v) =>
                    setState(() => _selectedFoot = v == _selectedFoot ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: _selectedLeague ?? 'League',
              isActive: _selectedLeague != null,
              activeColor: AppColors.coachColor,
              onTap: () => _showPickerSheet(
                title: 'League',
                options: _leagues,
                selected: _selectedLeague,
                onSelect: (v) => setState(
                    () => _selectedLeague = v == _selectedLeague ? null : v),
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coachColor),
      );
    }

    if (!_hasSearched) {
      return _buildLanding();
    }

    if (_results.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_results.length} player${_results.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _results.length,
            itemBuilder: (context, index) => _PlayerCard(
              player: _results[index],
              onViewProfile: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CoachPlayerDetailPage(
                    playerId: _results[index]['id'] as String,
                  ),
                ),
              ),
              onContact: () => _contactPlayer(_results[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanding() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Recruits',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search the Lanista database for players that match your program\'s needs. Filter by position, graduation year, academics, and more.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickSearchChip(
                label: '2026 Goalkeepers',
                onTap: () {
                  setState(() {
                    _selectedPosition = 'GK';
                    _selectedGradYear = '2026';
                  });
                  _search();
                },
              ),
              _QuickSearchChip(
                label: '3.5+ GPA Strikers',
                onTap: () {
                  setState(() {
                    _selectedPosition = 'ST';
                    _selectedGpa = '3.5–3.9';
                  });
                  _search();
                },
              ),
              _QuickSearchChip(
                label: 'ECNL Midfielders',
                onTap: () {
                  setState(() {
                    _selectedPosition = 'CM';
                    _selectedLeague = 'ECNL';
                  });
                  _search();
                },
              ),
              _QuickSearchChip(
                label: 'Left-footed Wingers',
                onTap: () {
                  setState(() {
                    _selectedPosition = 'LW';
                    _selectedFoot = 'Left';
                  });
                  _search();
                },
              ),
              _QuickSearchChip(
                label: '2027 Class',
                onTap: () {
                  setState(() => _selectedGradYear = '2027');
                  _search();
                },
              ),
              _QuickSearchChip(
                label: 'MLS Next Defenders',
                onTap: () {
                  setState(() {
                    _selectedPosition = 'CB';
                    _selectedLeague = 'MLS Next';
                  });
                  _search();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coachColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.coachColor.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚖️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NCAA Compliance Reminder',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contact window rules are enforced automatically. You may view player profiles at any time, but messaging is restricted until contact periods open.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            const Text('👤', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'No players found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try broadening your filters or search by a different criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contact player ───────────────────────────────────────────────────────────

  Future<void> _contactPlayer(Map<String, dynamic> player) async {
    final coachUserId = _supabase.auth.currentUser?.id;
    if (coachUserId == null) return;

    try {
      // Get coach record
      final coachData = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', coachUserId)
          .maybeSingle();
      if (coachData == null) return;
      final coachId = coachData['id'] as String;

      final playerUserId = (player['users'] as Map<String, dynamic>?)?['id'] as String?
          ?? player['user_id'] as String;

      // Get the player's players.id (PK), not user_id
      final playerRecord = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', playerUserId)
          .maybeSingle();
      if (playerRecord == null) return;
      final playerId = playerRecord['id'] as String;

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
        final playerUser = (player['users'] as Map<String, dynamic>?) ?? {};
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
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showPickerSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options[i];
                  final isSelected = opt == selected;
                  return ListTile(
                    title: Text(opt),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.coachColor)
                        : null,
                    onTap: () {
                      onSelect(opt);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-Widgets ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.close : Icons.keyboard_arrow_down,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSearchChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
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
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Map<String, dynamic> player;
  final VoidCallback onContact;
  final VoidCallback onViewProfile;

  const _PlayerCard({
    required this.player,
    required this.onContact,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final user = (player['users'] as Map<String, dynamic>?) ?? {};
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final position = player['primary_position'] as String? ?? '';
    final secondary = player['secondary_position'] as String? ?? '';
    final gradYear = player['graduation_year'] as int?;
    final gpa = (player['gpa'] as num?)?.toDouble();
    final foot = player['preferred_foot'] as String? ?? '';
    final club = player['club_name'] as String? ?? '';
    final league = player['league'] as String? ?? '';
    final bio = player['bio'] as String? ?? '';

    return GestureDetector(
      onTap: onViewProfile,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
            Row(
              children: [
                // Player avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
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
                      const SizedBox(height: 2),
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
                if (gradYear != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\'${gradYear.toString().substring(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (position.isNotEmpty)
                  _Tag(label: position, color: AppColors.primary),
                if (secondary.isNotEmpty)
                  _Tag(label: secondary, color: AppColors.primary.withValues(alpha: 0.6)),
                if (foot.isNotEmpty)
                  _Tag(label: foot == 'Right' ? '🦵R' : foot == 'Left' ? '🦵L' : '🦵Both', color: AppColors.textSecondary),
                if (gpa != null)
                  _Tag(label: 'GPA ${gpa.toStringAsFixed(1)}', color: AppColors.success),
                if (league.isNotEmpty)
                  _Tag(label: league, color: AppColors.mentorColor),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('View Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coachColor,
                      side: const BorderSide(color: AppColors.coachColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onViewProfile,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coachColor,
                      foregroundColor: Colors.white,
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

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../messaging/presentation/pages/conversation_detail_page.dart';

/// Player's "Search Programs" tab — search college programs by division,
/// formation, location, and recruiting status.
class PlayerSearchPage extends StatefulWidget {
  const PlayerSearchPage({super.key});

  @override
  State<PlayerSearchPage> createState() => _PlayerSearchPageState();
}

class _PlayerSearchPageState extends State<PlayerSearchPage> {
  final _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;

  // Filter state
  String? _selectedDivision;
  String? _selectedFormation;
  String? _selectedState;
  bool _recruitingOnly = false;

  // _allResults holds the raw Supabase fetch; _filteredResults is derived live
  List<Map<String, dynamic>> _allResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  List<Map<String, dynamic>> get _results {
    var r = _allResults;
    if (_selectedDivision != null) {
      r = r.where((c) => c['division'] == _selectedDivision).toList();
    }
    if (_selectedFormation != null) {
      r = r.where((c) => c['primary_formation'] == _selectedFormation).toList();
    }
    if (_selectedState != null) {
      r = r.where((c) => c['state'] == _selectedState).toList();
    }
    if (_recruitingOnly) {
      r = r.where((c) {
        final slots = c['roster_slots'] as List? ?? [];
        return slots.any((s) => s['needs_recruit'] == true);
      }).toList();
    }
    return r;
  }

  static const _divisions = ['D1', 'D2', 'D3', 'NAIA', 'NJCAA'];
  static const _formations = [
    '4-3-3', '4-2-3-1', '3-4-3', '4-4-2', '3-5-2',
    '4-5-1', '4-3-2-1', '4-1-4-1', '5-3-2', '3-1-3-3',
    '4-1-2-3', '4-2-2-2', '4-3-1-2', '5-2-1-2', '5-2-3', '5-2-2-1',
  ];
  static const _states = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches all matching coaches from Supabase and stores in [_allResults].
  /// Filters are applied live via the [_results] getter — no re-fetch needed
  /// when the user changes division/formation/state/recruiting toggles.
  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      var query = _supabase
          .from('coaches')
          .select('''
            id,
            school_name,
            division,
            state,
            primary_formation,
            playing_style,
            is_published,
            users!inner(first_name, last_name),
            roster_slots(needs_recruit)
          ''')
          .eq('is_published', true);

      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) {
        query = query.ilike('school_name', '%$keyword%');
      }

      final data = await query.order('school_name', ascending: true);

      if (mounted) {
        setState(() {
          _allResults = List<Map<String, dynamic>>.from(data as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDivision = null;
      _selectedFormation = null;
      _selectedState = null;
      _recruitingOnly = false;
      _searchController.clear();
      _allResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return Column(
      children: [
        _buildSearchBar(isDark),
        _buildFilterRow(isDark),
        Expanded(child: _buildBody(isDark)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      color: isDark ? PlayerColors.surface : AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search programs (e.g. "Stanford", "Georgetown")',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
                ),
                filled: true,
                fillColor: isDark
                    ? PlayerColors.surfaceVariant
                    : AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? PlayerColors.border : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? PlayerColors.accent : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
              foregroundColor:
                  isDark ? PlayerColors.textOnAccent : Colors.white,
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

  Widget _buildFilterRow(bool isDark) {
    final hasFilters = _selectedDivision != null ||
        _selectedFormation != null ||
        _selectedState != null ||
        _recruitingOnly;

    return Container(
      color: isDark ? PlayerColors.surface : AppColors.surface,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Division filter
                _FilterChip(
                  label: _selectedDivision ?? 'Division',
                  isActive: _selectedDivision != null,
                  onTap: () => _showPickerSheet(
                    title: 'Select Division',
                    options: _divisions,
                    selected: _selectedDivision,
                    onSelect: (v) => setState(
                        () => _selectedDivision =
                            v == _selectedDivision ? null : v),
                  ),
                ),
                const SizedBox(width: 8),
                // Formation filter
                _FilterChip(
                  label: _selectedFormation ?? 'Formation',
                  isActive: _selectedFormation != null,
                  onTap: () => _showPickerSheet(
                    title: 'Select Formation',
                    options: _formations,
                    selected: _selectedFormation,
                    onSelect: (v) => setState(
                        () => _selectedFormation =
                            v == _selectedFormation ? null : v),
                  ),
                ),
                const SizedBox(width: 8),
                // State filter
                _FilterChip(
                  label: _selectedState ?? 'State',
                  isActive: _selectedState != null,
                  onTap: () => _showPickerSheet(
                    title: 'Select State',
                    options: _states,
                    selected: _selectedState,
                    onSelect: (v) => setState(
                        () =>
                            _selectedState = v == _selectedState ? null : v),
                  ),
                ),
                const SizedBox(width: 8),
                // Recruiting toggle
                GestureDetector(
                  onTap: () =>
                      setState(() => _recruitingOnly = !_recruitingOnly),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _recruitingOnly
                          ? (isDark ? PlayerColors.accent : AppColors.primary)
                          : (isDark
                              ? PlayerColors.surfaceVariant
                              : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: _recruitingOnly
                              ? (isDark
                                  ? PlayerColors.textOnAccent
                                  : Colors.white)
                              : (isDark
                                  ? PlayerColors.textSecondary
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Recruiting Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _recruitingOnly
                                ? (isDark
                                    ? PlayerColors.textOnAccent
                                    : Colors.white)
                                : (isDark
                                    ? PlayerColors.textSecondary
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
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
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? PlayerColors.accent : AppColors.primary,
        ),
      );
    }

    if (!_hasSearched) {
      return _buildLanding(isDark);
    }

    if (_results.isEmpty) {
      return _buildEmpty(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) => _ProgramCard(
        program: _results[index],
        onMessage: () => _startConversation(_results[index]),
        onViewProgram: () => _showProgramProfile(_results[index]),
      ),
    );
  }

  Widget _buildLanding(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Program',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search across hundreds of college soccer programs. Filter by division, formation style, and state.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? PlayerColors.textSecondary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Browse by Division',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _divisions
                .map(
                  (d) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedDivision = d);
                      _search();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? PlayerColors.accentSubtle
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? PlayerColors.borderAccent
                              : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? PlayerColors.accent
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Browse by Formation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formations
                .map(
                  (f) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedFormation = f);
                      _search();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? PlayerColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? PlayerColors.border
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? PlayerColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No programs found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search with a different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? PlayerColors.textSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? PlayerColors.accent : AppColors.primary,
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Conversation start ───────────────────────────────────────────────────────

  Future<void> _startConversation(Map<String, dynamic> program) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Resolve players.id from auth uid (conversations.player_id references players.id)
      final playerRow = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (playerRow == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complete your player profile first')),
          );
        }
        return;
      }
      final playerId = playerRow['id'] as String;

      // Check or create conversation
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('player_id', playerId)
          .eq('coach_id', program['id'] as String)
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
        // Re-open contact window if it was closed
        await _supabase
            .from('conversations')
            .update({'contact_window_valid': true})
            .eq('id', conversationId);
      } else {
        final created = await _supabase
            .from('conversations')
            .insert({
              'player_id': playerId,
              'coach_id': program['id'] as String,
              'initiated_by': 'player',
            })
            .select('id')
            .single();
        conversationId = created['id'] as String;
      }

      if (mounted) {
        final coachUser =
            (program['users'] as Map<String, dynamic>?) ?? {};
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailPage(
              conversationId: conversationId,
              otherUserId: program['id'] as String,
              otherUserName:
                  'Coach ${coachUser['first_name'] ?? ''} ${coachUser['last_name'] ?? ''}'
                      .trim(),
              otherUserRole: 'coach',
              isDark: PlayerThemeScope.isDark(context),
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

  // ── Program profile sheet ────────────────────────────────────────────────────

  void _showProgramProfile(Map<String, dynamic> program) {
    final isDark = PlayerThemeScope.isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProgramProfileSheet(
        program: program,
        isDark: isDark,
        onMessage: () {
          Navigator.pop(ctx);
          _startConversation(program);
        },
      ),
    );
  }

  // ── Filter picker sheet ──────────────────────────────────────────────────────

  void _showPickerSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    final isDark = PlayerThemeScope.isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? PlayerColors.surfaceElevated : Colors.white,
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
                color: isDark ? PlayerColors.border : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? PlayerColors.textPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options[i];
                  final isSelected = opt == selected;
                  return ListTile(
                    title: Text(
                      opt,
                      style: TextStyle(
                        color: isDark
                            ? PlayerColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            color: isDark
                                ? PlayerColors.accent
                                : AppColors.primary,
                          )
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
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? PlayerColors.accent : AppColors.primary)
              : (isDark
                  ? PlayerColors.surfaceVariant
                  : AppColors.surfaceVariant),
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
                color: isActive
                    ? (isDark ? PlayerColors.textOnAccent : Colors.white)
                    : (isDark
                        ? PlayerColors.textSecondary
                        : AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.close : Icons.keyboard_arrow_down,
              size: 14,
              color: isActive
                  ? (isDark ? PlayerColors.textOnAccent : Colors.white)
                  : (isDark
                      ? PlayerColors.textSecondary
                      : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final VoidCallback onMessage;
  final VoidCallback onViewProgram;

  const _ProgramCard({
    required this.program,
    required this.onMessage,
    required this.onViewProgram,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final coachUser =
        (program['users'] as Map<String, dynamic>?) ?? {};
    final coachName =
        'Coach ${coachUser['first_name'] ?? ''} ${coachUser['last_name'] ?? ''}'
            .trim();
    final schoolName = program['school_name'] as String? ?? 'Unknown';
    final division = program['division'] as String? ?? '';
    final state = program['state'] as String? ?? '';
    final formation = program['primary_formation'] as String? ?? '';
    final style = program['playing_style'] as String? ?? '';
    final slots = (program['roster_slots'] as List?) ?? [];
    final needsRecruit = slots.any((s) => s['needs_recruit'] == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? PlayerColors.border : AppColors.border,
        ),
        boxShadow: isDark
            ? null
            : [
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
                // School initial avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? PlayerColors.gradientStart.withValues(alpha: 0.15)
                        : AppColors.coachColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      schoolName.isNotEmpty ? schoolName[0] : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? PlayerColors.gradientStart
                            : AppColors.coachColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? PlayerColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coachName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? PlayerColors.textSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (needsRecruit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? PlayerColors.success : AppColors.success)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Recruiting',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? PlayerColors.success : AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (division.isNotEmpty)
                  _Tag(
                    label: division,
                    color: isDark ? PlayerColors.info : AppColors.coachColor,
                  ),
                if (formation.isNotEmpty)
                  _Tag(
                    label: formation,
                    color: isDark ? PlayerColors.accent : AppColors.primary,
                  ),
                if (state.isNotEmpty)
                  _Tag(
                    label: '📍 $state',
                    color: isDark
                        ? PlayerColors.textSecondary
                        : AppColors.textSecondary,
                  ),
                if (style.isNotEmpty)
                  _Tag(
                    label: style,
                    color:
                        isDark ? PlayerColors.warning : AppColors.mentorColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.school_outlined, size: 16),
                    label: const Text('View Program'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? PlayerColors.textSecondary
                          : AppColors.textSecondary,
                      side: BorderSide(
                        color: isDark
                            ? PlayerColors.border
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onViewProgram,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? PlayerColors.accent
                          : AppColors.primary,
                      foregroundColor: isDark
                          ? PlayerColors.textOnAccent
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Program Profile Sheet ─────────────────────────────────────────────────────

class _ProgramProfileSheet extends StatelessWidget {
  final Map<String, dynamic> program;
  final bool isDark;
  final VoidCallback onMessage;

  const _ProgramProfileSheet({
    required this.program,
    required this.isDark,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final coachUser = (program['users'] as Map<String, dynamic>?) ?? {};
    final coachName =
        '${coachUser['first_name'] ?? ''} ${coachUser['last_name'] ?? ''}'.trim();
    final schoolName = program['school_name'] as String? ?? 'Unknown';
    final division = program['division'] as String? ?? '';
    final state = program['state'] as String? ?? '';
    final formation = program['primary_formation'] as String? ?? '';
    final style = program['playing_style'] as String? ?? '';
    final slots = (program['roster_slots'] as List?) ?? [];
    final needsRecruit = slots.any((s) => s['needs_recruit'] == true);
    final bg = isDark ? PlayerColors.surfaceElevated : Colors.white;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewPadding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? PlayerColors.border : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // School avatar + name
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? PlayerColors.gradientStart.withValues(alpha: 0.15)
                        : AppColors.coachColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      schoolName.isNotEmpty ? schoolName[0] : '?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? PlayerColors.gradientStart : AppColors.coachColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Head Coach $coachName',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (needsRecruit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Recruiting',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? PlayerColors.success : AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Info rows
            _InfoRow(label: 'Division', value: division.isNotEmpty ? division : '—', isDark: isDark),
            _InfoRow(label: 'State', value: state.isNotEmpty ? state : '—', isDark: isDark),
            _InfoRow(label: 'Formation', value: formation.isNotEmpty ? formation : '—', isDark: isDark),
            if (style.isNotEmpty)
              _InfoRow(label: 'Style', value: style, isDark: isDark),

            const SizedBox(height: 20),

            // Message button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Message Coach'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
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
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

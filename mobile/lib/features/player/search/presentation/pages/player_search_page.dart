import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
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

  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  static const _divisions = ['D1', 'D2', 'D3', 'NAIA', 'NJCAA'];
  static const _formations = ['4-3-3', '4-2-3-1', '3-4-3', '4-4-2', '3-5-2'];
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

      if (_selectedDivision != null) {
        query = query.eq('division', _selectedDivision!);
      }
      if (_selectedFormation != null) {
        query = query.eq('primary_formation', _selectedFormation!);
      }
      if (_selectedState != null) {
        query = query.eq('state', _selectedState!);
      }

      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) {
        query = query.ilike('school_name', '%$keyword%');
      }

      final data = await query.order('school_name', ascending: true);

      List<Map<String, dynamic>> results =
          List<Map<String, dynamic>>.from(data as List);

      // Filter by recruiting need if toggled (needs at least one slot needing recruit)
      if (_recruitingOnly) {
        results = results.where((coach) {
          final slots = coach['roster_slots'] as List? ?? [];
          return slots.any((s) => s['needs_recruit'] == true);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: AppColors.error),
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
      _results = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterRow(),
        Expanded(child: _buildBody()),
      ],
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
                hintText: 'Search programs (e.g. "Stanford", "Georgetown")',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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
    final hasFilters = _selectedDivision != null ||
        _selectedFormation != null ||
        _selectedState != null ||
        _recruitingOnly;

    return Container(
      color: AppColors.surface,
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
                    onSelect: (v) =>
                        setState(() => _selectedDivision = v == _selectedDivision ? null : v),
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
                    onSelect: (v) =>
                        setState(() => _selectedFormation = v == _selectedFormation ? null : v),
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
                    onSelect: (v) =>
                        setState(() => _selectedState = v == _selectedState ? null : v),
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
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: _recruitingOnly
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Recruiting Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _recruitingOnly
                                ? Colors.white
                                : AppColors.textSecondary,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (!_hasSearched) {
      return _buildLanding();
    }

    if (_results.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) => _ProgramCard(
        program: _results[index],
        onMessage: () => _startConversation(_results[index]),
      ),
    );
  }

  Widget _buildLanding() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Program',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search across hundreds of college soccer programs. Filter by division, formation style, and state.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Browse by Division',
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
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Browse by Formation',
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'No programs found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search with a different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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

  // ── Conversation start ───────────────────────────────────────────────────────

  Future<void> _startConversation(Map<String, dynamic> program) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Check or create conversation
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('player_id', userId)
          .eq('coach_id', program['id'] as String)
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
      } else {
        final created = await _supabase
            .from('conversations')
            .insert({
              'player_id': userId,
              'coach_id': program['id'] as String,
              'contact_window_open': true,
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

  // ── Filter sheet ─────────────────────────────────────────────────────────────

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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
                    title: Text(opt),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
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

// ── Shared Sub-Widgets ────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
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

class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final VoidCallback onMessage;

  const _ProgramCard({required this.program, required this.onMessage});

  @override
  Widget build(BuildContext context) {
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
                // School initial avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.coachColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      schoolName.isNotEmpty ? schoolName[0] : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coachColor,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coachName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Recruiting',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
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
                if (division.isNotEmpty) _Tag(label: division, color: AppColors.coachColor),
                if (formation.isNotEmpty) _Tag(label: formation, color: AppColors.primary),
                if (state.isNotEmpty) _Tag(label: '📍 $state', color: AppColors.textSecondary),
                if (style.isNotEmpty) _Tag(label: style, color: AppColors.mentorColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message Coach'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../tactical_blueprint/data/tactical_blueprint_data.dart';

class CoachRosterMapPage extends StatefulWidget {
  const CoachRosterMapPage({super.key});

  @override
  State<CoachRosterMapPage> createState() => _CoachRosterMapPageState();
}

class _CoachRosterMapPageState extends State<CoachRosterMapPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  String _formation = '4-3-3';

  // Map of "positionKey_year" -> list of player slots (depth chart)
  // e.g. { 'gk_2026': [ {slot_status, player_name, depth_order}, ... ] }
  Map<String, List<Map<String, dynamic>>> _slots = {};

  // The coaches.id PK (NOT the auth user id)
  String? _coachId;

  // Scraped roster import
  int _scrapedPlayerCount = 0;   // > 0 means import is available
  bool _importLoading = false;

  late int _selectedYear;

  final List<int> _years = TacticalBlueprintData.recruitingYears
      .map((y) => int.parse(y))
      .toList();

  static const int _maxDepth = 4; // NCAA: cap at 4 per position per year

  @override
  void initState() {
    super.initState();
    _selectedYear = _years.first;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Load coach record (need coaches.id for roster_slots FK)
      final coachData = await _supabase
          .from('coaches')
          .select('id, primary_formation')
          .eq('user_id', userId)
          .maybeSingle();

      final coachId = coachData?['id'] as String?;
      if (coachId == null) {
        // Coach hasn't completed onboarding yet — show empty state gracefully
        if (mounted) setState(() => _loading = false);
        return;
      }
      _coachId = coachId;

      final formation = coachData?['primary_formation'] as String?;
      if (formation != null && formation.isNotEmpty) {
        _formation = formation;
      }

      // Load all roster slots for this coach, ordered by depth
      final slotsData = await _supabase
          .from('roster_slots')
          .select('position_key, graduation_year, slot_status, player_name, depth_order, is_injured, injury_return_date')
          .eq('coach_id', coachId)
          .order('depth_order', ascending: true);

      final Map<String, List<Map<String, dynamic>>> slots = {};
      for (final row in slotsData as List<dynamic>) {
        final posKey = row['position_key'] as String?;
        final gradYear = row['graduation_year'];
        if (posKey == null || gradYear == null) continue;
        final key = '${posKey}_$gradYear';
        slots.putIfAbsent(key, () => []);
        slots[key]!.add({
          'slot_status': row['slot_status'] as String? ?? 'unknown',
          'player_name': row['player_name'] as String?,
          'depth_order': row['depth_order'] as int? ?? 1,
          'is_injured': row['is_injured'] as bool? ?? false,
          'injury_return_date': row['injury_return_date'] as String?,
        });
      }

      // Check if scraped roster data is available for import
      final scrapedCount = await _supabase
          .from('college_roster_players')
          .select('id')
          .eq('coach_id', coachId)
          .eq('season_year', 2025)
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          _slots = slots;
          _scrapedPlayerCount = scrapedCount.count;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _importScrapedRoster() async {
    if (_coachId == null || _importLoading) return;
    setState(() => _importLoading = true);
    try {
      final result = await _supabase.rpc(
        'preload_roster_from_scraped',
        params: {'p_coach_id': _coachId, 'p_season_year': 2025},
      );
      final inserted = result as int? ?? 0;
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inserted > 0
                  ? '$inserted players imported from your 2025 roster.'
                  : 'Roster already up to date — no new players added.',
            ),
            backgroundColor: AppColors.coachColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  List<BlueprintPosition> get _currentPositions {
    final formationInfo = TacticalBlueprintData.formations
        .firstWhere((f) => f.id == _formation,
            orElse: () => TacticalBlueprintData.formations.first);
    return formationInfo.positions;
  }

  List<Map<String, dynamic>> _slotsFor(String positionKey) {
    return _slots['${positionKey}_$_selectedYear'] ?? [];
  }

  // Upsert a single player slot row
  Future<void> _upsertPlayer(
      String positionKey, int depthOrder, String slotStatus, String? playerName,
      {bool isInjured = false, String? injuryReturnDate}) async {
    if (_coachId == null) return;
    final key = '${positionKey}_$_selectedYear';

    // Optimistic update
    setState(() {
      final list = List<Map<String, dynamic>>.from(_slots[key] ?? []);
      final idx = list.indexWhere((s) => s['depth_order'] == depthOrder);
      final entry = {
        'slot_status': slotStatus,
        'player_name': playerName,
        'depth_order': depthOrder,
        'is_injured': isInjured,
        'injury_return_date': injuryReturnDate,
      };
      if (idx >= 0) {
        list[idx] = entry;
      } else {
        list.add(entry);
        list.sort((a, b) => (a['depth_order'] as int).compareTo(b['depth_order'] as int));
      }
      _slots[key] = list;
    });

    try {
      await _supabase.from('roster_slots').upsert({
        'coach_id': _coachId,
        'position_key': positionKey,
        'graduation_year': _selectedYear,
        'depth_order': depthOrder,
        'slot_status': slotStatus,
        'player_name': playerName,
        'is_injured': isInjured,
        'injury_return_date': injuryReturnDate,
      }, onConflict: 'coach_id,position_key,graduation_year,depth_order');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
        await _loadData();
      }
    }
  }

  // Delete a single player slot row
  Future<void> _deletePlayer(String positionKey, int depthOrder) async {
    if (_coachId == null) return;
    final key = '${positionKey}_$_selectedYear';

    // Optimistic update
    setState(() {
      final list = List<Map<String, dynamic>>.from(_slots[key] ?? []);
      list.removeWhere((s) => s['depth_order'] == depthOrder);
      _slots[key] = list;
    });

    try {
      await _supabase
          .from('roster_slots')
          .delete()
          .eq('coach_id', _coachId!)
          .eq('position_key', positionKey)
          .eq('graduation_year', _selectedYear)
          .eq('depth_order', depthOrder);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
        await _loadData();
      }
    }
  }

  String _shortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0];
    return '${parts[0][0]}. ${parts.last}';
  }

  /// Swap two players' depth_order values for the same position + year.
  /// Uses a temporary depth (999) to avoid the unique-constraint conflict
  /// while the swap is in progress.
  Future<void> _swapPlayerDepth(
      String positionKey, int depthA, int depthB) async {
    if (_coachId == null) return;
    final key = '${positionKey}_$_selectedYear';

    // Optimistic local swap first
    setState(() {
      final list = List<Map<String, dynamic>>.from(_slots[key] ?? []);
      final idxA = list.indexWhere((s) => s['depth_order'] == depthA);
      final idxB = list.indexWhere((s) => s['depth_order'] == depthB);
      if (idxA >= 0 && idxB >= 0) {
        list[idxA] = {...list[idxA], 'depth_order': depthB};
        list[idxB] = {...list[idxB], 'depth_order': depthA};
        list.sort((a, b) =>
            (a['depth_order'] as int).compareTo(b['depth_order'] as int));
      }
      _slots[key] = list;
    });

    try {
      const tempDepth = 999; // safe placeholder outside normal 1–4 range

      // Step 1: move A to temp slot (avoids constraint violation)
      await _supabase
          .from('roster_slots')
          .update({'depth_order': tempDepth})
          .eq('coach_id', _coachId!)
          .eq('position_key', positionKey)
          .eq('graduation_year', _selectedYear)
          .eq('depth_order', depthA);

      // Step 2: move B into A's former slot
      await _supabase
          .from('roster_slots')
          .update({'depth_order': depthA})
          .eq('coach_id', _coachId!)
          .eq('position_key', positionKey)
          .eq('graduation_year', _selectedYear)
          .eq('depth_order', depthB);

      // Step 3: move temp into B's former slot
      await _supabase
          .from('roster_slots')
          .update({'depth_order': depthB})
          .eq('coach_id', _coachId!)
          .eq('position_key', positionKey)
          .eq('graduation_year', _selectedYear)
          .eq('depth_order', tempDepth);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to reorder: $e'),
              backgroundColor: AppColors.error),
        );
        await _loadData(); // roll back optimistic update on error
      }
    }
  }

  // Show the depth chart sheet for a position
  void _showDepthChartSheet(BlueprintPosition position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DepthChartSheet(
        position: position,
        year: _selectedYear,
        slots: _slotsFor(position.positionId),
        maxDepth: _maxDepth,
        onUpsert: (depthOrder, status, name, isInjured, injuryReturnDate) =>
            _upsertPlayer(position.positionId, depthOrder, status, name,
                isInjured: isInjured, injuryReturnDate: injuryReturnDate),
        onDelete: (depthOrder) =>
            _deletePlayer(position.positionId, depthOrder),
        onSwap: (depthA, depthB) =>
            _swapPlayerDepth(position.positionId, depthA, depthB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.coachColor));
    if (_error != null) return _buildError();
    if (_coachId == null) return _buildSetupPrompt();
    return Column(
      children: [
        _buildYearTabs(),
        Expanded(child: _buildFormationField()),
      ],
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Set up your Tactical Blueprint first',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your coach profile to unlock the Roster Map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coachColor, foregroundColor: Colors.white),
              onPressed: _loadData,
              child: const Text('Retry'),
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildYearTabs() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Roster Map',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coachColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formation,
                  style: const TextStyle(
                    color: AppColors.coachColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Builder(builder: (context) {
                // Count total players and gaps for selected year
                int totalPlayers = 0;
                int gaps = 0;
                const needsRecruitStatuses = {'graduating', 'portal_risk', 'open'};
                for (final pos in _currentPositions) {
                  final playerList = _slotsFor(pos.positionId);
                  totalPlayers += playerList.length;
                  for (final s in playerList) {
                    if (needsRecruitStatuses.contains(s['slot_status'])) gaps++;
                  }
                }
                return gaps > 0
                    ? Text(
                        '$totalPlayers players · $gaps gap${gaps > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      )
                    : Text(
                        '$totalPlayers players',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      );
              }),
            ],
          ),
          if (_scrapedPlayerCount > 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _importLoading ? null : _importScrapedRoster,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.coachColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.coachColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    if (_importLoading)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coachColor),
                      )
                    else
                      const Icon(Icons.download_rounded, size: 18, color: AppColors.coachColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _importLoading
                            ? 'Importing players…'
                            : 'Import $_scrapedPlayerCount players from your 2025 roster',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.coachColor,
                        ),
                      ),
                    ),
                    if (!_importLoading)
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.coachColor),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _years.map((year) {
                final isSelected = year == _selectedYear;
                int totalPlayers = 0;
                int gaps = 0;
                const needsRecruitStatuses = {'graduating', 'portal_risk', 'open'};
                for (final pos in _currentPositions) {
                  final playerList = _slots['${pos.positionId}_$year'] ?? [];
                  totalPlayers += playerList.length;
                  for (final s in playerList) {
                    if (needsRecruitStatuses.contains(s['slot_status'])) gaps++;
                  }
                }
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.coachColor : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.coachColor : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$year',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          gaps > 0
                              ? '$gaps gap${gaps > 1 ? 's' : ''}'
                              : '$totalPlayers player${totalPlayers != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white70
                                : gaps > 0
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationField() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 0.65,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  return Stack(
                    children: [
                      _buildFieldBackground(width, height),
                      ..._currentPositions.map((pos) {
                        return _buildPositionMarker(pos, width, height);
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldBackground(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(painter: _FieldMarkingsPainter()),
    );
  }

  Widget _buildPositionMarker(BlueprintPosition pos, double width, double height) {
    final playerList = _slotsFor(pos.positionId);
    final count = playerList.length;

    // Starter = depth_order 1
    final starter = playerList.isNotEmpty
        ? playerList.firstWhere((s) => s['depth_order'] == 1, orElse: () => playerList.first)
        : null;
    final starterName = starter?['player_name'] as String?;

    // Dominant status: driven by the starter if present, otherwise worst across all
    // Priority: portal_risk > graduating > open > filled > unknown
    String dominantStatus = 'unknown';
    const priority = ['portal_risk', 'graduating', 'open', 'filled', 'unknown'];
    final statusSource = starter != null ? [starter] : playerList;
    for (final status in priority) {
      if (statusSource.any((s) => s['slot_status'] == status)) {
        dominantStatus = status;
        break;
      }
    }

    const markerW = 64.0;
    const markerH = 56.0;
    final left = pos.x * width - markerW / 2;
    final top = pos.y * height - markerH / 2;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    switch (dominantStatus) {
      case 'filled':
        bgColor = Colors.white;
        borderColor = AppColors.success;
        textColor = AppColors.textPrimary;
        icon = null;
      case 'graduating':
        bgColor = AppColors.error.withValues(alpha: 0.12);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        icon = Icons.school;
      case 'portal_risk':
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        borderColor = AppColors.warning;
        textColor = AppColors.warning;
        icon = Icons.swap_horiz;
      case 'open':
        bgColor = const Color(0xFF1565C0).withValues(alpha: 0.12);
        borderColor = const Color(0xFF1565C0);
        textColor = const Color(0xFF1565C0);
        icon = Icons.flag;
      default: // unknown / empty
        bgColor = Colors.white.withValues(alpha: 0.15);
        borderColor = Colors.white.withValues(alpha: 0.5);
        textColor = Colors.white;
        icon = Icons.add;
    }

    return Positioned(
      left: left.clamp(0.0, width - markerW),
      top: top.clamp(0.0, height - markerH),
      child: GestureDetector(
        onTap: () => _showDepthChartSheet(pos),
        child: Container(
          width: markerW,
          height: markerH,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pos.abbreviation,
                      style: TextStyle(
                        color: dominantStatus == 'filled'
                            ? AppColors.coachColor
                            : textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (starterName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _shortName(starterName),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: dominantStatus == 'filled'
                                ? AppColors.textSecondary
                                : textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (count > 0)
                      Text(
                        '$count player${count > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 8,
                          color: dominantStatus == 'filled'
                              ? AppColors.textSecondary
                              : textColor,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (icon != null)
                      Icon(icon, color: textColor, size: 14),
                  ],
                ),
              ),
              // Player count badge
              if (count > 0)
                Positioned(
                  top: 3,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              // Injury indicator on starter
              if (starter?['is_injured'] == true)
                const Positioned(
                  bottom: 3,
                  right: 4,
                  child: Text('🤕', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(Colors.white, AppColors.success, 'Filled'),
        _legendItem(AppColors.error.withValues(alpha: 0.12), AppColors.error, 'Graduating'),
        _legendItem(AppColors.warning.withValues(alpha: 0.15), AppColors.warning, 'Portal Risk'),
        _legendItem(const Color(0xFF1565C0).withValues(alpha: 0.12), const Color(0xFF1565C0), 'Open'),
      ],
    );
  }

  Widget _legendItem(Color bg, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Depth Chart Bottom Sheet ───────────────────────────────────────────────────

class _DepthChartSheet extends StatefulWidget {
  final BlueprintPosition position;
  final int year;
  final List<Map<String, dynamic>> slots;
  final int maxDepth;
  final Future<void> Function(int depthOrder, String status, String? name, bool isInjured, String? injuryReturnDate) onUpsert; // ignore: avoid_positional_boolean_parameters
  final Future<void> Function(int depthOrder) onDelete;
  final Future<void> Function(int depthA, int depthB) onSwap;

  const _DepthChartSheet({
    required this.position,
    required this.year,
    required this.slots,
    required this.maxDepth,
    required this.onUpsert,
    required this.onDelete,
    required this.onSwap,
  });

  @override
  State<_DepthChartSheet> createState() => _DepthChartSheetState();
}

class _DepthChartSheetState extends State<_DepthChartSheet> {
  late List<Map<String, dynamic>> _localSlots;

  @override
  void initState() {
    super.initState();
    _localSlots = List<Map<String, dynamic>>.from(widget.slots);
  }

  void _showEditDialog({Map<String, dynamic>? existing, required int depthOrder}) {
    final nameCtrl = TextEditingController(text: existing?['player_name'] as String? ?? '');
    String selectedStatus = (existing?['slot_status'] as String?) ?? 'filled';
    bool isInjured = existing?['is_injured'] as bool? ?? false;
    DateTime? returnDate = existing?['injury_return_date'] != null
        ? DateTime.tryParse(existing!['injury_return_date'] as String)
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing == null ? 'Add Player' : 'Edit Player',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Player name (optional)',
                    hintText: 'e.g. Alex Johnson',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                const Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                ..._slotStatusOptions.map((option) {
                  final isSelected = selectedStatus == option['value'];
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedStatus = option['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (option['color'] as Color).withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? (option['color'] as Color) : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(option['icon'] as IconData,
                              color: isSelected ? option['color'] as Color : AppColors.textSecondary,
                              size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isSelected ? option['color'] as Color : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: option['color'] as Color, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Injury toggle
                Row(
                  children: [
                    const Text('🤕', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Injured',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Switch(
                      value: isInjured,
                      activeTrackColor: AppColors.error,
                      onChanged: (val) => setDialogState(() {
                        isInjured = val;
                        if (!val) returnDate = null;
                      }),
                    ),
                  ],
                ),
                if (isInjured) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: returnDate ?? DateTime.now().add(const Duration(days: 14)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        helpText: 'Expected return date',
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.coachColor),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setDialogState(() => returnDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text(
                            returnDate != null
                                ? 'Return: ${returnDate!.day}/${returnDate!.month}/${returnDate!.year}'
                                : 'Tap to set return date',
                            style: TextStyle(
                              fontSize: 13,
                              color: returnDate != null ? AppColors.error : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coachColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final name = nameCtrl.text.trim();
                final returnDateStr = returnDate != null
                    ? '${returnDate!.year}-${returnDate!.month.toString().padLeft(2, '0')}-${returnDate!.day.toString().padLeft(2, '0')}'
                    : null;
                await widget.onUpsert(
                  depthOrder, selectedStatus, name.isEmpty ? null : name,
                  isInjured, returnDateStr,
                );
                setState(() {
                  final idx = _localSlots.indexWhere((s) => s['depth_order'] == depthOrder);
                  final entry = {
                    'depth_order': depthOrder,
                    'slot_status': selectedStatus,
                    'player_name': name.isEmpty ? null : name,
                    'is_injured': isInjured,
                    'injury_return_date': returnDateStr,
                  };
                  if (idx >= 0) {
                    _localSlots[idx] = entry;
                  } else {
                    _localSlots.add(entry);
                    _localSlots.sort((a, b) =>
                        (a['depth_order'] as int).compareTo(b['depth_order'] as int));
                  }
                });
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  /// Promote a player one step up in the depth chart (swap with the player above).
  Future<void> _promote(int depthOrder) async {
    final sortedOrders = _localSlots
        .map((s) => s['depth_order'] as int)
        .toList()
      ..sort();
    final idx = sortedOrders.indexOf(depthOrder);
    if (idx <= 0) return; // already at top

    final depthAbove = sortedOrders[idx - 1];

    // Optimistic local swap
    setState(() {
      final idxA = _localSlots.indexWhere((s) => s['depth_order'] == depthOrder);
      final idxB = _localSlots.indexWhere((s) => s['depth_order'] == depthAbove);
      if (idxA >= 0 && idxB >= 0) {
        final temp = _localSlots[idxA]['depth_order'];
        _localSlots[idxA] = {..._localSlots[idxA], 'depth_order': _localSlots[idxB]['depth_order']};
        _localSlots[idxB] = {..._localSlots[idxB], 'depth_order': temp};
        _localSlots.sort((a, b) =>
            (a['depth_order'] as int).compareTo(b['depth_order'] as int));
      }
    });

    await widget.onSwap(depthOrder, depthAbove);
  }

  /// Demote a player one step down in the depth chart (swap with the player below).
  Future<void> _demote(int depthOrder) async {
    final sortedOrders = _localSlots
        .map((s) => s['depth_order'] as int)
        .toList()
      ..sort();
    final idx = sortedOrders.indexOf(depthOrder);
    if (idx < 0 || idx >= sortedOrders.length - 1) return; // already at bottom

    final depthBelow = sortedOrders[idx + 1];

    // Optimistic local swap
    setState(() {
      final idxA = _localSlots.indexWhere((s) => s['depth_order'] == depthOrder);
      final idxB = _localSlots.indexWhere((s) => s['depth_order'] == depthBelow);
      if (idxA >= 0 && idxB >= 0) {
        final temp = _localSlots[idxA]['depth_order'];
        _localSlots[idxA] = {..._localSlots[idxA], 'depth_order': _localSlots[idxB]['depth_order']};
        _localSlots[idxB] = {..._localSlots[idxB], 'depth_order': temp};
        _localSlots.sort((a, b) =>
            (a['depth_order'] as int).compareTo(b['depth_order'] as int));
      }
    });

    await widget.onSwap(depthOrder, depthBelow);
  }

  @override
  Widget build(BuildContext context) {
    final usedOrders = _localSlots.map((s) => s['depth_order'] as int).toSet();
    final canAdd = _localSlots.length < widget.maxDepth;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.coachColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.position.abbreviation,
                    style: const TextStyle(
                      color: AppColors.coachColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
                      widget.position.positionName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Class of ${widget.year} · ${_localSlots.length}/${widget.maxDepth} players',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Player list
          if (_localSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No players added yet.\nTap "+ Add Player" to begin building your depth chart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            )
          else
            ..._localSlots.map((slot) {
              final depthOrder = slot['depth_order'] as int;
              final name = slot['player_name'] as String?;
              final status = slot['slot_status'] as String? ?? 'unknown';
              final injured = slot['is_injured'] as bool? ?? false;
              final returnDateStr = slot['injury_return_date'] as String?;
              final returnDate = returnDateStr != null ? DateTime.tryParse(returnDateStr) : null;
              final statusOption = _slotStatusOptions.firstWhere(
                (o) => o['value'] == status,
                orElse: () => _slotStatusOptions.last,
              );
              final color = statusOption['color'] as Color;

              // Position in sorted list (determines which arrows are active)
              final sortedOrders = _localSlots
                  .map((s) => s['depth_order'] as int)
                  .toList()
                ..sort();
              final posIdx = sortedOrders.indexOf(depthOrder);
              final isFirst = posIdx == 0;
              final isLast  = posIdx == sortedOrders.length - 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: injured ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
                    width: injured ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // ── Move up/down arrows ─────────────────────────
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: isFirst ? null : () => _promote(depthOrder),
                                child: Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 22,
                                  color: isFirst
                                      ? AppColors.border
                                      : AppColors.coachColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: isLast ? null : () => _demote(depthOrder),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 22,
                                  color: isLast
                                      ? AppColors.border
                                      : AppColors.coachColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // ── Starter / Backup badge ──────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: depthOrder == 1
                                  ? AppColors.coachColor
                                  : AppColors.coachColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              depthOrder == 1 ? 'Starter' : 'Backup',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: depthOrder == 1 ? Colors.white : AppColors.coachColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (injured) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('🤕',
                                            style: TextStyle(fontSize: 10)),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        name ?? 'Unnamed Player',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: name != null ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(statusOption['icon'] as IconData, size: 12, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusOption['label'] as String,
                                      style: TextStyle(fontSize: 11, color: color),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                            onPressed: () => _showEditDialog(existing: slot, depthOrder: depthOrder),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            onPressed: () async {
                              await widget.onDelete(depthOrder);
                              setState(() {
                                _localSlots.removeWhere((s) => s['depth_order'] == depthOrder);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Return date strip
                    if (injured && returnDate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.07),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Text(
                          'Expected return: ${returnDate.day}/${returnDate.month}/${returnDate.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),

          // Add player button
          if (canAdd)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Player'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coachColor,
                  side: const BorderSide(color: AppColors.coachColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // Find the next available depth_order
                  int nextOrder = 1;
                  while (usedOrders.contains(nextOrder)) { nextOrder++; }
                  _showEditDialog(depthOrder: nextOrder);
                },
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Max ${widget.maxDepth} players per position per year',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const List<Map<String, dynamic>> _slotStatusOptions = [
  {
    'value': 'filled',
    'label': 'Confirmed Staying',
    'icon': Icons.check_circle_outline,
    'color': AppColors.success,
  },
  {
    'value': 'graduating',
    'label': 'Graduating',
    'icon': Icons.school_outlined,
    'color': AppColors.error,
  },
  {
    'value': 'portal_risk',
    'label': 'Transfer Portal Risk',
    'icon': Icons.swap_horiz,
    'color': AppColors.warning,
  },
  {
    'value': 'open',
    'label': 'Open — Needs Recruit',
    'icon': Icons.flag_outlined,
    'color': Color(0xFF1565C0),
  },
  {
    'value': 'unknown',
    'label': 'Unknown',
    'icon': Icons.help_outline,
    'color': AppColors.textSecondary,
  },
];

/// Draws field markings: center circle, penalty areas, halfway line
class _FieldMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, w - 16, h - 16),
        const Radius.circular(4),
      ),
      paint,
    );

    canvas.drawLine(Offset(8, h * 0.5), Offset(w - 8, h * 0.5), paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.15, paint);

    final penW = w * 0.55;
    final penH = h * 0.18;
    canvas.drawRect(Rect.fromLTWH((w - penW) / 2, 8, penW, penH), paint);
    canvas.drawRect(Rect.fromLTWH((w - penW) / 2, h - 8 - penH, penW, penH), paint);

    final goalW = w * 0.28;
    final goalH = h * 0.07;
    canvas.drawRect(Rect.fromLTWH((w - goalW) / 2, 8, goalW, goalH), paint);
    canvas.drawRect(Rect.fromLTWH((w - goalW) / 2, h - 8 - goalH, goalW, goalH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

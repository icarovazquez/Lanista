import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/player_colors.dart';

class PlayerMySchoolsPage extends StatefulWidget {
  const PlayerMySchoolsPage({super.key});

  @override
  State<PlayerMySchoolsPage> createState() => _PlayerMySchoolsPageState();
}

class _PlayerMySchoolsPageState extends State<PlayerMySchoolsPage> {
  bool _loading = true;
  String? _error;
  List<_SavedSchool> _schools = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final db = Supabase.instance.client;
      final userId = db.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final playerRow = await db
          .from('players')
          .select('id, primary_position, graduation_year')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerRow == null) {
        setState(() { _loading = false; _schools = []; });
        return;
      }

      final playerId = playerRow['id'] as String;
      final primaryPos = (playerRow['primary_position'] as String?)?.toUpperCase();
      final gradYear = playerRow['graduation_year'] as int?;

      // Saved coaches with their info
      final savedRaw = await db
          .from('player_saved_coaches')
          .select('coach_id, status, saved_at, '
              'coaches!inner(id, school_name, division, state, website_url)')
          .eq('player_id', playerId)
          .order('saved_at', ascending: false);

      if (savedRaw.isEmpty) {
        setState(() { _loading = false; _schools = []; });
        return;
      }

      final coachIds = (savedRaw as List).map((s) => s['coach_id'] as String).toList();

      // Match scores
      final matchesRaw = await db
          .from('player_coach_matches')
          .select('coach_id, total_score, tactical_score, position_score, '
              'physical_score, academic_score, timeline_score, film_score')
          .eq('player_id', playerId)
          .inFilter('coach_id', coachIds);

      final matchMap = <String, Map<String, dynamic>>{
        for (final m in matchesRaw as List) m['coach_id'] as String: m,
      };

      // Open roster slot at player's position for each coach
      Set<String> openSlotCoachIds = {};
      if (primaryPos != null && gradYear != null) {
        final posKeys = _expandPosition(primaryPos);
        final slotsRaw = await db
            .from('roster_slots')
            .select('coach_id')
            .inFilter('coach_id', coachIds)
            .inFilter('position_key', posKeys)
            .eq('slot_status', 'open')
            .gte('graduation_year', DateTime.now().year);
        openSlotCoachIds = {for (final s in slotsRaw as List) s['coach_id'] as String};
      }

      final schools = <_SavedSchool>[];
      for (final saved in savedRaw) {
        final coachId = saved['coach_id'] as String;
        final coach = saved['coaches'] as Map<String, dynamic>;
        final match = matchMap[coachId];

        schools.add(_SavedSchool(
          coachId:     coachId,
          playerId:    playerId,
          schoolName:  coach['school_name'] as String? ?? '',
          division:    coach['division'] as String? ?? '',
          state:       coach['state'] as String? ?? '',
          status:      saved['status'] as String? ?? 'interested',
          hasOpenSlot: openSlotCoachIds.contains(coachId),
          totalScore:  (match?['total_score'] as num?)?.toDouble() ?? 0,
          filmScore:   (match?['film_score'] as num?)?.toDouble() ?? 0,
          hasMatch:    match != null,
        ));
      }

      // Sort: open slot first, then by score
      schools.sort((a, b) {
        if (a.hasOpenSlot != b.hasOpenSlot) return a.hasOpenSlot ? -1 : 1;
        return b.totalScore.compareTo(a.totalScore);
      });

      setState(() { _schools = schools; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static List<String> _expandPosition(String pos) {
    switch (pos.toLowerCase()) {
      case 'cb':  return ['rcb', 'lcb'];
      case 'cdm': case 'cam': return ['rcm', 'cm', 'lcm'];
      case 'rm':  return ['rcm', 'rw', 'cm'];
      case 'lm':  return ['lcm', 'lw', 'cm'];
      case 'f9':  return ['st'];
      case 'wb':  return ['rb', 'lb'];
      case 'cm':  return ['cm', 'rcm', 'lcm'];
      default:    return [pos.toLowerCase()];
    }
  }

  Future<void> _removeSchool(String coachId, String playerId) async {
    try {
      await Supabase.instance.client
          .from('player_saved_coaches')
          .delete()
          .eq('player_id', playerId)
          .eq('coach_id', coachId);
      setState(() { _schools.removeWhere((s) => s.coachId == coachId); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: $e')));
      }
    }
  }

  Future<void> _updateStatus(String coachId, String playerId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('player_saved_coaches')
          .update({'status': newStatus})
          .eq('player_id', playerId)
          .eq('coach_id', coachId);
      setState(() {
        final idx = _schools.indexWhere((s) => s.coachId == coachId);
        if (idx >= 0) {
          _schools[idx] = _schools[idx].copyWith(status: newStatus);
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayerColors.background,
      appBar: AppBar(
        backgroundColor: PlayerColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Schools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          if (_schools.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PlayerColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PlayerColors.accent.withValues(alpha: 0.4)),
                ),
                child: Text('${_schools.length} saved',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: PlayerColors.accent)),
              )),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PlayerColors.accent))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadData)
              : _schools.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      color: PlayerColors.accent,
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: _schools.length,
                        itemBuilder: (_, i) => _SchoolCard(
                          school: _schools[i],
                          onRemove: () => _removeSchool(_schools[i].coachId, _schools[i].playerId),
                          onStatusChanged: (s) => _updateStatus(
                              _schools[i].coachId, _schools[i].playerId, s),
                        ),
                      ),
                    ),
    );
  }
}

// ── School card ───────────────────────────────────────────────────────────────

class _SchoolCard extends StatelessWidget {
  final _SavedSchool school;
  final VoidCallback onRemove;
  final void Function(String status) onStatusChanged;

  const _SchoolCard({
    required this.school,
    required this.onRemove,
    required this.onStatusChanged,
  });

  Color get _scoreColor {
    if (!school.hasMatch) return PlayerColors.textTertiary;
    if (school.totalScore >= 70) return PlayerColors.accent;
    if (school.totalScore >= 50) return const Color(0xFF4A9D6F);
    return const Color(0xFFE8A838);
  }

  String get _fitLabel {
    if (!school.hasMatch) return '—';
    if (school.totalScore >= 75) return 'Strong fit';
    if (school.totalScore >= 55) return 'Good fit';
    if (school.totalScore >= 35) return 'Possible fit';
    return 'Reach';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PlayerColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: school.hasOpenSlot
              ? PlayerColors.accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Score circle
              SizedBox(
                width: 48, height: 48,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: school.hasMatch ? school.totalScore / 100 : 0,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(_scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(school.hasMatch ? '${school.totalScore.round()}%' : '—',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: _scoreColor)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(school.schoolName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 12,
                        color: PlayerColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(school.state,
                      style: TextStyle(fontSize: 12, color: PlayerColors.textTertiary)),
                    const SizedBox(width: 8),
                    _Chip(school.division, color: _divColor(school.division)),
                    const SizedBox(width: 6),
                    if (school.hasMatch) ...[
                      _Chip(_fitLabel,
                        color: _scoreColor.withValues(alpha: 0.15),
                        textColor: _scoreColor),
                    ],
                  ]),
                ]),
              ),
              // Remove button
              GestureDetector(
                onTap: () => _confirmRemove(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.bookmark_remove_outlined, size: 18,
                      color: PlayerColors.textTertiary),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            // Position availability banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: school.hasOpenSlot
                    ? const Color(0xFF4A9D6F).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: school.hasOpenSlot
                      ? const Color(0xFF4A9D6F).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                Icon(
                  school.hasOpenSlot ? Icons.sports_soccer : Icons.schedule,
                  size: 14,
                  color: school.hasOpenSlot
                      ? const Color(0xFF4A9D6F) : PlayerColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  school.hasOpenSlot
                      ? 'Open roster slot at your position'
                      : 'No open slot at your position right now — monitor for future need',
                  style: TextStyle(
                    fontSize: 12,
                    color: school.hasOpenSlot
                        ? const Color(0xFF4A9D6F) : PlayerColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            // Status selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) => GestureDetector(
                  onTap: () => onStatusChanged(s.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: school.status == s.key
                          ? s.color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: school.status == s.key
                            ? s.color.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(s.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: school.status == s.key ? s.color : PlayerColors.textTertiary,
                      )),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PlayerColors.surface,
        title: const Text('Remove school?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Remove ${school.schoolName} from your saved schools?',
          style: TextStyle(color: PlayerColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: PlayerColors.textSecondary))),
          TextButton(
            onPressed: () { Navigator.pop(context); onRemove(); },
            child: const Text('Remove', style: TextStyle(color: Color(0xFFE74C3C)))),
        ],
      ),
    );
  }

  Color _divColor(String div) {
    switch (div.toUpperCase()) {
      case 'D1': return const Color(0xFF4A9D6F);
      case 'D2': return const Color(0xFF3A7ACD);
      case 'D3': return const Color(0xFF8B6CD8);
      default:   return Colors.white38;
    }
  }
}

// ── Status labels ─────────────────────────────────────────────────────────────

class _StatusItem {
  final String key;
  final String label;
  final Color color;
  const _StatusItem(this.key, this.label, this.color);
}

const _statuses = [
  _StatusItem('interested', 'Interested',  Color(0xFFE8A838)),
  _StatusItem('contacted',  'Contacted',   Color(0xFF3A7ACD)),
  _StatusItem('applied',    'Applied',     Color(0xFF8B6CD8)),
  _StatusItem('committed',  'Committed',   Color(0xFF4A9D6F)),
];

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _Chip(this.label, {required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: textColor ?? Colors.white.withValues(alpha: 0.7))),
    );
  }
}

// ── Empty / Error views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border,
              size: 56, color: PlayerColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No saved schools yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Tap "Save to My Schools" on any opening to start building your target list.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: PlayerColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load schools',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: PlayerColors.textTertiary)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _SavedSchool {
  final String coachId;
  final String playerId;
  final String schoolName;
  final String division;
  final String state;
  final String status;
  final bool hasOpenSlot;
  final double totalScore;
  final double filmScore;
  final bool hasMatch;

  const _SavedSchool({
    required this.coachId,
    required this.playerId,
    required this.schoolName,
    required this.division,
    required this.state,
    required this.status,
    required this.hasOpenSlot,
    required this.totalScore,
    required this.filmScore,
    required this.hasMatch,
  });

  _SavedSchool copyWith({String? status}) => _SavedSchool(
    coachId: coachId, playerId: playerId, schoolName: schoolName,
    division: division, state: state, hasOpenSlot: hasOpenSlot,
    totalScore: totalScore, filmScore: filmScore, hasMatch: hasMatch,
    status: status ?? this.status,
  );
}

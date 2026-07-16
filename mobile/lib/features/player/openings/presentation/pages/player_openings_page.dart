import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/player_colors.dart';

class PlayerOpeningsPage extends StatefulWidget {
  const PlayerOpeningsPage({super.key});

  @override
  State<PlayerOpeningsPage> createState() => _PlayerOpeningsPageState();
}

class _PlayerOpeningsPageState extends State<PlayerOpeningsPage> {
  bool _loading = true;
  String? _error;
  List<_Opening> _openings = [];
  bool _hasFilm = false;
  String _playerId = '';
  Set<String> _savedCoachIds = {};

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

      // 1. Player profile
      final playerRow = await db
          .from('players')
          .select('id, primary_position, secondary_position, graduation_year')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerRow == null) {
        setState(() { _loading = false; _openings = []; });
        return;
      }

      final playerId     = playerRow['id'] as String;
      final primaryPos   = (playerRow['primary_position'] as String?)?.toUpperCase();
      final secondaryPos = (playerRow['secondary_position'] as String?)?.toUpperCase();
      final gradYear     = playerRow['graduation_year'] as int?;

      // Latest analyzed video (analysis_result lives on player_videos, not players)
      final videoRow = await db
          .from('player_videos')
          .select('analysis_result')
          .eq('player_id', playerId)
          .eq('analysis_status', 'complete')
          .order('uploaded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final analysisResult = videoRow?['analysis_result'] as Map<String, dynamic>?;
      _hasFilm = analysisResult != null;

      if (primaryPos == null || gradYear == null) {
        setState(() { _loading = false; _openings = []; });
        return;
      }

      // 2. Roster openings matching position(s) + graduation year
      // roster_slots stores formation-specific keys (rcb, lcb, rcm…); expand generic positions.
      final primaryKeys  = _expandPosition(primaryPos);
      final secondaryKeys = secondaryPos != null ? _expandPosition(secondaryPos) : <String>[];
      final allPosKeys = {...primaryKeys, ...secondaryKeys}.toList();

      final currentYear = DateTime.now().year;
      final slotsRaw = await db
          .from('roster_slots')
          .select('id, coach_id, position_key, graduation_year, slot_status, '
              'coaches!inner(id, school_name, division, state, website_url)')
          .eq('needs_recruit', true)
          .gte('graduation_year', currentYear)
          .inFilter('position_key', allPosKeys);

      if (slotsRaw.isEmpty) {
        setState(() { _loading = false; _openings = []; });
        return;
      }

      // 3. Match records + saved state for this player
      final coachIds = (slotsRaw as List)
          .map((s) => s['coach_id'] as String)
          .toSet()
          .toList();

      final matchesRaw = await db
          .from('player_coach_matches')
          .select('coach_id, total_score, tactical_score, position_score, '
              'physical_score, academic_score, timeline_score, film_score, '
              'match_reasons, match_gaps')
          .eq('player_id', playerId)
          .inFilter('coach_id', coachIds);

      final matchMap = <String, Map<String, dynamic>>{
        for (final m in matchesRaw as List) m['coach_id'] as String: m,
      };

      final savedRaw = await db
          .from('player_saved_coaches')
          .select('coach_id')
          .eq('player_id', playerId);

      final savedIds = {for (final s in savedRaw as List) s['coach_id'] as String};

      // 4. Build opening objects
      final openings = <_Opening>[];
      for (final slot in slotsRaw) {
        final coachId  = slot['coach_id'] as String;
        final posKey   = (slot['position_key'] as String).toUpperCase();
        final coach    = slot['coaches'] as Map<String, dynamic>;
        final match    = matchMap[coachId];
        final isPrimary = primaryKeys.contains(posKey.toLowerCase());

        double baseScore     = 0;
        double tacticalScore = 0;
        double positionScore = 0;
        double physicalScore = 0;
        double academicScore = 0;
        double timelineScore = 0;
        double filmScore     = 0;
        List<String> reasons = [];
        List<String> gaps    = [];
        if (match != null) {
          baseScore     = (match['total_score']    as num?)?.toDouble() ?? 0;
          tacticalScore = (match['tactical_score'] as num?)?.toDouble() ?? 0;
          positionScore = (match['position_score'] as num?)?.toDouble() ?? 0;
          physicalScore = (match['physical_score'] as num?)?.toDouble() ?? 0;
          academicScore = (match['academic_score'] as num?)?.toDouble() ?? 0;
          timelineScore = (match['timeline_score'] as num?)?.toDouble() ?? 0;
          filmScore     = (match['film_score']     as num?)?.toDouble() ?? 0;
          reasons = _parseStringList(match['match_reasons']);
          gaps    = _parseStringList(match['match_gaps']);
        }

        // total_score from the engine already includes film_score.
        // Only apply the display-layer boost when the engine hasn't computed it yet.
        double displayScore = baseScore;
        if (analysisResult != null && filmScore == 0) {
          final rating = (analysisResult['scout_rating'] as num?)?.toDouble() ?? 5;
          final projection = analysisResult['college_level_projection'] as String? ?? '';
          final division = coach['division'] as String? ?? '';
          displayScore = _applyFilmBoost(baseScore, rating, projection, division);
        }
        displayScore = displayScore.clamp(0, 100);

        openings.add(_Opening(
          slotId:         slot['id'] as String,
          coachId:        coachId,
          schoolName:     coach['school_name'] as String? ?? '',
          division:       coach['division'] as String? ?? '',
          state:          coach['state'] as String? ?? '',
          website:        coach['website_url'] as String?,
          positionKey:    posKey,
          graduationYear: slot['graduation_year'] as int,
          slotStatus:     slot['slot_status'] as String? ?? 'open',
          isPrimary:      isPrimary,
          hasMatchRecord: match != null,
          displayScore:   displayScore,
          tacticalScore:  tacticalScore,
          positionScore:  positionScore,
          physicalScore:  physicalScore,
          academicScore:  academicScore,
          timelineScore:  timelineScore,
          filmScore:      filmScore,
          isSaved:        savedIds.contains(coachId),
          matchReasons:   reasons,
          matchGaps:      gaps,
        ));
      }

      // 5. Sort: primary first, then by score desc
      openings.sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        if (a.hasMatchRecord != b.hasMatchRecord) return a.hasMatchRecord ? -1 : 1;
        return b.displayScore.compareTo(a.displayScore);
      });

      setState(() {
        _openings = openings;
        _savedCoachIds = savedIds;
        _loading = false;
        _playerId = playerId;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double _applyFilmBoost(double base, double rating, String projection, String division) {
    // scout_rating 1–10 → ±7.5 pts centered on 5
    final ratingBoost = (rating - 5) * 1.5;
    // projection alignment with division
    double projBoost = 0;
    final divUpper = division.toUpperCase();
    final projUpper = projection.toUpperCase();
    if (projUpper.isNotEmpty && divUpper.isNotEmpty) {
      if (projUpper == divUpper || projUpper.contains(divUpper)) {
        projBoost = 5;
      } else if ((projUpper == 'D1' && (divUpper == 'D2' || divUpper == 'D3')) ||
                 (projUpper == 'D2' && divUpper == 'D3')) {
        projBoost = 2; // overqualified but still good
      } else if ((projUpper == 'D3' && divUpper == 'D1') ||
                 (projUpper == 'D3' && divUpper == 'D2')) {
        projBoost = -3;
      }
    }
    return base + ratingBoost + projBoost;
  }

  // Maps generic position codes → formation-specific position_key values stored in roster_slots.
  static List<String> _expandPosition(String pos) {
    switch (pos.toLowerCase()) {
      case 'cb':  return ['rcb', 'lcb'];
      case 'cdm': return ['rcm', 'cm', 'lcm'];
      case 'cam': return ['rcm', 'cm', 'lcm'];
      case 'rm':  return ['rcm', 'rw', 'cm'];
      case 'lm':  return ['lcm', 'lw', 'cm'];
      case 'f9':  return ['st'];
      case 'wb':  return ['rb', 'lb'];
      case 'gk':  return ['gk'];
      case 'lb':  return ['lb'];
      case 'rb':  return ['rb'];
      case 'cm':  return ['cm', 'rcm', 'lcm'];
      case 'lw':  return ['lw'];
      case 'rw':  return ['rw'];
      case 'st':  return ['st'];
      default:    return [pos.toLowerCase()];
    }
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(openingCount: _openings.length, hasFilm: _hasFilm,
              savedCount: _savedCoachIds.length),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: PlayerColors.accent))
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _loadData)
                    : _openings.isEmpty
                        ? const _EmptyView()
                        : RefreshIndicator(
                            color: PlayerColors.accent,
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _openings.length,
                              itemBuilder: (_, i) {
                                final o = _openings[i];
                                final showSecondaryLabel = i > 0 &&
                                    _openings[i - 1].isPrimary && !o.isPrimary;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (i == 0)
                                      _SectionLabel('Primary position matches'),
                                    if (showSecondaryLabel)
                                      _SectionLabel('Secondary position matches'),
                                    _OpeningCard(
                                      opening: o,
                                      hasFilm: _hasFilm,
                                      playerId: _playerId,
                                      onSaveToggled: (coachId, saved) => setState(() {
                                        if (saved) {
                                          _savedCoachIds.add(coachId);
                                        } else {
                                          _savedCoachIds.remove(coachId);
                                        }
                                      }),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int openingCount;
  final bool hasFilm;
  final int savedCount;
  const _Header({required this.openingCount, required this.hasFilm, required this.savedCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Roster Openings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              const Spacer(),
              // My Schools bookmark button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/player/my-schools'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(savedCount > 0 ? Icons.bookmark : Icons.bookmark_border,
                        size: 15, color: savedCount > 0 ? PlayerColors.accent : PlayerColors.textSecondary),
                    if (savedCount > 0) ...[
                      const SizedBox(width: 4),
                      Text('$savedCount',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: PlayerColors.accent)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              if (openingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: PlayerColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PlayerColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text('$openingCount open',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: PlayerColors.accent)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasFilm
                ? 'Scores include your film analysis'
                : 'Upload your highlight reel to boost your match scores',
            style: TextStyle(fontSize: 13,
                color: hasFilm ? PlayerColors.textSecondary : PlayerColors.accent.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(text.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: PlayerColors.textTertiary, letterSpacing: 1.2)),
    );
  }
}

// ── Opening card ──────────────────────────────────────────────────────────────

class _OpeningCard extends StatelessWidget {
  final _Opening opening;
  final bool hasFilm;
  final String playerId;
  final void Function(String coachId, bool saved) onSaveToggled;
  const _OpeningCard({
    required this.opening,
    required this.hasFilm,
    required this.playerId,
    required this.onSaveToggled,
  });

  Color get _scoreColor {
    if (!opening.hasMatchRecord) return PlayerColors.textTertiary;
    if (opening.displayScore >= 70) return PlayerColors.accent;
    if (opening.displayScore >= 50) return const Color(0xFF4A9D6F);
    return const Color(0xFFE8A838);
  }

  String get _fitLabel {
    if (!opening.hasMatchRecord) return 'Score pending';
    if (opening.displayScore >= 75) return 'Strong fit';
    if (opening.displayScore >= 55) return 'Good fit';
    if (opening.displayScore >= 35) return 'Possible fit';
    return 'Reach';
  }

  // ignore: unused_element — kept for potential future use
  String get _fitSummary {
    if (!opening.hasMatchRecord) {
      return 'Match analysis not yet calculated for this program.';
    }
    if (opening.displayScore >= 70) {
      final reason = opening.matchReasons.isNotEmpty
          ? opening.matchReasons.first
          : 'Strong overall profile match';
      return hasFilm ? reason : '$reason · Upload film to boost score';
    }
    if (opening.displayScore >= 50) {
      final reason = opening.matchReasons.isNotEmpty ? opening.matchReasons.first : '';
      final gap = opening.matchGaps.isNotEmpty ? opening.matchGaps.first : '';
      if (reason.isNotEmpty && gap.isNotEmpty) return '$reason · $gap';
      if (reason.isNotEmpty) return reason;
      return gap.isNotEmpty ? gap : 'Good overall fit';
    }
    return opening.matchGaps.isNotEmpty
        ? opening.matchGaps.first
        : 'Continue building your profile to improve this match';
  }

  String get _statusLabel {
    switch (opening.slotStatus) {
      case 'graduating': return 'Graduating';
      case 'portal_risk': return 'Transfer risk';
      case 'open': return 'Open slot';
      default: return 'Opening';
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _OpeningDetailSheet(
        opening: opening, playerId: playerId, onSaveToggled: onSaveToggled),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PlayerColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: opening.isPrimary
              ? PlayerColors.accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Score ring
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: opening.hasMatchRecord ? opening.displayScore / 100 : 0,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(_scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    opening.hasMatchRecord
                        ? '${opening.displayScore.round()}%'
                        : '—',
                    style: TextStyle(
                      fontSize: opening.hasMatchRecord ? 11 : 14,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(opening.schoolName,
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w800, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ),
                      if (opening.isSaved)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.bookmark,
                              size: 13, color: PlayerColors.accent),
                        ),
                      _Chip(opening.division,
                          color: _divisionColor(opening.division)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12,
                          color: PlayerColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(opening.state,
                        style: TextStyle(fontSize: 12, color: PlayerColors.textTertiary)),
                      const SizedBox(width: 8),
                      _Chip(opening.positionKey.toUpperCase(),
                          color: PlayerColors.accent.withValues(alpha: 0.15),
                          textColor: PlayerColors.accent),
                      const SizedBox(width: 6),
                      _Chip("'${opening.graduationYear % 100}",
                          color: Colors.white.withValues(alpha: 0.06),
                          textColor: PlayerColors.textSecondary),
                      const SizedBox(width: 6),
                      _Chip(_statusLabel,
                          color: Colors.white.withValues(alpha: 0.06),
                          textColor: PlayerColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _ScoreExplanation(opening: opening, scoreColor: _scoreColor, fitLabel: _fitLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    )); // GestureDetector
  }

  Color _divisionColor(String div) {
    switch (div.toUpperCase()) {
      case 'D1': return const Color(0xFF4A9D6F).withValues(alpha: 0.2);
      case 'D2': return const Color(0xFF3A7ACD).withValues(alpha: 0.2);
      case 'D3': return const Color(0xFF8B6CD8).withValues(alpha: 0.2);
      default:   return Colors.white.withValues(alpha: 0.08);
    }
  }
}

// ── Score explanation (inline on card) ───────────────────────────────────────

class _ScoreExplanation extends StatelessWidget {
  final _Opening opening;
  final Color scoreColor;
  final String fitLabel;
  const _ScoreExplanation({required this.opening, required this.scoreColor, required this.fitLabel});

  @override
  Widget build(BuildContext context) {
    if (!opening.hasMatchRecord) {
      return Row(children: [
        Icon(Icons.pending_outlined, size: 11, color: PlayerColors.textTertiary),
        const SizedBox(width: 4),
        Expanded(child: Text('Score not yet calculated for this program',
          style: TextStyle(fontSize: 11, color: PlayerColors.textTertiary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);
    }

    final topReason = opening.matchReasons.isNotEmpty ? opening.matchReasons.first : null;
    final topGap    = opening.matchGaps.isNotEmpty ? opening.matchGaps.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fit label badge + top reason
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(fitLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: scoreColor)),
          ),
          if (topReason != null) ...[
            const SizedBox(width: 6),
            Expanded(child: Text(topReason,
              style: TextStyle(fontSize: 11, color: PlayerColors.textSecondary, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ]),
        // Top gap (if any)
        if (topGap != null) ...[
          const SizedBox(height: 3),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.remove_circle_outline, size: 11,
                color: const Color(0xFFE8A838).withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Expanded(child: Text(topGap,
              style: TextStyle(fontSize: 11, color: PlayerColors.textTertiary, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ],
    );
  }
}

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
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: textColor ?? Colors.white.withValues(alpha: 0.7))),
    );
  }
}

// ── Opening detail sheet ──────────────────────────────────────────────────────

class _OpeningDetailSheet extends StatefulWidget {
  final _Opening opening;
  final String playerId;
  final void Function(String coachId, bool saved) onSaveToggled;
  const _OpeningDetailSheet({
    required this.opening,
    required this.playerId,
    required this.onSaveToggled,
  });

  @override
  State<_OpeningDetailSheet> createState() => _OpeningDetailSheetState();
}

class _OpeningDetailSheetState extends State<_OpeningDetailSheet> {
  late bool _saved;
  bool _savingInProgress = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.opening.isSaved;
  }

  Future<void> _toggleSave() async {
    if (_savingInProgress) return;
    setState(() { _savingInProgress = true; });
    try {
      final db = Supabase.instance.client;
      if (_saved) {
        await db.from('player_saved_coaches')
            .delete()
            .eq('player_id', widget.playerId)
            .eq('coach_id', widget.opening.coachId);
      } else {
        await db.from('player_saved_coaches')
            .insert({'player_id': widget.playerId, 'coach_id': widget.opening.coachId});
      }
      setState(() { _saved = !_saved; });
      widget.onSaveToggled(widget.opening.coachId, _saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() { _savingInProgress = false; });
    }
  }

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ScoreBreakdownSheet(opening: widget.opening),
    );
  }

  Future<void> _messageCoach(BuildContext context) async {
    Navigator.pop(context);
    try {
      final db = Supabase.instance.client;
      final userId = db.auth.currentUser?.id;
      if (userId == null) return;

      final existing = await db
          .from('conversations')
          .select('id')
          .eq('player_id', widget.playerId)
          .eq('coach_id', widget.opening.coachId)
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'] as String;
      } else {
        final created = await db
            .from('conversations')
            .insert({'player_id': widget.playerId, 'coach_id': widget.opening.coachId, 'initiated_by': userId})
            .select('id')
            .single();
        convId = created['id'] as String;
      }

      if (context.mounted) {
        Navigator.pushNamed(context, '/messages/$convId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open conversation: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opening = widget.opening;
    final divColor = _divisionColor(opening.division);
    return Padding(
      padding: EdgeInsets.only(
        top: 20, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(opening.schoolName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                      color: Colors.white)),
              ),
              // Save / unsave button
              GestureDetector(
                onTap: _toggleSave,
                child: Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _saved
                        ? PlayerColors.accent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _saved
                          ? PlayerColors.accent.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_saved ? Icons.bookmark : Icons.bookmark_border,
                        size: 14, color: _saved ? PlayerColors.accent : PlayerColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_saved ? 'Saved' : 'Save',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: _saved ? PlayerColors.accent : PlayerColors.textSecondary)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: divColor, borderRadius: BorderRadius.circular(8)),
                child: Text(opening.division,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.location_on_outlined, size: 14, color: PlayerColors.textTertiary),
            const SizedBox(width: 4),
            Text(opening.state, style: TextStyle(fontSize: 13, color: PlayerColors.textSecondary)),
            const SizedBox(width: 12),
            Icon(Icons.sports_soccer_outlined, size: 14, color: PlayerColors.textTertiary),
            const SizedBox(width: 4),
            Text('${opening.positionKey.toUpperCase()} · Class of ${opening.graduationYear}',
              style: TextStyle(fontSize: 13, color: PlayerColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          if (!opening.hasMatchRecord)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10)),
              child: Text('Match score not yet calculated.',
                style: TextStyle(fontSize: 13, color: PlayerColors.textSecondary)),
            )
          else ...[
            // Score + label + breakdown "?" button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text('${opening.displayScore.round()}%',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: _scoreChipColor(opening.displayScore))),
                const SizedBox(width: 10),
                Expanded(child: Text(_fitLabel(opening.displayScore),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: _scoreChipColor(opening.displayScore)))),
                // Score breakdown button
                GestureDetector(
                  onTap: () => _showBreakdown(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bar_chart_rounded, size: 12, color: PlayerColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('How?', style: TextStyle(fontSize: 11,
                          color: PlayerColors.textSecondary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
            if (opening.matchReasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('STRENGTHS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: PlayerColors.textTertiary, letterSpacing: 1.1)),
              const SizedBox(height: 6),
              ...opening.matchReasons.take(4).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_outline, size: 14,
                      color: const Color(0xFF4A9D6F)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4))),
                ]),
              )),
            ],
            if (opening.matchGaps.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('AREAS TO DEVELOP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: PlayerColors.textTertiary, letterSpacing: 1.1)),
              const SizedBox(height: 6),
              ...opening.matchGaps.take(3).map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.radio_button_unchecked, size: 14,
                      color: const Color(0xFFE8A838).withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(g,
                    style: TextStyle(fontSize: 13, color: PlayerColors.textSecondary,
                        height: 1.4))),
                ]),
              )),
            ],
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleSave,
                icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, size: 16),
                label: Text(_saved ? 'Saved to My Schools' : 'Save to My Schools'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _saved ? PlayerColors.accent : PlayerColors.textSecondary,
                  side: BorderSide(
                    color: _saved
                        ? PlayerColors.accent.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _messageCoach(context),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Message Coach'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PlayerColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fitLabel(double score) {
    if (score >= 75) return 'Strong fit';
    if (score >= 55) return 'Good fit';
    if (score >= 35) return 'Possible fit';
    return 'Reach';
  }

  Color _scoreChipColor(double score) {
    if (score >= 70) return PlayerColors.accent;
    if (score >= 50) return const Color(0xFF4A9D6F);
    return const Color(0xFFE8A838);
  }

  Color _divisionColor(String div) {
    switch (div.toUpperCase()) {
      case 'D1': return const Color(0xFF4A9D6F).withValues(alpha: 0.3);
      case 'D2': return const Color(0xFF3A7ACD).withValues(alpha: 0.3);
      case 'D3': return const Color(0xFF8B6CD8).withValues(alpha: 0.3);
      default:   return Colors.white.withValues(alpha: 0.1);
    }
  }
}

// ── Empty / Error views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 56,
                color: PlayerColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No openings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Complete your profile (position, graduation year) and we\'ll surface roster openings that match you.',
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
            const Text('Could not load openings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text(error,
              textAlign: TextAlign.center,
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

class _Opening {
  final String slotId;
  final String coachId;
  final String schoolName;
  final String division;
  final String state;
  final String? website;
  final String positionKey;
  final int graduationYear;
  final String slotStatus;
  final bool isPrimary;
  final bool hasMatchRecord;
  final double displayScore;
  final double tacticalScore;
  final double positionScore;
  final double physicalScore;
  final double academicScore;
  final double timelineScore;
  final double filmScore;
  final bool isSaved;
  final List<String> matchReasons;
  final List<String> matchGaps;

  const _Opening({
    required this.slotId,
    required this.coachId,
    required this.schoolName,
    required this.division,
    required this.state,
    this.website,
    required this.positionKey,
    required this.graduationYear,
    required this.slotStatus,
    required this.isPrimary,
    required this.hasMatchRecord,
    required this.displayScore,
    required this.tacticalScore,
    required this.positionScore,
    required this.physicalScore,
    required this.academicScore,
    required this.timelineScore,
    required this.filmScore,
    required this.isSaved,
    required this.matchReasons,
    required this.matchGaps,
  });
}

// ── Score breakdown sheet ─────────────────────────────────────────────────────

class _ScoreBreakdownSheet extends StatelessWidget {
  final _Opening opening;
  const _ScoreBreakdownSheet({required this.opening});

  @override
  Widget build(BuildContext context) {
    final categories = [
      _ScoreCat('Tactical fit',   opening.tacticalScore, 35, const Color(0xFF4A9D6F),
          'Formation & position overlap'),
      _ScoreCat('Position need',  opening.positionScore, 25, const Color(0xFF3A7ACD),
          'Open roster slot + priority'),
      _ScoreCat('Physical',       opening.physicalScore, 20, const Color(0xFF8B6CD8),
          'Height, speed, foot, build'),
      _ScoreCat('Academic',       opening.academicScore, 15, const Color(0xFFE8A838),
          'GPA & test scores'),
      _ScoreCat('Timeline',       opening.timelineScore, 5,  Colors.white54,
          'Graduation year alignment'),
      if (opening.filmScore > 0)
        _ScoreCat('Film',         opening.filmScore,     15, PlayerColors.accent,
            'Scout rating + level projection'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('How your score is calculated',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Each category contributes points. Film is a bonus on top.',
            style: TextStyle(fontSize: 13, color: PlayerColors.textSecondary)),
          const SizedBox(height: 20),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(cat.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white))),
                Text('${cat.score.round()} / ${cat.max}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: cat.color)),
              ]),
              const SizedBox(height: 4),
              Text(cat.description,
                style: TextStyle(fontSize: 11, color: PlayerColors.textTertiary)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cat.max > 0 ? (cat.score / cat.max).clamp(0.0, 1.0) : 0,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(cat.color),
                ),
              ),
            ]),
          )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: PlayerColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Upload highlight film to add up to 15 bonus points to every school\'s score.',
                style: TextStyle(fontSize: 12, color: PlayerColors.textSecondary, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ScoreCat {
  final String label;
  final double score;
  final int max;
  final Color color;
  final String description;
  const _ScoreCat(this.label, this.score, this.max, this.color, this.description);
}

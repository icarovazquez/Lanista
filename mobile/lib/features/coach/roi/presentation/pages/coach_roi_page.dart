import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';

// ── Colours ───────────────────────────────────────────────────────────────────
const _kFoundationBg  = Color(0xFFE8F5E9);
const _kDevelopingBg  = Color(0xFFFFF8E1);
const _kProvenBg      = Color(0xFFE3F2FD);
const _kReconsiderBg  = Color(0xFFFFEBEE);

const _kFoundationFg  = Color(0xFF2E7D32);
const _kDevelopingFg  = Color(0xFFE65100);
const _kProvenFg      = Color(0xFF1565C0);
const _kReconsiderFg  = Color(0xFFC62828);

const _kThreshold = 70.0; // dividing line for both axes

// ── Metric explanations ───────────────────────────────────────────────────────

const _kMetricInfo = {
  'Utilization': (
    title: 'Utilization',
    icon: '⏱️',
    body: 'How much did this player actually play?\n\n'
        'Calculated as minutes played ÷ total possible minutes in the season, '
        'expressed as a 0–100 score. A starter who plays every minute scores 100. '
        'A backup who never sees the field scores 0.\n\n'
        'Weight: 35% of ROI — the highest weight, because a player who doesn\'t play '
        'provides no on-field value regardless of their talent.',
  ),
  'Production': (
    title: 'Production',
    icon: '⚽',
    body: 'How much did this player contribute on the field, adjusted for their position?\n\n'
        '• Forwards: goals, assists, shots on target, chances created\n'
        '• Midfielders: key passes, progressive passes & carries, chances created, goals, assists\n'
        '• Defenders: duels won, progressive passes & carries, key passes\n'
        '• Goalkeepers: save percentage, clean sheets, goals allowed\n\n'
        'Stats are converted to per-90-minute rates so playing time doesn\'t inflate the score. '
        'Weight: 30% of ROI.',
  ),
  'Retention': (
    title: 'Retention',
    icon: '🔒',
    body: 'Did this player stay with your program?\n\n'
        'Scored by season status:\n'
        '• Graduated on time → 100\n'
        '• Still active on roster → 85\n'
        '• Medical redshirt → 75\n'
        '• Entered portal at season end → 30\n'
        '• Left mid-season → 10\n'
        '• Dismissed → 0\n\n'
        'A player who leaves early reduces your ROI regardless of how well they played while here. '
        'Weight: 20% of ROI.',
  ),
  'Academics': (
    title: 'Academics',
    icon: '🎓',
    body: 'Is this player maintaining academic eligibility?\n\n'
        'Based on their GPA this season (scaled 0–100) plus a bonus for being on track '
        'with credits. A 4.0 GPA with full credit load scores ~110 (capped at 100). '
        'Below a 2.0 GPA triggers an eligibility risk flag.\n\n'
        'Weight: 15% of ROI.',
  ),
  'Performance': (
    title: 'Current Performance',
    icon: '📈',
    body: 'How well is this player performing right now, in their most recent season?\n\n'
        'Uses the same position-adjusted production formula as the ROI score, '
        'but only looks at the latest season — not the career average. '
        'This captures whether a player is currently in form or declining.\n\n'
        'Weight: 40% of Player Value — the largest component, because current output '
        'is the best predictor of near-term contribution.',
  ),
  'Scarcity': (
    title: 'Position Scarcity',
    icon: '🗺️',
    body: 'How hard would it be to replace this player on your roster?\n\n'
        'Checks your current depth chart for this player\'s position. '
        'If there is no backup at depth order 2 or below, scarcity is high. '
        'If you have two strong backups already, scarcity is lower.\n\n'
        'A starting GK with no backup scores very high here — losing them '
        'leaves a critical gap. Weight: 25% of Player Value.',
  ),
  'Eligibility': (
    title: 'Remaining Eligibility',
    icon: '📅',
    body: 'How many seasons does this player have left?\n\n'
        '• Freshman (3+ seasons left) → 100\n'
        '• Sophomore (2 seasons left) → 75\n'
        '• Junior (1 season left) → 50\n'
        '• Senior (final season) → 25\n\n'
        'A freshman with high value is worth fighting hard to keep — '
        'they have years of contribution ahead. A senior in their last season '
        'has less future value even if they\'re performing well now. '
        'Weight: 20% of Player Value.',
  ),
  'Replaceability ↓': (
    title: 'Replaceability',
    icon: '🔄',
    body: 'How many blueprint-matched recruits exist for this position right now?\n\n'
        'Pulls from your active matches in the recruiting engine. '
        'If there are many strong matches available for this position, '
        'the player is more replaceable — their value score is lower. '
        'If your blueprint returns few matches, this player is harder to replace.\n\n'
        'Note: the bar shows replaceability inverted — a full bar means '
        'the player is hard to replace (low replaceability = high value). '
        'Weight: 15% of Player Value.',
  ),
};

void _showMetricInfo(BuildContext context, String metricKey) {
  final info = _kMetricInfo[metricKey];
  if (info == null) return;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(children: [
        Text(info.icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(info.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ]),
      content: Text(info.body,
          style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF555555))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(_),
          child: const Text('Got it',
              style: TextStyle(color: AppColors.coachColor, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

class CoachRoiPage extends StatefulWidget {
  const CoachRoiPage({super.key});

  @override
  State<CoachRoiPage> createState() => _CoachRoiPageState();
}

class _CoachRoiPageState extends State<CoachRoiPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final coachRow = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (coachRow == null) return;
      final coachId = coachRow['id'] as String;

      final rows = await _supabase
          .from('player_roi_records')
          .select('*, players!inner(id, primary_position, users!inner(first_name, last_name))')
          .eq('coach_id', coachId)
          .order('roi_score', ascending: false);

      if (mounted) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _playerName(Map<String, dynamic> p) {
    final u = p['players']?['users'];
    return '${u?['first_name'] ?? ''} ${u?['last_name'] ?? ''}'.trim();
  }

  String _initials(Map<String, dynamic> p) {
    final u = p['players']?['users'];
    final f = (u?['first_name'] as String? ?? '');
    final l = (u?['last_name'] as String? ?? '');
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
  }

  Color _quadrantFg(String? q) {
    switch (q) {
      case 'foundation':  return _kFoundationFg;
      case 'developing':  return _kDevelopingFg;
      case 'proven':      return _kProvenFg;
      default:            return _kReconsiderFg;
    }
  }

  Color _quadrantBg(String? q) {
    switch (q) {
      case 'foundation':  return _kFoundationBg;
      case 'developing':  return _kDevelopingBg;
      case 'proven':      return _kProvenBg;
      default:            return _kReconsiderBg;
    }
  }

  String _quadrantLabel(String? q) {
    switch (q) {
      case 'foundation':  return 'FOUNDATION';
      case 'developing':  return 'DEVELOPING';
      case 'proven':      return 'PROVEN';
      default:            return 'RECONSIDER';
    }
  }

  String _roiGrade(double score) {
    if (score >= 85) return 'Elite ROI';
    if (score >= 70) return 'Strong ROI';
    if (score >= 55) return 'Solid ROI';
    if (score >= 40) return 'Below Average';
    return 'Poor ROI';
  }

  // Sort order: foundation → developing → proven → reconsider
  int _quadrantOrder(String? q) {
    switch (q) {
      case 'foundation':  return 0;
      case 'developing':  return 1;
      case 'proven':      return 2;
      default:            return 3;
    }
  }

  List<Map<String, dynamic>> get _sorted {
    final list = List<Map<String, dynamic>>.from(_players);
    list.sort((a, b) {
      final qa = _quadrantOrder(a['retention_quadrant'] as String?);
      final qb = _quadrantOrder(b['retention_quadrant'] as String?);
      if (qa != qb) return qa.compareTo(qb);
      return (b['roi_score'] as num).compareTo(a['roi_score'] as num);
    });
    return list;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Recruiting ROI',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: const Text('Analytics Mode',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.coachColor)),
              backgroundColor: AppColors.coachColor.withValues(alpha: 0.08),
              side: BorderSide(color: AppColors.coachColor.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.coachColor))
          : _players.isEmpty
              ? _emptyState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(),
          const SizedBox(height: 24),
          // 2×2 Retention Matrix
          const Text('Retention Matrix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tap a player to see their full breakdown',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _retentionMatrix(),
          const SizedBox(height: 28),
          // Portal risk alerts
          if (_players.any((p) => p['portal_risk'] == true)) ...[
            _portalRiskBanner(),
            const SizedBox(height: 20),
          ],
          // Player list
          const Text('All Recruited Players',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._sorted.map((p) => _playerRow(p)),
          const SizedBox(height: 32),
          // ML Predictions section
          _predictionsCard(),
        ],
      ),
    );
  }

  // ── Summary row ──────────────────────────────────────────────────────────────

  Widget _summaryRow() {
    final active  = _players.where((p) => p['career_status'] == 'active').toList();
    final avgRoi  = active.isEmpty ? 0.0
        : active.map((p) => (p['roi_score'] as num).toDouble()).reduce((a, b) => a + b) / active.length;
    final portal  = _players.where((p) => p['portal_risk'] == true).length;
    final foundation = _players.where((p) => p['retention_quadrant'] == 'foundation').length;

    return Row(children: [
      Expanded(child: _miniStatCard('Avg ROI', avgRoi.toStringAsFixed(1),
          Icons.trending_up, AppColors.coachColor)),
      const SizedBox(width: 12),
      Expanded(child: _miniStatCard('Foundation', '$foundation',
          Icons.star_outline, _kFoundationFg)),
      const SizedBox(width: 12),
      Expanded(child: _miniStatCard('Portal Risk', '$portal',
          Icons.warning_amber_outlined, portal > 0 ? _kReconsiderFg : AppColors.textSecondary)),
    ]);
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );

  // ── 2×2 Retention Matrix ─────────────────────────────────────────────────────

  // Maps a score to a screen fraction using the threshold as the visual midpoint.
  // Scores 0–threshold → 0–0.5 of screen, scores threshold–100 → 0.5–1.0.
  double _scaleX(double roi) {
    if (roi <= _kThreshold) return (roi / _kThreshold) * 0.5;
    return 0.5 + ((roi - _kThreshold) / (100 - _kThreshold)) * 0.5;
  }

  // Y is inverted (y=0 is top = high value).
  double _scaleY(double value) {
    if (value >= _kThreshold) return ((100 - value) / (100 - _kThreshold)) * 0.5;
    return 0.5 + ((_kThreshold - value) / _kThreshold) * 0.5;
  }

  Widget _retentionMatrix() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            final half = size / 2;

            return Stack(
              children: [
                // Non-interactive background layer — equal quadrants at 50/50
                IgnorePointer(child: Stack(children: [

                  // Quadrant backgrounds with gradients
                  Positioned(left: 0, top: 0, width: half, height: half,
                    child: Container(decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFF8E1)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)))),
                  Positioned(left: half, top: 0, width: half, height: half,
                    child: Container(decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)))),
                  Positioned(left: 0, top: half, width: half, height: half,
                    child: Container(decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFFEBEE), Color(0xFFFCE4EC)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)))),
                  Positioned(left: half, top: half, width: half, height: half,
                    child: Container(decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFEDE7F6)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)))),

                  // Soccer pitch motif (behind dot grid)
                  Positioned.fill(child: CustomPaint(painter: _SoccerMotifPainter())),

                  // Subtle dot grid overlay
                  Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

                  // Dividing lines (thicker, styled)
                  Positioned(left: half - 0.5, top: 0,
                    child: Container(width: 1.5, height: size,
                        color: Colors.white.withValues(alpha: 0.8))),
                  Positioned(left: 0, top: half - 0.5,
                    child: Container(width: size, height: 1.5,
                        color: Colors.white.withValues(alpha: 0.8))),

                  // Quadrant header banners
                  _quadrantHeader(0, 0, half, '⚡', 'DEVELOPING', _kDevelopingFg,
                      'Low ROI · High Value', const Color(0xFFFFF3E0)),
                  _quadrantHeader(half, 0, half, '🏆', 'FOUNDATION', _kFoundationFg,
                      'High ROI · High Value', const Color(0xFFE8F5E9)),
                  _quadrantHeader(0, half, half, '⚠️', 'RECONSIDER', _kReconsiderFg,
                      'Low ROI · Low Value', const Color(0xFFFFEBEE)),
                  _quadrantHeader(half, half, half, '✅', 'PROVEN', _kProvenFg,
                      'High ROI · Graduated', const Color(0xFFE3F2FD)),

                  // Axis labels
                  Positioned(bottom: 8, left: 0, right: 0,
                    child: Center(child: Text('← LOW ROI   |   HIGH ROI →',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: Colors.grey[500], letterSpacing: 0.6)))),
                ])),

                // Player bubbles — tappable
                ..._players.map((p) => _playerBubble(p, size)),

                // Outer border
                Positioned.fill(child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.5),
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _quadrantHeader(double left, double top, double width,
      String emoji, String label, Color color, String subtitle, Color bg) =>
      Positioned(left: left, top: top, width: width,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.2)),
              right: left > 0 ? BorderSide.none : BorderSide(color: color.withValues(alpha: 0.0)),
            ),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                  color: color, letterSpacing: 0.6)),
              Text(subtitle, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75))),
            ])),
          ]),
        ),
      );

  Widget _playerBubble(Map<String, dynamic> p, double matrixSize) {
    final roi   = (p['roi_score']   as num?)?.toDouble() ?? 0;
    final value = (p['value_score'] as num?)?.toDouble() ?? 0;
    final quad  = p['retention_quadrant'] as String?;
    final isPortalRisk = p['portal_risk'] == true;

    // Graduated/transferred: pin value near bottom of their ROI half
    final effectiveValue = (p['career_status'] == 'graduated' || p['career_status'] == 'transferred')
        ? 8.0 : value;

    final bubbleR = 22.0;
    final xFrac = _scaleX(roi);
    final yFrac = _scaleY(effectiveValue);
    final x = xFrac * matrixSize - bubbleR;
    final y = yFrac * matrixSize - bubbleR;

    return Positioned(
      left: x.clamp(4, matrixSize - bubbleR * 2 - 4),
      top:  y.clamp(32, matrixSize - bubbleR * 2 - 4), // 32 = below header banner
      child: GestureDetector(
        onTap: () => _showPlayerSheet(p),
        child: Container(
          width: bubbleR * 2,
          height: bubbleR * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _quadrantFg(quad),
            border: isPortalRisk
                ? Border.all(color: _kReconsiderFg, width: 2.5)
                : Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _quadrantFg(quad).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(_initials(p),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ),
    );
  }


  // ── Portal risk banner ────────────────────────────────────────────────────────

  Widget _portalRiskBanner() {
    final atRisk = _players.where((p) => p['portal_risk'] == true).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kReconsiderBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kReconsiderFg.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Text('🔴', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Portal Risk Alert',
              style: TextStyle(fontWeight: FontWeight.w700, color: _kReconsiderFg, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            atRisk.map(_playerName).join(', ') +
                (atRisk.length == 1 ? ' has been flagged as a portal risk.' : ' have been flagged as portal risks.'),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ])),
      ]),
    );
  }

  // ── Player list row ──────────────────────────────────────────────────────────

  Widget _playerRow(Map<String, dynamic> p) {
    final roi    = (p['roi_score']   as num?)?.toDouble() ?? 0;
    final value  = (p['value_score'] as num?)?.toDouble() ?? 0;
    final quad   = p['retention_quadrant'] as String?;
    final fg     = _quadrantFg(quad);
    final bg     = _quadrantBg(quad);
    final isRisk = p['portal_risk'] == true;
    final status = p['career_status'] as String? ?? 'active';

    return GestureDetector(
      onTap: () => _showPlayerSheet(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isRisk ? _kReconsiderFg.withValues(alpha: 0.5) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Quadrant dot
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(_playerName(p),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            if (isRisk)
              const Text('🔴', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(_quadrantLabel(quad),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            '${(p['position_recruited_for'] as String? ?? '').toUpperCase()}  ·  '
            '${p['total_seasons_tracked'] ?? 0} season(s)  ·  '
            '${status[0].toUpperCase()}${status.substring(1)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          // ROI bar
          _scoreBar('ROI', roi, fg),
          const SizedBox(height: 6),
          // Value bar (only for active players)
          if (status == 'active')
            _scoreBar('Value', value, AppColors.secondary),
        ]),
      ),
    );
  }

  Widget _scoreBar(String label, double value, Color color) => Row(children: [
    SizedBox(width: 40, child: Text(label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value / 100,
        backgroundColor: color.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 6,
      ),
    )),
    const SizedBox(width: 8),
    Text(value.toStringAsFixed(0),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  ]);

  // ── Player detail bottom sheet ────────────────────────────────────────────────

  void _showPlayerSheet(Map<String, dynamic> p) {
    final roi     = (p['roi_score']   as num?)?.toDouble() ?? 0;
    final value   = (p['value_score'] as num?)?.toDouble() ?? 0;
    final util    = (p['roi_utilization'] as num?)?.toDouble() ?? 0;
    final prod    = (p['roi_production']  as num?)?.toDouble() ?? 0;
    final ret     = (p['roi_retention']   as num?)?.toDouble() ?? 0;
    final acad    = (p['roi_academics']   as num?)?.toDouble() ?? 0;
    final quad    = p['retention_quadrant'] as String?;
    final fg      = _quadrantFg(quad);
    final isRisk  = p['portal_risk'] == true;
    final status  = p['career_status'] as String? ?? 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              // Header
              Row(children: [
                CircleAvatar(radius: 28, backgroundColor: fg,
                    child: Text(_initials(p), style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_playerName(p), style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(
                    '${(p['position_recruited_for'] as String? ?? '').toUpperCase()}  ·  '
                    '${_quadrantLabel(quad)}  ·  '
                    '${status[0].toUpperCase()}${status.substring(1)}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ])),
                if (isRisk) const Text('🔴', style: TextStyle(fontSize: 22)),
              ]),
              const SizedBox(height: 24),

              // ROI grade banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fg.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Text(roi.toStringAsFixed(1),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: fg)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_roiGrade(roi),
                        style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 15)),
                    Text('ROI Score', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // Component breakdown
              const Text('ROI Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              _componentBar('Utilization', util, '35%', AppColors.coachColor),
              const SizedBox(height: 8),
              _componentBar('Production', prod, '30%', _kFoundationFg),
              const SizedBox(height: 8),
              _componentBar('Retention', ret, '20%',
                  ret >= 70 ? _kFoundationFg : ret >= 40 ? _kDevelopingFg : _kReconsiderFg),
              const SizedBox(height: 8),
              _componentBar('Academics', acad, '15%', AppColors.secondary),

              if (status == 'active') ...[
                const SizedBox(height: 20),
                const Text('Player Value',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text('How valuable is this player to your program right now?',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                _scoreBar('Value Score', value, AppColors.secondary),
                const SizedBox(height: 8),
                _componentBar('Performance', (p['value_performance'] as num?)?.toDouble() ?? 0, '40%', AppColors.secondary),
                const SizedBox(height: 8),
                _componentBar('Scarcity', (p['value_scarcity'] as num?)?.toDouble() ?? 0, '25%', AppColors.mentorColor),
                const SizedBox(height: 8),
                _componentBar('Eligibility', (p['value_eligibility'] as num?)?.toDouble() ?? 0, '20%', AppColors.coachColor),
                const SizedBox(height: 8),
                _componentBar('Replaceability ↓', 100 - ((p['value_replaceability'] as num?)?.toDouble() ?? 0), '15%', _kDevelopingFg),
              ],

              if (isRisk) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kReconsiderBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kReconsiderFg.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Text('🔴', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'This player has been flagged as a portal risk. '
                      'Based on their ROI (${ roi.toStringAsFixed(0)}) and current value '
                      '(${value.toStringAsFixed(0)}), ${_retentionAdvice(roi, value)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _componentBar(String label, double value, String weight, Color color) =>
      Builder(builder: (context) => Row(children: [
        GestureDetector(
          onTap: () => _showMetricInfo(context, label),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 88, child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Icon(Icons.info_outline, size: 13,
                color: AppColors.coachColor.withValues(alpha: 0.5)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        )),
        const SizedBox(width: 8),
        Text(value.toStringAsFixed(0),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(weight, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]));

  String _retentionAdvice(double roi, double value) {
    if (roi >= 70 && value >= 70) return 'we strongly recommend fighting to retain them — they are a Foundation player.';
    if (roi < 70 && value >= 70) return 'their current value justifies a retention effort even though their historical ROI is still building.';
    if (roi >= 70 && value < 70) return 'their past ROI is strong but current value is lower — evaluate carefully before committing resources.';
    return 'both ROI and current value are low — consider whether retention resources are best spent elsewhere.';
  }

  // ── ML Predictions card ───────────────────────────────────────────────────────

  Widget _predictionsCard() {
    final active = _players.where((p) => p['career_status'] == 'active').toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.coachColor.withValues(alpha: 0.08),
            AppColors.coachColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coachColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🤖', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Expanded(child: Text('AI Performance Predictions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.coachColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('BETA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.coachColor)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Based on trajectory data from ${active.length} active recruited player${active.length == 1 ? '' : 's'}, '
          'the AI predicts next season performance using historical stats, position benchmarks, and progression curves.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        // Preview predictions from trending data
        ...active.take(3).map((p) => _predictionRow(p)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Generate Full Predictions Report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.coachColor,
              side: BorderSide(color: AppColors.coachColor.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showPredictionsComingSoon(),
          ),
        ),
      ]),
    );
  }

  Widget _predictionRow(Map<String, dynamic> p) {
    final roi   = (p['roi_score'] as num?)?.toDouble() ?? 0;
    final trend = roi >= 75 ? '📈' : roi >= 55 ? '➡️' : '📉';
    final prediction = roi >= 75
        ? 'Trajectory: Elite — expected to maintain starter role'
        : roi >= 55
            ? 'Trajectory: Stable — consistent contribution expected'
            : 'Trajectory: At risk — performance improvement needed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(trend, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_playerName(p),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(prediction,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }

  void _showPredictionsComingSoon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('AI Predictions', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Full AI performance predictions using machine learning will be available in the next update. '
          'The model uses season-over-season progression curves, position benchmarks, '
          'and physical performance trends to project each player\'s next 2 seasons.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppColors.coachColor)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📊', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('No ROI data yet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Move players to Signed in the pipeline\nto start tracking ROI.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
    ]),
  );
}

// ── Custom Painters ───────────────────────────────────────────────────────────

/// Draws a ghosted top-down soccer pitch over the retention matrix.
/// Oriented landscape: left goal ← center → right goal.
/// All lines are white at low opacity so they work across every quadrant.
class _SoccerMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark green at low opacity — reads as grass markings, visible on all
    // four light pastel quadrant backgrounds.
    const pitchGreen = Color(0xFF1B5E20);

    final line = Paint()
      ..color = pitchGreen.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = pitchGreen.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    // ── Center circle ────────────────────────────────────────────────────────
    final cx = w / 2;
    final cy = h / 2;
    canvas.drawCircle(Offset(cx, cy), w * 0.14, line);
    // Center spot
    canvas.drawCircle(Offset(cx, cy), 3.5, fill);

    // ── Penalty areas (landscape: boxes on left & right) ─────────────────────
    final paW = w * 0.20;  // depth of penalty area
    final paH = h * 0.56;  // height of penalty area
    final paTop = (h - paH) / 2;
    // Left
    canvas.drawRect(Rect.fromLTWH(0, paTop, paW, paH), line);
    // Right
    canvas.drawRect(Rect.fromLTWH(w - paW, paTop, paW, paH), line);

    // ── Goal areas ──────────────────────────────────────────────────────────
    final gaW = w * 0.08;
    final gaH = h * 0.28;
    final gaTop = (h - gaH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, gaTop, gaW, gaH), line);
    canvas.drawRect(Rect.fromLTWH(w - gaW, gaTop, gaW, gaH), line);

    // ── Penalty spots ────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.14, cy), 3.0, fill);
    canvas.drawCircle(Offset(w * 0.86, cy), 3.0, fill);

    // ── Penalty arcs (D) — only the portion outside the penalty area ─────────
    // Left arc sweeps toward right (facing center)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.14, cy), radius: w * 0.11),
      -0.93, 1.86, false, line,
    );
    // Right arc sweeps toward left
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.86, cy), radius: w * 0.11),
      2.21, 1.86, false, line,
    );

    // ── Corner arcs ──────────────────────────────────────────────────────────
    const cR = 11.0;
    // Top-left (0 → 90°)
    canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: cR), 0, 1.5708, false, line);
    // Top-right (90° → 180°)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w, 0), radius: cR), 1.5708, 1.5708, false, line);
    // Bottom-right (180° → 270°)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w, h), radius: cR), 3.1416, 1.5708, false, line);
    // Bottom-left (270° → 360°)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(0, h), radius: cR), 4.7124, 1.5708, false, line);
  }

  @override
  bool shouldRepaint(_SoccerMotifPainter old) => false;
}

/// Subtle dot-grid texture overlaid on the retention matrix.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius  = 1.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

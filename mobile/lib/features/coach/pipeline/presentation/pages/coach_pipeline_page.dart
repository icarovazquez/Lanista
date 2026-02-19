import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Coach's Recruiting Pipeline — a horizontal kanban board showing prospects
/// grouped by stage: Identified → Contacted → Evaluated → Offered → Committed
/// (plus Declined / Lost as an archive column).
class CoachPipelinePage extends StatefulWidget {
  const CoachPipelinePage({super.key});

  @override
  State<CoachPipelinePage> createState() => _CoachPipelinePageState();
}

class _CoachPipelinePageState extends State<CoachPipelinePage>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pipeline = [];
  bool _isLoading = true;
  String? _error;
  String? _coachId;

  // Active stages shown as kanban columns (left → right)
  static const _activeStages = [
    'identified',
    'contacted',
    'evaluated',
    'offered',
    'committed',
  ];

  static const _stageLabels = {
    'identified': 'Identified',
    'contacted': 'Contacted',
    'evaluated': 'Evaluated',
    'offered': 'Offered',
    'committed': 'Committed ✅',
    'declined': 'Declined',
    'lost': 'Lost',
  };

  static const _stageColors = {
    'identified': Color(0xFF6B7280),
    'contacted': AppColors.coachColor,
    'evaluated': AppColors.secondary,
    'offered': AppColors.primary,
    'committed': AppColors.success,
    'declined': AppColors.error,
    'lost': Color(0xFF9CA3AF),
  };

  static const _stageEmojis = {
    'identified': '👀',
    'contacted': '📨',
    'evaluated': '🔍',
    'offered': '📋',
    'committed': '🎉',
    'declined': '❌',
    'lost': '🚪',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPipeline();
  }

  Future<void> _loadPipeline() async {
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

      // Get coach ID
      final coachData = await _supabase
          .from('coaches')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (coachData == null) {
        setState(() => _isLoading = false);
        return;
      }

      _coachId = coachData['id'] as String;

      // Load pipeline with player + user info
      final data = await _supabase
          .from('recruiting_pipeline')
          .select('''
            id,
            stage,
            target_year,
            notes,
            last_contact,
            created_at,
            players!inner(
              id,
              primary_position,
              secondary_position,
              graduation_year,
              gpa,
              club_name,
              league,
              users!inner(first_name, last_name)
            )
          ''')
          .eq('coach_id', _coachId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _pipeline = List<Map<String, dynamic>>.from(data as List);
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

  List<Map<String, dynamic>> _prospectsForStage(String stage) {
    return _pipeline.where((p) => p['stage'] == stage).toList();
  }

  Future<void> _moveToStage(String pipelineId, String newStage) async {
    try {
      await _supabase
          .from('recruiting_pipeline')
          .update({'stage': newStage, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', pipelineId);

      setState(() {
        final idx = _pipeline.indexWhere((p) => p['id'] == pipelineId);
        if (idx != -1) _pipeline[idx]['stage'] = newStage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update stage: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeFromPipeline(String pipelineId) async {
    try {
      await _supabase
          .from('recruiting_pipeline')
          .delete()
          .eq('id', pipelineId);

      setState(() {
        _pipeline.removeWhere((p) => p['id'] == pipelineId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from pipeline')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addNotesDialog(Map<String, dynamic> prospect) async {
    final player = prospect['players'] as Map<String, dynamic>;
    final user = player['users'] as Map<String, dynamic>;
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final notesCtrl =
        TextEditingController(text: prospect['notes'] as String? ?? '');

    final saved = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notes — $name'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add recruiting notes…',
            border: OutlineInputBorder(),
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
            ),
            onPressed: () => Navigator.pop(ctx, notesCtrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != null) {
      try {
        await _supabase
            .from('recruiting_pipeline')
            .update({'notes': saved, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', prospect['id'] as String);

        setState(() {
          final idx = _pipeline.indexWhere((p) => p['id'] == prospect['id']);
          if (idx != -1) _pipeline[idx]['notes'] = saved;
        });
      } catch (e) {
        // ignore
      }
    }
  }

  void _showMoveSheet(Map<String, dynamic> prospect) {
    final currentStage = prospect['stage'] as String;
    final player = prospect['players'] as Map<String, dynamic>;
    final user = player['users'] as Map<String, dynamic>;
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move $name to…',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...[..._activeStages, 'declined', 'lost'].map((stage) {
              final isCurrentStage = stage == currentStage;
              final color =
                  _stageColors[stage] ?? AppColors.textSecondary;
              return ListTile(
                leading: Text(
                  _stageEmojis[stage] ?? '',
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(
                  _stageLabels[stage] ?? stage,
                  style: TextStyle(
                    fontWeight: isCurrentStage
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isCurrentStage ? color : AppColors.textPrimary,
                  ),
                ),
                trailing: isCurrentStage
                    ? Icon(Icons.check_circle, color: color)
                    : null,
                onTap: isCurrentStage
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _moveToStage(
                            prospect['id'] as String, stage);
                      },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.error),
              title: const Text(
                'Remove from Pipeline',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _removeFromPipeline(prospect['id'] as String);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.coachColor));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPipeline,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coachColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildKanban()),
      ],
    );
  }

  Widget _buildHeader() {
    final total = _pipeline
        .where((p) => !['declined', 'lost'].contains(p['stage']))
        .length;
    final committed =
        _pipeline.where((p) => p['stage'] == 'committed').length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recruiting Pipeline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total active prospect${total == 1 ? '' : 's'} · $committed committed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadPipeline,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildKanban() {
    if (_pipeline.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _activeStages.length,
      itemBuilder: (context, i) {
        final stage = _activeStages[i];
        final prospects = _prospectsForStage(stage);
        return _KanbanColumn(
          stage: stage,
          label: _stageLabels[stage] ?? stage,
          emoji: _stageEmojis[stage] ?? '',
          color: _stageColors[stage] ?? AppColors.textSecondary,
          prospects: prospects,
          onCardTap: (p) => _showProspectDetail(p),
          onMove: (p) => _showMoveSheet(p),
          onNotes: (p) => _addNotesDialog(p),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📈', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Pipeline is empty',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add players to your pipeline from the Matches or Search tabs by contacting them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadPipeline,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coachColor,
                side: const BorderSide(color: AppColors.coachColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProspectDetail(Map<String, dynamic> prospect) {
    final player = prospect['players'] as Map<String, dynamic>;
    final user = player['users'] as Map<String, dynamic>;
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final stage = prospect['stage'] as String;
    final color = _stageColors[stage] ?? AppColors.textSecondary;
    final notes = prospect['notes'] as String? ?? '';
    final position = player['primary_position'] as String? ?? '';
    final gradYear = player['graduation_year'] as int?;
    final gpa = (player['gpa'] as num?)?.toDouble();
    final club = player['club_name'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
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
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        if (club.isNotEmpty)
                          Text(club,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _stageLabels[stage] ?? stage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (position.isNotEmpty)
                    _DetailChip(label: position, icon: Icons.sports_soccer),
                  if (gradYear != null)
                    _DetailChip(
                        label: 'Class of $gradYear',
                        icon: Icons.school_outlined),
                  if (gpa != null)
                    _DetailChip(
                        label: 'GPA ${gpa.toStringAsFixed(1)}',
                        icon: Icons.grade_outlined),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(notes,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.5)),
                ),
              ],
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Edit Notes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coachColor,
                        side: const BorderSide(
                            color: AppColors.coachColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addNotesDialog(prospect);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Move Stage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coachColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showMoveSheet(prospect);
                      },
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

// ── Kanban Column ─────────────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final String stage;
  final String label;
  final String emoji;
  final Color color;
  final List<Map<String, dynamic>> prospects;
  final void Function(Map<String, dynamic>) onCardTap;
  final void Function(Map<String, dynamic>) onMove;
  final void Function(Map<String, dynamic>) onNotes;

  const _KanbanColumn({
    required this.stage,
    required this.label,
    required this.emoji,
    required this.color,
    required this.prospects,
    required this.onCardTap,
    required this.onMove,
    required this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${prospects.length}',
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
          const SizedBox(height: 8),
          // Cards
          Expanded(
            child: prospects.isEmpty
                ? Center(
                    child: Text(
                      'No prospects',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: prospects.length,
                    itemBuilder: (context, i) => _ProspectCard(
                      prospect: prospects[i],
                      color: color,
                      onTap: () => onCardTap(prospects[i]),
                      onMove: () => onMove(prospects[i]),
                      onNotes: () => onNotes(prospects[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Prospect Card ─────────────────────────────────────────────────────────────

class _ProspectCard extends StatelessWidget {
  final Map<String, dynamic> prospect;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onMove;
  final VoidCallback onNotes;

  const _ProspectCard({
    required this.prospect,
    required this.color,
    required this.onTap,
    required this.onMove,
    required this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    final player = prospect['players'] as Map<String, dynamic>;
    final user = player['users'] as Map<String, dynamic>;
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final position = player['primary_position'] as String? ?? '';
    final gradYear = player['graduation_year'] as int?;
    final gpa = (player['gpa'] as num?)?.toDouble();
    final hasNotes =
        (prospect['notes'] as String? ?? '').isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.isNotEmpty ? name : 'Unknown',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasNotes)
                  const Icon(Icons.note_outlined,
                      size: 14, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (position.isNotEmpty)
                  _MiniTag(label: position, color: color),
                if (gradYear != null)
                  _MiniTag(
                      label: '\'${gradYear.toString().substring(2)}',
                      color: AppColors.secondary),
                if (gpa != null)
                  _MiniTag(
                      label: '${gpa.toStringAsFixed(1)} GPA',
                      color: AppColors.success),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onNotes,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: onMove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Move',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ),
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

// ── Mini widgets ──────────────────────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DetailChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

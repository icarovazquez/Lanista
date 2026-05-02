import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';

class PlayerScheduleAddPage extends StatefulWidget {
  final String playerId;
  const PlayerScheduleAddPage({super.key, required this.playerId});

  @override
  State<PlayerScheduleAddPage> createState() =>
      _PlayerScheduleAddPageState();
}

class _PlayerScheduleAddPageState extends State<PlayerScheduleAddPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _competitionController = TextEditingController();
  final _notesController = TextEditingController();

  String _eventType = 'game';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _competitionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDark) async {
    final now = DateTime.now();
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: accent,
                  onPrimary: PlayerColors.textOnAccent,
                  surface: PlayerColors.surfaceElevated,
                  onSurface: PlayerColors.textPrimary,
                )
              : ColorScheme.light(
                  primary: accent,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isDark) async {
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: accent,
                  onPrimary: PlayerColors.textOnAccent,
                  surface: PlayerColors.surfaceElevated,
                  onSurface: PlayerColors.textPrimary,
                )
              : ColorScheme.light(
                  primary: accent,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (widget.playerId.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _supabase.from('player_schedule').insert({
        'player_id': widget.playerId,
        'event_type': _eventType,
        'title': _titleController.text.trim(),
        'event_date': _selectedDate!.toIso8601String().substring(0, 10),
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim() : null,
        'competition': _competitionController.text.trim().isNotEmpty
            ? _competitionController.text.trim() : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim() : null,
        'event_time': _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
    return PlayerThemeScope(
      service: themeService,
      child: _ScheduleAddContent(
        formKey: _formKey,
        titleController: _titleController,
        locationController: _locationController,
        competitionController: _competitionController,
        notesController: _notesController,
        eventType: _eventType,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        saving: _saving,
        onEventTypeChanged: (v) => setState(() => _eventType = v),
        onPickDate: _pickDate,
        onPickTime: _pickTime,
        onClearTime: () => setState(() => _selectedTime = null),
        onSave: _save,
      ),
    );
  }
}

class _ScheduleAddContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController competitionController;
  final TextEditingController notesController;
  final String eventType;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final bool saving;
  final ValueChanged<String> onEventTypeChanged;
  final Future<void> Function(bool isDark) onPickDate;
  final Future<void> Function(bool isDark) onPickTime;
  final VoidCallback onClearTime;
  final VoidCallback onSave;

  const _ScheduleAddContent({
    required this.formKey,
    required this.titleController,
    required this.locationController,
    required this.competitionController,
    required this.notesController,
    required this.eventType,
    required this.selectedDate,
    required this.selectedTime,
    required this.saving,
    required this.onEventTypeChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onClearTime,
    required this.onSave,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    required bool isDark,
  }) {
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14,
          color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary),
      prefixIcon: prefix,
      filled: true,
      fillColor: isDark ? PlayerColors.surfaceVariant : Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.border : AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.border : AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.error : AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.error : AppColors.error,
              width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final bg = isDark ? PlayerColors.background : AppColors.background;
    final appBarBg = isDark ? PlayerColors.surface : AppColors.primary;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    final textTertiary = isDark ? PlayerColors.textTertiary : AppColors.textTertiary;
    final border = isDark ? PlayerColors.border : AppColors.border;
    final surface = isDark ? PlayerColors.surfaceVariant : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Event',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Event type toggle ─────────────────────────────────────────────
            _FieldLabel(text: 'Event Type', isDark: isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  _TypeTab(
                    label: '⚽  Game',
                    selected: eventType == 'game',
                    onTap: () => onEventTypeChanged('game'),
                    isDark: isDark,
                  ),
                  _TypeTab(
                    label: '🏆  Showcase',
                    selected: eventType == 'showcase',
                    onTap: () => onEventTypeChanged('showcase'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────────────────
            _FieldLabel(
                text: eventType == 'game' ? 'Opponent' : 'Event Name',
                isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                hint: eventType == 'game'
                    ? 'e.g. FC Dallas U19'
                    : 'e.g. Jefferson Cup',
                isDark: isDark,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 20),

            // ── Date ──────────────────────────────────────────────────────────
            _FieldLabel(text: 'Date', isDark: isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onPickDate(isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      selectedDate != null
                          ? _formatDate(selectedDate!)
                          : 'Select date',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate != null
                            ? textPrimary
                            : textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Time ──────────────────────────────────────────────────────────
            _FieldLabel(text: 'Time (optional)', isDark: isDark),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onPickTime(isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 18, color: textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Select time (if known)',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedTime != null
                            ? textPrimary
                            : textTertiary,
                      ),
                    ),
                    if (selectedTime != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onClearTime,
                        child: Icon(Icons.close,
                            size: 16, color: textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Location ──────────────────────────────────────────────────────
            _FieldLabel(text: 'Location (optional)', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: locationController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                hint: 'e.g. Frisco, TX',
                prefix: Icon(Icons.location_on_outlined,
                    size: 18, color: textSecondary),
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 20),

            // ── Competition ───────────────────────────────────────────────────
            _FieldLabel(text: 'Competition (optional)', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: competitionController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                hint: 'e.g. MLS Next, ECNL, Jefferson Cup',
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────────────────────
            _FieldLabel(text: 'Notes (optional)', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                hint: 'e.g. Away game, Field 3',
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 32),

            // ── Save ──────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: saving
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? PlayerColors.textOnAccent : Colors.white,
                        ),
                      )
                    : const Text('Save Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: selected
                  ? (isDark ? PlayerColors.textOnAccent : Colors.white)
                  : (isDark ? PlayerColors.textSecondary : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
      ),
    );
  }
}

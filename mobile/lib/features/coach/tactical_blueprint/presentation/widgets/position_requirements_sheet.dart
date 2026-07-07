import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../data/tactical_blueprint_data.dart';

/// Bottom sheet for setting requirements for a specific position.
/// Covers both free-form quality tags and structured physical/academic requirements
/// that feed directly into the matching engine.
class PositionRequirementsSheet extends StatefulWidget {
  final BlueprintPosition position;
  final List<PlayerQuality> allQualities;
  final List<String> selectedQualities;

  // Structured requirements (nullable = not set)
  final int? minHeightCm;
  final String? preferredFoot;     // 'left' | 'right' | 'both' | 'any'
  final int? minSpeedRating;
  final double? minGpa;
  final String? minPhysicalBuild;  // 'any' | 'slight_ok' | 'athletic' | 'powerful'

  final void Function(
    List<String> qualities,
    int? minHeightCm,
    String? preferredFoot,
    int? minSpeedRating,
    double? minGpa,
    String? minPhysicalBuild,
  ) onSaved;

  const PositionRequirementsSheet({
    super.key,
    required this.position,
    required this.allQualities,
    required this.selectedQualities,
    required this.onSaved,
    this.minHeightCm,
    this.preferredFoot,
    this.minSpeedRating,
    this.minGpa,
    this.minPhysicalBuild,
  });

  @override
  State<PositionRequirementsSheet> createState() => _PositionRequirementsSheetState();
}

class _PositionRequirementsSheetState extends State<PositionRequirementsSheet> {
  late List<String> _selected;

  // Structured fields
  final _heightCtrl = TextEditingController();
  final _gpaCtrl    = TextEditingController();
  String _preferredFoot    = 'any';
  String _minPhysicalBuild = 'any';
  int?   _minSpeedRating;

  static const _footOptions = [
    ('any',   'Any'),
    ('left',  'Left'),
    ('right', 'Right'),
    ('both',  'Both'),
  ];

  static const _buildOptions = [
    ('any',       'Any',              'No minimum build requirement'),
    ('slight_ok', 'Slight OK',        'Lean players accepted — any build'),
    ('athletic',  'Athletic minimum', 'Must have athletic or powerful build'),
    ('powerful',  'Powerful',         'Must have powerful build — CB, CDM, ST'),
  ];

  @override
  void initState() {
    super.initState();
    _selected        = List.from(widget.selectedQualities);
    _preferredFoot   = widget.preferredFoot ?? 'any';
    _minPhysicalBuild = widget.minPhysicalBuild ?? 'any';
    _minSpeedRating  = widget.minSpeedRating;
    if (widget.minHeightCm != null) _heightCtrl.text = widget.minHeightCm.toString();
    if (widget.minGpa != null) _gpaCtrl.text = widget.minGpa!.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _gpaCtrl.dispose();
    super.dispose();
  }

  void _toggleQuality(String qualityId) {
    setState(() {
      if (_selected.contains(qualityId)) {
        _selected.remove(qualityId);
      } else {
        if (_selected.length < 8) _selected.add(qualityId);
      }
    });
  }

  void _save() {
    final height = int.tryParse(_heightCtrl.text.trim());
    final gpa    = double.tryParse(_gpaCtrl.text.trim());
    final speed  = _minSpeedRating;
    final foot   = _preferredFoot == 'any' ? null : _preferredFoot;
    final build  = _minPhysicalBuild == 'any' ? null : _minPhysicalBuild;
    widget.onSaved(_selected, height, foot, speed, gpa, build);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = TacticalBlueprintData.qualityCategories;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.coachColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(widget.position.abbreviation,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.coachColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.position.positionName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('${_selected.length} qualities · matching engine requirements',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Matching Engine Requirements ──────────────────────────
                  _sectionHeader('Matching Engine Requirements',
                    'These feed directly into player match scores', AppColors.secondary),
                  const SizedBox(height: 12),

                  // Height + GPA row
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          controller: _heightCtrl,
                          label: 'Min height (cm)',
                          hint: 'e.g. 175',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _inputField(
                          controller: _gpaCtrl,
                          label: 'Min GPA',
                          hint: 'e.g. 3.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preferred foot
                  Text('Preferred Foot',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: _footOptions.map((opt) {
                      final isSelected = _preferredFoot == opt.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _preferredFoot = opt.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.coachColor : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.coachColor : AppColors.border),
                            ),
                            child: Text(opt.$2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textPrimary)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Min speed rating
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Min Speed Rating',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      ),
                      Text(
                        _minSpeedRating != null ? '${_minSpeedRating}/10' : 'Not set',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _minSpeedRating != null
                              ? AppColors.coachColor : AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Slider(
                    value: (_minSpeedRating ?? 0).toDouble(),
                    min: 0, max: 10, divisions: 10,
                    activeColor: AppColors.coachColor,
                    inactiveColor: AppColors.border,
                    onChanged: (v) => setState(() =>
                        _minSpeedRating = v == 0 ? null : v.round()),
                  ),
                  const SizedBox(height: 4),

                  // Physical build
                  Text('Minimum Physical Build',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Based on height + weight. Ensures player won\'t be pushed off the ball.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...(_buildOptions.map((opt) {
                    final isSelected = _minPhysicalBuild == opt.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _minPhysicalBuild = opt.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.coachColor.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.coachColor : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.coachColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.coachColor : AppColors.border,
                                  width: 2),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opt.$2,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.coachColor : AppColors.textPrimary)),
                                  Text(opt.$3,
                                    style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 4),

                  // ── Quality Tags ──────────────────────────────────────────
                  _sectionHeader('Player Qualities',
                    'Select up to 8 · ${_selected.length} selected', AppColors.coachColor),
                  const SizedBox(height: 8),

                  ...categories.map((category) {
                    final categoryQualities = widget.allQualities
                        .where((q) => q.category == category)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 4, height: 14,
                                decoration: BoxDecoration(
                                  color: _categoryColor(category),
                                  borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              Text(category,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                    color: _categoryColor(category))),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: categoryQualities.map((quality) {
                            final isSelected = _selected.contains(quality.id);
                            final isDisabled = !isSelected && _selected.length >= 8;
                            return GestureDetector(
                              onTap: isDisabled ? null : () => _toggleQuality(quality.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.coachColor
                                      : isDisabled ? AppColors.surface : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.coachColor : AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(quality.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : isDisabled
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Save / Cancel buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coachColor),
                    onPressed: _save,
                    child: const Text('Save Requirements',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.coachColor, width: 2)),
        ),
      );

  Color _categoryColor(String category) {
    switch (category) {
      case 'Technical': return AppColors.coachColor;
      case 'Physical':  return AppColors.playerColor;
      case 'Tactical':  return AppColors.secondary;
      case 'Character': return AppColors.mentorColor;
      default:          return AppColors.textSecondary;
    }
  }
}

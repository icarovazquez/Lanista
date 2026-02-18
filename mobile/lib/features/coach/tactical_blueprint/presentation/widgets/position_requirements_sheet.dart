import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../data/tactical_blueprint_data.dart';

/// Bottom sheet for selecting player qualities required for a specific position.
class PositionRequirementsSheet extends StatefulWidget {
  final BlueprintPosition position;
  final List<PlayerQuality> allQualities;
  final List<String> selectedQualities;
  final ValueChanged<List<String>> onSaved;

  const PositionRequirementsSheet({
    super.key,
    required this.position,
    required this.allQualities,
    required this.selectedQualities,
    required this.onSaved,
  });

  @override
  State<PositionRequirementsSheet> createState() => _PositionRequirementsSheetState();
}

class _PositionRequirementsSheetState extends State<PositionRequirementsSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedQualities);
  }

  void _toggleQuality(String qualityId) {
    setState(() {
      if (_selected.contains(qualityId)) {
        _selected.remove(qualityId);
      } else {
        if (_selected.length < 8) {
          _selected.add(qualityId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = TacticalBlueprintData.qualityCategories;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
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
                        fontWeight: FontWeight.w800,
                        color: AppColors.coachColor,
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        'Select up to 8 qualities • ${_selected.length} selected',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categories.map((category) {
                  final categoryQualities = widget.allQualities
                      .where((q) => q.category == category)
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _categoryColor(category),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _categoryColor(category),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoryQualities.map((quality) {
                          final isSelected = _selected.contains(quality.id);
                          final isDisabled = !isSelected && _selected.length >= 8;
                          return GestureDetector(
                            onTap: isDisabled ? null : () => _toggleQuality(quality.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.coachColor
                                    : isDisabled
                                        ? AppColors.surface
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.coachColor
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(Icons.check,
                                        color: Colors.white, size: 13),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    quality.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : isDisabled
                                              ? AppColors.textSecondary
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                    onPressed: () {
                      widget.onSaved(_selected);
                      Navigator.pop(context);
                    },
                    child: Text('Save ${_selected.length} Qualities'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Technical':
        return AppColors.coachColor;
      case 'Physical':
        return AppColors.playerColor;
      case 'Tactical':
        return AppColors.secondary;
      case 'Character':
        return AppColors.mentorColor;
      default:
        return AppColors.textSecondary;
    }
  }
}

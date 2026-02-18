import 'package:flutter/material.dart';

/// Animated linear progress indicator for multi-step flows.
class StepProgressIndicator extends StatelessWidget {
  final int total;
  final int current;
  final Color color;

  const StepProgressIndicator({
    super.key,
    required this.total,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: List.generate(total, (i) {
          final isCompleted = i <= current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: isCompleted ? color : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../data/tactical_blueprint_data.dart';

/// Visual soccer field with position dots representing the selected formation.
/// Dots glow green when qualities have been defined for that position.
class FormationFieldWidget extends StatelessWidget {
  final FormationInfo formation;
  final Map<String, List<String>> positionQualities;
  final ValueChanged<BlueprintPosition> onPositionTap;

  const FormationFieldWidget({
    super.key,
    required this.formation,
    required this.positionQualities,
    required this.onPositionTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const aspectRatio = 0.65; // soccer field ratio
        final height = width / aspectRatio;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF2D7A3F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Field markings
              CustomPaint(
                size: Size(width, height),
                painter: _FieldPainter(),
              ),
              // Formation label
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      formation.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Position dots
              ...formation.positions.map((pos) {
                final hasQualities = (positionQualities[pos.positionId] ?? []).isNotEmpty;
                final dotX = pos.x * width;
                final dotY = pos.y * height;

                return Positioned(
                  left: dotX - 22,
                  top: dotY - 22,
                  child: GestureDetector(
                    onTap: () => onPositionTap(pos),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasQualities
                                ? AppColors.coachColor
                                : Colors.white.withValues(alpha: 0.85),
                            border: Border.all(
                              color: hasQualities ? Colors.white : Colors.white.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: hasQualities
                                ? [
                                    BoxShadow(
                                      color: AppColors.coachColor.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              pos.abbreviation.length > 3 ? pos.abbreviation.substring(0, 3) : pos.abbreviation,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: hasQualities ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Outer boundary
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, 8, w - 16, h - 16), const Radius.circular(12)),
      paint,
    );

    // Center line
    canvas.drawLine(Offset(8, h / 2), Offset(w - 8, h / 2), paint);

    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.1, paint);
    canvas.drawCircle(Offset(w / 2, h / 2), 3, Paint()..color = Colors.white.withValues(alpha: 0.4));

    // Top penalty box
    final penBoxW = w * 0.55;
    final penBoxH = h * 0.16;
    canvas.drawRect(
      Rect.fromLTWH((w - penBoxW) / 2, 8, penBoxW, penBoxH),
      paint,
    );

    // Bottom penalty box
    canvas.drawRect(
      Rect.fromLTWH((w - penBoxW) / 2, h - 8 - penBoxH, penBoxW, penBoxH),
      paint,
    );

    // Top goal box
    final goalBoxW = w * 0.28;
    final goalBoxH = h * 0.07;
    canvas.drawRect(
      Rect.fromLTWH((w - goalBoxW) / 2, 8, goalBoxW, goalBoxH),
      paint,
    );

    // Bottom goal box
    canvas.drawRect(
      Rect.fromLTWH((w - goalBoxW) / 2, h - 8 - goalBoxH, goalBoxW, goalBoxH),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FieldPainter oldDelegate) => false;
}

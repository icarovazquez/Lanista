import 'package:flutter/material.dart';

/// Dark / Electric color palette for the player-facing side of Lanista.
/// Coach side continues to use [AppColors] so this file is completely isolated.
class PlayerColors {
  PlayerColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0A0A0A); // near-black page bg
  static const Color surface        = Color(0xFF141414); // card bg
  static const Color surfaceVariant = Color(0xFF1E1E1E); // input / chip bg
  static const Color surfaceElevated= Color(0xFF242424); // bottom sheet, modal

  // ── Hero gradient (Design D) ──────────────────────────────────────────────────
  static const Color gradientStart  = Color(0xFF7C3AED); // purple  — gradient start
  static const Color gradientEnd    = Color(0xFF2563EB); // blue    — gradient end

  // ── Neon lime accent ─────────────────────────────────────────────────────────
  static const Color accent         = Color(0xFFC8F135); // neon lime — primary CTA
  static const Color accentDim      = Color(0x33C8F135); // 20 % — indicator bg
  static const Color accentSubtle   = Color(0x1AC8F135); // 10 % — card tints

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFAAAAAA);
  static const Color textTertiary   = Color(0xFF555555);
  static const Color textOnAccent   = Color(0xFF0A0A0A); // black text on lime

  // ── Borders ──────────────────────────────────────────────────────────────────
  static const Color border         = Color(0xFF2A2A2A);
  static const Color borderAccent   = Color(0xFF3D4D1A); // lime-tinted border

  // ── Semantic ─────────────────────────────────────────────────────────────────
  /// Brighter variants tuned for dark backgrounds.
  static const Color success        = Color(0xFF4ADE80);
  static const Color warning        = Color(0xFFFBBF24);
  static const Color error          = Color(0xFFF87171);
  static const Color info           = Color(0xFF60A5FA);

  // ── Convenience helpers ───────────────────────────────────────────────────────

  /// Returns the right colour for a match / fit score displayed on dark bg.
  static Color scoreColor(int score) {
    if (score >= 75) return accent;
    if (score >= 55) return warning;
    return textSecondary;
  }
}

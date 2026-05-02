import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_colors.dart';

/// Dark Material3 ThemeData for the player-facing UI (Design D).
/// Applied at the PlayerDashboardPage level via a Theme widget so
/// it only affects players — the coach side uses AppTheme.lightTheme.
class PlayerThemeData {
  const PlayerThemeData._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: PlayerColors.accent,
        onPrimary: PlayerColors.textOnAccent,
        primaryContainer: PlayerColors.accentDim,
        secondary: PlayerColors.gradientStart,
        onSecondary: Colors.white,
        surface: PlayerColors.surface,
        onSurface: PlayerColors.textPrimary,
        surfaceContainerHighest: PlayerColors.surfaceVariant,
        error: PlayerColors.error,
        onError: Colors.white,
        outline: PlayerColors.border,
      ),
      scaffoldBackgroundColor: PlayerColors.background,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: PlayerColors.surface,
        foregroundColor: PlayerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: PlayerColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: PlayerColors.textPrimary),
      ),

      // ── Navigation Bar ───────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PlayerColors.surface,
        indicatorColor: PlayerColors.accentDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: PlayerColors.accent, size: 24);
          }
          return const IconThemeData(
              color: PlayerColors.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: PlayerColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: PlayerColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Elevated Button ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PlayerColors.accent,
          foregroundColor: PlayerColors.textOnAccent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlayerColors.accent,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: PlayerColors.accent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PlayerColors.accent,
        ),
      ),

      // ── Input Decoration ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PlayerColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PlayerColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PlayerColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PlayerColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: PlayerColors.textSecondary),
        hintStyle: const TextStyle(color: PlayerColors.textTertiary),
      ),

      // ── Card ─────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: PlayerColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PlayerColors.border),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Divider ──────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: PlayerColors.border,
        thickness: 1,
      ),

      // ── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PlayerColors.textOnAccent;
          }
          return PlayerColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PlayerColors.accent;
          }
          return PlayerColors.surfaceVariant;
        }),
      ),

      // ── Text ─────────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: PlayerColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: PlayerColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PlayerColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: PlayerColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PlayerColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: PlayerColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: PlayerColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: PlayerColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: PlayerColors.textPrimary,
        ),
      ),
    );
  }
}

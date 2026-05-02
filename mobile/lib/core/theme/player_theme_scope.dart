import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Enum ──────────────────────────────────────────────────────────────────────

enum PlayerThemeMode { dark, light }

// ── Service ───────────────────────────────────────────────────────────────────

/// Persists and broadcasts the player's preferred theme mode.
/// Register as a singleton via GetIt; call [PlayerThemeService.init] once
/// during app startup after SharedPreferences is available.
class PlayerThemeService extends ValueNotifier<PlayerThemeMode> {
  static const _key = 'player_theme_mode';

  PlayerThemeService() : super(PlayerThemeMode.dark); // default: dark (Design D)

  /// Must be called once at startup (after SharedPreferences is ready).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'light') {
      value = PlayerThemeMode.light;
    }
    // otherwise keep default: dark
  }

  void toggle() {
    final next =
        value == PlayerThemeMode.dark ? PlayerThemeMode.light : PlayerThemeMode.dark;
    _persist(next);
    value = next;
  }

  void setMode(PlayerThemeMode mode) {
    _persist(mode);
    value = mode;
  }

  Future<void> _persist(PlayerThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

// ── InheritedNotifier ─────────────────────────────────────────────────────────

/// Place this at the root of the player widget tree (inside PlayerDashboardPage).
/// Any descendant can call [PlayerThemeScope.isDark(context)] and will
/// automatically rebuild when the theme mode changes.
class PlayerThemeScope extends InheritedNotifier<PlayerThemeService> {
  const PlayerThemeScope({
    super.key,
    required PlayerThemeService service,
    required super.child,
  }) : super(notifier: service);

  /// Returns true when the current player theme is dark (Design D).
  static bool isDark(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlayerThemeScope>();
    return scope?.notifier?.value == PlayerThemeMode.dark;
  }

  /// Returns the current [PlayerThemeMode].
  static PlayerThemeMode of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlayerThemeScope>();
    return scope?.notifier?.value ?? PlayerThemeMode.dark;
  }
}

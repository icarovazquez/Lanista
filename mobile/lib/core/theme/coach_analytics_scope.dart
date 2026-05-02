import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Service ───────────────────────────────────────────────────────────────────

/// Persists and broadcasts the coach's Analytics Mode preference.
/// Standard Mode = simplified dashboard for head coaches.
/// Analytics Mode = deep metrics, ROI charts, and benchmarks for
/// data-savvy assistant coaches / analytics staff.
class CoachAnalyticsService extends ValueNotifier<bool> {
  static const _key = 'coach_analytics_mode';

  CoachAnalyticsService() : super(false); // default: Standard Mode

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_key) ?? false;
  }

  void toggle() {
    value = !value;
    _persist(value);
  }

  void setMode(bool analyticsOn) {
    value = analyticsOn;
    _persist(analyticsOn);
  }

  Future<void> _persist(bool mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, mode);
  }
}

// ── InheritedNotifier ─────────────────────────────────────────────────────────

/// Place this at the root of the coach widget tree (inside CoachDashboardPage).
/// Any descendant can call [CoachAnalyticsScope.isEnabled(context)] and will
/// automatically rebuild when analytics mode changes.
class CoachAnalyticsScope extends InheritedNotifier<CoachAnalyticsService> {
  const CoachAnalyticsScope({
    super.key,
    required CoachAnalyticsService service,
    required super.child,
  }) : super(notifier: service);

  /// Returns true when Analytics Mode is active.
  static bool isEnabled(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CoachAnalyticsScope>();
    return scope?.notifier?.value ?? false;
  }

  /// Returns the service so callers can toggle it.
  static CoachAnalyticsService? of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CoachAnalyticsScope>();
    return scope?.notifier;
  }
}

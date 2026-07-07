import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches and caches remote feature flags from the app_config table.
/// Call [fetch] once at app startup (before routing). All flags are then
/// available synchronously via static getters for the rest of the session.
class AppConfigService {
  AppConfigService._();

  static bool _coachAccessEnabled = false;
  static bool _fetched = false;

  /// Whether the coach signup/onboarding flow is open to the public.
  /// Returns false until [fetch] completes (safe default — keeps coach side hidden).
  static bool get coachAccessEnabled => _coachAccessEnabled;

  /// Fetches the config row from Supabase. Safe to call multiple times —
  /// subsequent calls are no-ops once fetched.
  static Future<void> fetch() async {
    if (_fetched) return;
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          .select('coach_access_enabled')
          .eq('id', 1)
          .single();
      _coachAccessEnabled = (data['coach_access_enabled'] as bool?) ?? false;
    } catch (e) {
      // On error keep safe defaults (coach hidden)
      _coachAccessEnabled = false;
    }
    _fetched = true;
  }

  /// Force-refresh the config (e.g. after a flag flip in production).
  static Future<void> refresh() async {
    _fetched = false;
    await fetch();
  }
}

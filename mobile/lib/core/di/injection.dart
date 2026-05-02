import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/player_theme_scope.dart';
import '../theme/coach_analytics_scope.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Supabase client
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Player theme service (dark/light mode toggle, persisted via SharedPreferences)
  final playerThemeService = PlayerThemeService();
  await playerThemeService.init();
  getIt.registerSingleton<PlayerThemeService>(playerThemeService);

  // Coach analytics mode (standard vs analytics, persisted via SharedPreferences)
  final coachAnalyticsService = CoachAnalyticsService();
  await coachAnalyticsService.init();
  getIt.registerSingleton<CoachAnalyticsService>(coachAnalyticsService);
}

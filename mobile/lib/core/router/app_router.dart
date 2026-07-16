import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/player/profile/presentation/pages/player_dashboard_page.dart';
import '../../features/player/profile/presentation/pages/player_profile_setup_page.dart';
import '../../features/player/profile/presentation/pages/player_profile_page.dart';
import '../../features/coach/roster_map/presentation/pages/coach_dashboard_page.dart';
import '../../features/coach/tactical_blueprint/presentation/pages/tactical_blueprint_page.dart';
import '../../features/coach/roi/presentation/pages/coach_roi_page.dart';
import '../../features/parent/companion/presentation/pages/parent_dashboard_page.dart';
import '../../features/mentor/dashboard/presentation/pages/mentor_dashboard_page.dart';
import '../../features/education/presentation/pages/education_page.dart';
import '../../features/education/presentation/widgets/article_detail_page.dart';
import '../../features/education/data/education_articles.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/player/profile/presentation/pages/player_profile_views_page.dart';
import '../../features/player/roadmap/presentation/pages/player_roadmap_page.dart';
import '../../features/player/openings/presentation/pages/player_openings_page.dart';
import '../../features/player/schools/presentation/pages/player_my_schools_page.dart';

/// Notifier that listens to Supabase auth state changes and notifies GoRouter.
class SupabaseAuthNotifier extends ChangeNotifier {
  SupabaseAuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _authNotifier = SupabaseAuthNotifier();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;

      // Routes that don't require auth
      final isPublicRoute = loc.startsWith('/auth') || loc == '/splash';

      // Not logged in trying to access protected route → login
      if (!isLoggedIn && !isPublicRoute) return '/auth/login';

      // Login page handles its own post-sign-in navigation (including biometric setup offer)
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final skip = extra?['skipBiometrics'] == true;
          return LoginPage(skipBiometrics: skip);
        },
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/auth/role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),

      // ── Player Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/player/dashboard',
        builder: (context, state) => const PlayerDashboardPage(),
      ),
      GoRoute(
        path: '/player/profile-views',
        builder: (context, state) => const PlayerProfileViewsPage(),
      ),
      GoRoute(
        path: '/player/roadmap',
        builder: (context, state) => const PlayerRoadmapPage(),
      ),
      GoRoute(
        path: '/player/openings',
        builder: (context, state) => const PlayerOpeningsPage(),
      ),
      GoRoute(
        path: '/player/my-schools',
        builder: (context, state) => const PlayerMySchoolsPage(),
      ),
      GoRoute(
        path: '/player/profile',
        builder: (context, state) => const PlayerProfilePage(),
      ),
      GoRoute(
        path: '/player/profile/setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final startPage = extra?['startPage'] as int? ?? 0;
          return PlayerProfileSetupPage(startPage: startPage);
        },
      ),

      // ── Coach Routes ───────────────────────────────────────────────────────
      GoRoute(
        path: '/coach/dashboard',
        builder: (context, state) => const CoachDashboardPage(),
      ),
      GoRoute(
        path: '/coach/tactical-blueprint',
        builder: (context, state) => const TacticalBlueprintPage(),
      ),
      GoRoute(
        path: '/coach/roi',
        builder: (context, state) => const CoachRoiPage(),
      ),

      // ── Parent Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/parent/dashboard',
        builder: (context, state) => const ParentDashboardPage(),
      ),

      // ── Mentor Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/mentor/dashboard',
        builder: (context, state) => const MentorDashboardPage(),
      ),

      // ── Notifications ──────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // ── Education Routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/education',
        builder: (context, state) => const EducationPage(),
      ),
      GoRoute(
        path: '/education/:articleId',
        builder: (context, state) {
          final articleId = state.pathParameters['articleId']!;
          final article = EducationData.articles
              .firstWhere((a) => a.id == articleId,
                  orElse: () => EducationData.articles.first);
          return ArticleDetailPage(article: article);
        },
      ),
    ],
  );
}

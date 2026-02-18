import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/player/profile/presentation/pages/player_dashboard_page.dart';
import '../../features/player/profile/presentation/pages/player_profile_setup_page.dart';
import '../../features/coach/roster_map/presentation/pages/coach_dashboard_page.dart';
import '../../features/coach/tactical_blueprint/presentation/pages/tactical_blueprint_page.dart';
import '../../features/parent/companion/presentation/pages/parent_dashboard_page.dart';
import '../../features/mentor/dashboard/presentation/pages/mentor_dashboard_page.dart';
import '../../features/education/presentation/pages/education_page.dart';
import '../../features/education/presentation/widgets/article_detail_page.dart';
import '../../features/education/data/education_articles.dart';

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

      // Logged in on login page → go to splash to determine dashboard
      if (isLoggedIn && loc == '/auth/login') return '/splash';

      // Already logged in, don't redirect role-selection or any other auth route
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
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
        path: '/player/profile/setup',
        builder: (context, state) => const PlayerProfileSetupPage(),
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

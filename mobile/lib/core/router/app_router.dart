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

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && state.matchedLocation == '/auth/login') {
        return '/splash'; // Let splash handle role-based redirect
      }
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
    ],
  );
}

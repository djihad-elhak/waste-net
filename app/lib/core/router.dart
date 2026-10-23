// ─────────────────────────────────────────────────────────────────────────────
// FINAL INTEGRATION – Complete router.dart for the full TrashGo app
// Replace your existing lib/core/router.dart with this file.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValueX, Provider;
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/features/auth/auth.dart';
import 'package:trash/features/claim_map/claim_map.dart';
import 'package:trash/features/claiming/claiming.dart';
import 'package:trash/features/home/home.dart';
import 'package:trash/features/missions/missions.dart';
import 'package:trash/features/profile/profile.dart' show ProfileScreen;
import 'package:trash/features/social/social.dart';
import 'package:trash/shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authAsync = authState;
      if (authAsync.isLoading) return null;
      final isAuthenticated = authState.valueOrNull != null;
      final loc = state.uri.toString();

      final authRoutes = [
        AppConstants.routeLogin,
        AppConstants.routeRegister,
        AppConstants.routeRegisterDetails,
        AppConstants.routeForgotPassword,
        AppConstants.routeOnboarding,
        AppConstants.routeSplash,
      ];

      if (isAuthenticated && authRoutes.contains(loc)) {
        return AppConstants.routeHome;
      }

      final protectedPrefixes = [
        AppConstants.routeHome,
        AppConstants.routeCamera,
        AppConstants.routeResult,
        AppConstants.routeMap,
        AppConstants.routeMissions,
        AppConstants.routeSocial,
        AppConstants.routeProfile,
        AppConstants.routeRewards,
      ];

      if (!isAuthenticated &&
          protectedPrefixes.any((r) => loc.startsWith(r))) {
        return AppConstants.routeLogin;
      }

      return null;
    },
    routes: [
      // ── Auth routes (no shell) ─────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeOnboarding,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _fade,
        ),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _slide,
        ),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slide,
        ),
      ),
      GoRoute(
        path: AppConstants.routeRegisterDetails,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ProfileSetupScreen(
              uid: extra?['uid'] as String? ?? '',
              email: extra?['email'] as String? ?? '',
            ),
            transitionsBuilder: _slide,
          );
        },
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _slide,
        ),
      ),

      // ── Camera + Result (full-screen, no shell) ────────────────────
      GoRoute(
        path: AppConstants.routeCamera,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CameraScreen(),
          transitionsBuilder: _fade,
        ),
      ),
      GoRoute(
        path: AppConstants.routeResult,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ResultScreen(),
          transitionsBuilder: _slideUp,
        ),
      ),

      // ── Main app shell (persistent bottom nav + FAB) ───────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeHome,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: _fade,
            ),
          ),
          GoRoute(
            path: AppConstants.routeMap,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ClaimMapScreen(),
              transitionsBuilder: _fade,
            ),
          ),
          GoRoute(
            path: AppConstants.routeMissions,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MissionsScreen(),
              transitionsBuilder: _fade,
            ),
          ),
          GoRoute(
            path: AppConstants.routeSocial,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SocialScreen(),
              transitionsBuilder: _fade,
            ),
          ),
          GoRoute(
            path: AppConstants.routeProfile,
            pageBuilder: (_, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: _fade,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

// ── Transitions ───────────────────────────────────────────────────────────────
Widget _fade(_, animation, __, child) =>
    FadeTransition(opacity: animation, child: child);

Widget _slide(_, animation, __, child) => SlideTransition(
    position: Tween<Offset>(
        begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
    child: child);

Widget _slideUp(_, animation, __, child) => SlideTransition(
    position: Tween<Offset>(
        begin: const Offset(0.0, 1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
    child: child);

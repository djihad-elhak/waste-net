import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:trash/features/auth/presentation/screens/login_screen.dart';
import 'package:trash/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:trash/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:trash/features/auth/presentation/screens/register_screen.dart';
import 'package:trash/features/auth/presentation/screens/splash_screen.dart';

// Placeholder screens for unbuilt features
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Home – coming soon')),
      );
}

// ─────────────────────────────────────────────────────────────
// Router Provider
// ─────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = [
        AppConstants.routeLogin,
        AppConstants.routeRegister,
        AppConstants.routeRegisterDetails,
        AppConstants.routeForgotPassword,
        AppConstants.routeOnboarding,
        AppConstants.routeSplash,
      ].contains(state.fullPath);

      // If authenticated and on auth route → go home
      if (isAuthenticated && isAuthRoute) {
        return AppConstants.routeHome;
      }

      // If not authenticated and trying to access protected route → go login
      final isProtectedRoute = [
        AppConstants.routeHome,
        AppConstants.routeCamera,
        AppConstants.routeResult,
        AppConstants.routeMap,
        AppConstants.routeMissions,
        AppConstants.routeSocial,
        AppConstants.routeProfile,
        AppConstants.routeRewards,
      ].any((r) => state.fullPath?.startsWith(r) ?? false);

      if (!isAuthenticated && isProtectedRoute) {
        return AppConstants.routeLogin;
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Onboarding ──────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeOnboarding,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeLogin,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      GoRoute(
        path: AppConstants.routeRegister,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideTransition,
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
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      GoRoute(
        path: AppConstants.routeForgotPassword,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // ── Main App ─────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeHome,
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],

    // Error page
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

// ─── Transitions ─────────────────────────────────────────────
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
    child: child,
  );
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

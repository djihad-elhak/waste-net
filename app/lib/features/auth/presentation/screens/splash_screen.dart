import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/data/providers/auth_providers.dart';
import 'package:trash/features/auth/presentation/widgets/auth_widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );

    _animCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

    if (!onboardingDone) {
      if (mounted) context.go(AppConstants.routeOnboarding);
      return;
    }

    // Wait for Firebase Auth to initialise (max 3 seconds)
    // authStateProvider is a StreamProvider — .value is null while loading
    // We listen to the underlying Firebase stream directly for reliability
    try {
      final completer = Completer<void>();

      fb.FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (!mounted) return;
        if (user != null) {
          context.go(AppConstants.routeHome);
        } else {
          context.go(AppConstants.routeLogin);
        }
        if (!completer.isCompleted) completer.complete();
      }).catchError((_) {
        if (mounted) context.go(AppConstants.routeLogin);
        if (!completer.isCompleted) completer.complete();
      });

      // Timeout safety — never stay black for more than 4 seconds
      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 4)),
      ]);

      // If timeout hit and we're still on splash, go to login
      if (mounted && ModalRoute.of(context)?.settings.name == '/') {
        context.go(AppConstants.routeLogin);
      }
    } catch (_) {
      if (mounted) context.go(AppConstants.routeLogin);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.forestGreen.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Logo
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: const TrashGoLogo(size: 88),
              ),
            ),
          ),
          // Loading indicator at bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'v1.0.0',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/auth/presentation/widgets/auth_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      emoji: '📸',
      title: 'Snap litter,\nearn coins',
      description:
          'Point your camera at any trash on the street. Our AI instantly recognizes it and rewards you with coins and stars.',
      accentColor: AppColors.accentGreen,
    ),
    _OnboardingSlide(
      emoji: '🗺️',
      title: 'See your city\nget cleaner',
      description:
          'Watch your claims appear on the map. See hot zones, compete with your neighbourhood, and track your real-world impact.',
      accentColor: AppColors.orange,
    ),
    _OnboardingSlide(
      emoji: '🎁',
      title: 'Redeem real\nrewards',
      description:
          'Turn your coins into free internet, coffee vouchers, cinema tickets, and more from our local partners.',
      accentColor: Color(0xFF7C6CFF),
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) context.go(AppConstants.routeLogin);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background blob
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            top: -60,
            right: _currentPage == 0 ? -60 : (_currentPage == 1 ? 20 : -20),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _slides[_currentPage].accentColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text('Skip', style: AppTextStyles.labelMedium),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => _OnboardingPage(slide: _slides[i]),
                  ),
                ),

                // Indicators + Next
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? _slides[_currentPage].accentColor
                                  : AppColors.cardBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      AppPrimaryButton(
                        label: _currentPage == _slides.length - 1
                            ? 'Get Started 🌱'
                            : 'Next',
                        onPressed: _next,
                        backgroundColor: _slides[_currentPage].accentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data ────────────────────────────────────────────────────
class _OnboardingSlide {
  final String emoji;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

// ─── Slide Widget ─────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji illustration
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: slide.accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: slide.accentColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                slide.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            slide.title,
            style: AppTextStyles.displayLarge.copyWith(
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [slide.accentColor, slide.accentColor.withOpacity(0.7)],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 60)),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            slide.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

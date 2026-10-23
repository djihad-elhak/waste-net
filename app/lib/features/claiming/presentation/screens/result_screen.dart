import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/claiming/data/datasources/trash_label_map.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';
import 'package:trash/features/claiming/domain/usecases/classify_trash_use_case.dart';
import 'package:trash/features/claiming/presentation/controllers/claiming_controller.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  // Orchestration controller
  late final AnimationController _masterCtrl;

  // Individual animations
  late final Animation<double> _bgFade;
  late final Animation<double> _emojiScale;
  late final Animation<double> _titleSlide;
  late final Animation<double> _coinsReveal;
  late final Animation<double> _scoreReveal;
  late final Animation<double> _starsReveal;
  late final Animation<double> _mapPinDrop;
  late final Animation<double> _buttonsSlide;

  // Particle controller (confetti-like coins)
  late final AnimationController _particleCtrl;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _bgFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.15, curve: Curves.easeIn),
    );

    _emojiScale = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.05, 0.25, curve: Curves.elasticOut),
    );

    _titleSlide = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
    );

    _coinsReveal = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.28, 0.48, curve: Curves.easeOut),
    );

    _scoreReveal = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.40, 0.58, curve: Curves.easeOut),
    );

    _starsReveal = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.52, 0.68, curve: Curves.easeOut),
    );

    _mapPinDrop = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.62, 0.82, curve: Curves.bounceOut),
    );

    _buttonsSlide = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
    );

    // Generate particles
    final rng = math.Random();
    for (int i = 0; i < 22; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        startY: rng.nextDouble() * 0.3,
        speed: 0.3 + rng.nextDouble() * 0.7,
        size: 6.0 + rng.nextDouble() * 10,
        color: _particleColors[rng.nextInt(_particleColors.length)],
        angle: (rng.nextDouble() - 0.5) * math.pi * 0.6,
      ));
    }

    _masterCtrl.forward();
    _particleCtrl.forward();
  }

  static const _particleColors = [
    AppColors.accentGreen,
    AppColors.orange,
    Color(0xFFFFD700),
    Color(0xFF7C6CFF),
    Colors.white,
  ];

  @override
  void dispose() {
    _masterCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimState = ref.watch(claimingNotifierProvider);
    final result = claimState.classifyResult;

    // Failure state
    if (claimState.isFailure || result == null) {
      return _FailureScreen(
        reason: claimState.failureReason,
        message: claimState.errorMessage,
        onRetry: () {
          ref.read(claimingNotifierProvider.notifier).reset();
          ref.read(cameraNotifierProvider.notifier).resetToReady();
          context.pop();
        },
      );
    }

    final claim = result.claim!;
    final rewards = result.rewards!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _masterCtrl,
        builder: (context, _) {
          return Stack(
            children: [
              // ── Animated background glow ───────────────────────────────
              FadeTransition(
                opacity: _bgFade,
                child: _BackgroundGlow(category: claim.category),
              ),

              // ── Particle burst (coins / confetti) ──────────────────────
              if (_particleCtrl.value < 1.0)
                CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                  ),
                ),

              // ── Main content ───────────────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Category emoji + name
                      ScaleTransition(
                        scale: _emojiScale,
                        child: _CategoryHero(claim: claim),
                      ),

                      const SizedBox(height: 20),

                      // "Claimed!" title
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_titleSlide),
                        child: FadeTransition(
                          opacity: _titleSlide,
                          child: _ClaimedTitle(
                            category: claim.category,
                            confidence: claim.confidence,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Rewards breakdown ──────────────────────────────
                      _RewardsCard(
                        rewards: rewards,
                        coinsReveal: _coinsReveal,
                        scoreReveal: _scoreReveal,
                        starsReveal: _starsReveal,
                      ),

                      const SizedBox(height: 20),

                      // ── Map pin drop card ──────────────────────────────
                      if (claim.latitude != null && claim.longitude != null)
                        FadeTransition(
                          opacity: _mapPinDrop,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.6),
                              end: Offset.zero,
                            ).animate(_mapPinDrop),
                            child: _MapPinCard(
                              latitude: claim.latitude!,
                              longitude: claim.longitude!,
                              category: claim.category,
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // ── Action buttons ─────────────────────────────────
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1.0),
                          end: Offset.zero,
                        ).animate(_buttonsSlide),
                        child: FadeTransition(
                          opacity: _buttonsSlide,
                          child: _ActionButtons(
                            onClaimAnother: () {
                              ref.read(claimingNotifierProvider.notifier).reset();
                              ref.read(cameraNotifierProvider.notifier).resetToReady();
                              context.pop();
                            },
                            onGoHome: () {
                              ref.read(claimingNotifierProvider.notifier).reset();
                              context.go(AppConstants.routeHome);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Hero
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryHero extends StatelessWidget {
  final TrashClaim claim;
  const _CategoryHero({required this.claim});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                claim.category.color.withOpacity(0.25),
                claim.category.color.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: claim.category.color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: claim.category.color.withOpacity(0.3),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              claim.category.emoji,
              style: const TextStyle(fontSize: 52),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Claimed Title + confidence + rarity badge
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimedTitle extends StatelessWidget {
  final TrashCategory category;
  final double confidence;

  const _ClaimedTitle({required this.category, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${category.displayName} Claimed! 🎉',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: category.rarityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: category.rarityColor.withOpacity(0.4)),
              ),
              child: Text(
                '✦ ${category.rarityLabel}',
                style: TextStyle(
                  color: category.rarityColor,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}% match',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rewards Card
// ─────────────────────────────────────────────────────────────────────────────

class _RewardsCard extends StatelessWidget {
  final ClaimRewards rewards;
  final Animation<double> coinsReveal;
  final Animation<double> scoreReveal;
  final Animation<double> starsReveal;

  const _RewardsCard({
    required this.rewards,
    required this.coinsReveal,
    required this.scoreReveal,
    required this.starsReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            'You earned',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Three reward items
          Row(
            children: [
              Expanded(
                child: _RewardItem(
                  reveal: coinsReveal,
                  emoji: '🪙',
                  value: '+${rewards.coins}',
                  label: 'Coins',
                  color: const Color(0xFFFFD700),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _RewardItem(
                  reveal: scoreReveal,
                  emoji: '⚡',
                  value: '+${rewards.score}',
                  label: 'Score',
                  color: AppColors.orange,
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _RewardItem(
                  reveal: starsReveal,
                  emoji: '⭐',
                  value: '+${rewards.stars}',
                  label: 'Stars',
                  color: const Color(0xFF7C6CFF),
                ),
              ),
            ],
          ),

          // Bonus banners
          if (rewards.bonusMultiplier > 1.0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (rewards.isFirstClaimToday)
              _BonusBadge(
                icon: '🌅',
                label: 'First claim today',
                value: '+50%',
                color: AppColors.orange,
              ),
            if (rewards.streakBonus) ...[
              const SizedBox(height: 8),
              _BonusBadge(
                icon: '🔥',
                label: 'Streak bonus',
                value: '+25%',
                color: const Color(0xFFFF6B2C),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final Animation<double> reveal;
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _RewardItem({
    required this.reveal,
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        return Opacity(
          opacity: reveal.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - reveal.value)),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BonusBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _BonusBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 60,
      color: AppColors.cardBorder,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Pin Drop Card
// ─────────────────────────────────────────────────────────────────────────────

class _MapPinCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final TrashCategory category;

  const _MapPinCard({
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Animated pin
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.forestGreen.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('📍', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pin dropped on map',
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'View Map',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onClaimAnother;
  final VoidCallback onGoHome;

  const _ActionButtons({
    required this.onClaimAnother,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onClaimAnother,
            icon: const Text('📸', style: TextStyle(fontSize: 18)),
            label: Text('Claim Another', style: AppTextStyles.labelLarge),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onGoHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Back to Home', style: AppTextStyles.labelLarge),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Failure Screen
// ─────────────────────────────────────────────────────────────────────────────

class _FailureScreen extends StatelessWidget {
  final ClassifyFailureReason? reason;
  final String? message;
  final VoidCallback onRetry;

  const _FailureScreen({this.reason, this.message, required this.onRetry});

  String get _emoji {
    switch (reason) {
      case ClassifyFailureReason.notTrash:
        return '🤔';
      case ClassifyFailureReason.duplicate:
        return '🔁';
      case ClassifyFailureReason.tooClose:
        return '🗺️';
      default:
        return '⚠️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(_emoji,
                      style: const TextStyle(fontSize: 44)),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                message ?? 'Something went wrong.',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                reason == ClassifyFailureReason.notTrash
                    ? 'Make sure the trash is clearly visible and well-lit.'
                    : reason == ClassifyFailureReason.tooClose
                        ? 'Find a new spot at least 50 metres away.'
                        : 'Please try again.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: Text('Try Again', style: AppTextStyles.labelLarge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Glow
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundGlow extends StatelessWidget {
  final TrashCategory category;
  const _BackgroundGlow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                category.color.withOpacity(0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle System
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double angle;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.angle,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final x = p.x * size.width + math.sin(p.angle) * t * 80;
      final y = p.startY * size.height + t * size.height * 0.6;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.85)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + t * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

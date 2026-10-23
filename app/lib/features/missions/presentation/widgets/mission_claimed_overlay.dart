import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';

class MissionClaimedOverlay extends StatefulWidget {
  final Mission mission;
  final VoidCallback onDismiss;

  const MissionClaimedOverlay({
    super.key,
    required this.mission,
    required this.onDismiss,
  });

  @override
  State<MissionClaimedOverlay> createState() =>
      _MissionClaimedOverlayState();
}

class _MissionClaimedOverlayState extends State<MissionClaimedOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _particleCtrl;

  late final Animation<double> _bgFade;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;
  late final Animation<double> _coinsReveal;
  late final Animation<double> _btnSlide;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _bgFade = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn));
    _cardScale = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.1, 0.45, curve: Curves.elasticOut));
    _cardFade = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.1, 0.3, curve: Curves.easeIn));
    _coinsReveal = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut));
    _btnSlide = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut));

    final rng = math.Random();
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        startY: 0.3 + rng.nextDouble() * 0.2,
        speed: 0.4 + rng.nextDouble() * 0.6,
        size: 6 + rng.nextDouble() * 10,
        color: _colors[rng.nextInt(_colors.length)],
        angle: (rng.nextDouble() - 0.5) * math.pi * 0.8,
      ));
    }

    _mainCtrl.forward();
    _particleCtrl.forward();
  }

  static const _colors = [
    AppColors.accentGreen,
    Color(0xFFFFD700),
    AppColors.orange,
    Color(0xFF7C6CFF),
    Colors.white,
    Color(0xFF4D9FFF),
  ];

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final typeColor = _typeColor(m.type);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _mainCtrl,
        builder: (context, _) {
          return Stack(
            children: [
              // Dimmed background
              FadeTransition(
                opacity: _bgFade,
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(color: Colors.black.withOpacity(0.75)),
                ),
              ),

              // Particle burst
              if (_particleCtrl.value < 1.0)
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                  ),
                ),

              // Card
              Center(
                child: FadeTransition(
                  opacity: _cardFade,
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: typeColor.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withOpacity(0.25),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mission emoji
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: typeColor.withOpacity(0.1),
                              border: Border.all(
                                  color: typeColor.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: Center(
                              child: Text(m.emoji,
                                  style: const TextStyle(fontSize: 40)),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Mission Complete!',
                            style: AppTextStyles.headlineLarge.copyWith(
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [typeColor, typeColor.withOpacity(0.6)],
                                ).createShader(
                                    const Rect.fromLTWH(0, 0, 280, 36)),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            m.title,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Rewards
                          AnimatedBuilder(
                            animation: _coinsReveal,
                            builder: (_, __) => Opacity(
                              opacity: _coinsReveal.value,
                              child: Transform.translate(
                                offset:
                                    Offset(0, 20 * (1 - _coinsReveal.value)),
                                child: _RewardRow(mission: m),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Dismiss button
                          AnimatedBuilder(
                            animation: _btnSlide,
                            builder: (_, __) => Opacity(
                              opacity: _btnSlide.value,
                              child: Transform.translate(
                                offset:
                                    Offset(0, 30 * (1 - _btnSlide.value)),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: widget.onDismiss,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: typeColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                    child: Text('Awesome! 🎉',
                                        style: AppTextStyles.labelLarge),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _typeColor(MissionType type) {
    switch (type) {
      case MissionType.daily:    return AppColors.accentGreen;
      case MissionType.weekly:   return const Color(0xFF4D9FFF);
      case MissionType.special:  return AppColors.orange;
      case MissionType.seasonal: return const Color(0xFF7C6CFF);
    }
  }
}

class _RewardRow extends StatelessWidget {
  final Mission mission;
  const _RewardRow({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Item(emoji: '🪙', value: '+${mission.rewardCoins}',
              color: const Color(0xFFFFD700)),
          Container(width: 1, height: 28, color: AppColors.cardBorder),
          _Item(emoji: '⭐', value: '+${mission.rewardStars}',
              color: const Color(0xFF7C6CFF)),
          Container(width: 1, height: 28, color: AppColors.cardBorder),
          _Item(emoji: '⚡', value: '+${mission.rewardScore}',
              color: AppColors.orange),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _Item(
      {required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

// ── Particle ──────────────────────────────────────────────────────────────────
class _Particle {
  final double x, startY, speed, size, angle;
  final Color color;
  const _Particle(
      {required this.x, required this.startY, required this.speed,
      required this.size, required this.color, required this.angle});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter(
      {required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final x = p.x * size.width + math.sin(p.angle) * t * 100;
      final y = p.startY * size.height + t * size.height * 0.5;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + t * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55),
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

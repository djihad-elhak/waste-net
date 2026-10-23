import 'package:flutter/material.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';

class LevelProgressBar extends StatefulWidget {
  final UserStats stats;

  const LevelProgressBar({super.key, required this.stats});

  @override
  State<LevelProgressBar> createState() => _LevelProgressBarState();
}

class _LevelProgressBarState extends State<LevelProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progress = Tween<double>(
      begin: 0,
      end: widget.stats.levelProgress,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Slight delay so animation plays after screen loads
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(LevelProgressBar old) {
    super.didUpdateWidget(old);
    if (old.stats.levelProgress != widget.stats.levelProgress) {
      _progress = Tween<double>(
        begin: _progress.value,
        end: widget.stats.levelProgress,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Label row
          Row(
            children: [
              // Current level
              _LevelCircle(level: stats.level, isCurrent: true),
              const SizedBox(width: 12),

              // Progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: title + % label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _levelTitle(stats.level),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => Text(
                            '${(_progress.value * 100).toInt()}%',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Bar
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) => _ProgressBar(progress: _progress.value),
                    ),

                    const SizedBox(height: 6),

                    // Stars sub-label
                    Text(
                      '${stats.starsIntoCurrentLevel} / ${stats.starsNeededForNextLevel} ⭐ to Level ${stats.level + 1}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Next level
              _LevelCircle(level: stats.level + 1, isCurrent: false),
            ],
          ),
        ],
      ),
    );
  }

  String _levelTitle(int level) {
    if (level < 3) return 'Rookie Cleaner';
    if (level < 6) return 'Street Guardian';
    if (level < 10) return 'Eco Warrior';
    if (level < 15) return 'City Champion';
    return 'TrashGo Legend';
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            // Background track
            Container(
              width: width,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Fill
            Container(
              width: width * progress,
              height: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.forestGreen],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            // Shine
            Positioned(
              top: 2,
              left: 4,
              child: Container(
                width: (width * progress - 8).clamp(0.0, double.infinity),
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelCircle extends StatelessWidget {
  final int level;
  final bool isCurrent;

  const _LevelCircle({required this.level, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? AppColors.accentGreen.withOpacity(0.15)
            : AppColors.divider,
        border: Border.all(
          color: isCurrent ? AppColors.accentGreen : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isCurrent ? AppColors.accentGreen : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

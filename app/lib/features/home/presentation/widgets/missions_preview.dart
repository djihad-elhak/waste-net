import 'package:flutter/material.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';

class MissionsPreview extends StatelessWidget {
  final List<MissionPreview> missions;
  final VoidCallback onViewAll;

  const MissionsPreview({
    super.key,
    required this.missions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Missions", style: AppTextStyles.headlineMedium),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View All',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accentGreen,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Daily reset timer
        _DailyTimer(),

        const SizedBox(height: 12),

        // Mission cards
        ...missions.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MissionCard(mission: m),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily countdown
// ─────────────────────────────────────────────────────────────────────────────
class _DailyTimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;

    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          'Resets in ${h}h ${m}m',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mission Card
// ─────────────────────────────────────────────────────────────────────────────
class _MissionCard extends StatefulWidget {
  final MissionPreview mission;

  const _MissionCard({required this.mission});

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.mission.progress,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final isComplete = mission.isCompleted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.accentGreen.withOpacity(0.06)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? AppColors.accentGreen.withOpacity(0.3)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Emoji circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.accentGreen.withOpacity(0.12)
                  : AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isComplete ? '✅' : mission.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mission.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: isComplete
                              ? TextDecoration.lineThrough
                              : null,
                          color: isComplete
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Reward chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙',
                              style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          Text(
                            '+${mission.rewardCoins}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress bar
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => _MissionProgress(
                    progress: _progressAnim.value,
                    label: mission.progressLabel,
                    isComplete: isComplete,
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

class _MissionProgress extends StatelessWidget {
  final double progress;
  final String label;
  final bool isComplete;

  const _MissionProgress({
    required this.progress,
    required this.label,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? AppColors.accentGreen : AppColors.midGreen;

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          isComplete ? 'Done!' : label,
          style: AppTextStyles.caption.copyWith(
            color: isComplete ? AppColors.accentGreen : AppColors.textHint,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

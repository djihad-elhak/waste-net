import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';
import 'package:trash/features/missions/presentation/controllers/missions_controller.dart';

class MissionCard extends ConsumerStatefulWidget {
  final Mission mission;
  final String userId;

  const MissionCard({
    super.key,
    required this.mission,
    required this.userId,
  });

  @override
  ConsumerState<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<MissionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final Animation<double> _progressAnim;
  late final Animation<double> _claimPulse;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.mission.progress,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));

    _claimPulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _progressCtrl.forward();
      if (widget.mission.canClaim) {
        _progressCtrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  Color get _difficultyColor =>
      Color(widget.mission.difficulty.colorValue);

  Color get _typeColor {
    switch (widget.mission.type) {
      case MissionType.daily:   return AppColors.accentGreen;
      case MissionType.weekly:  return const Color(0xFF4D9FFF);
      case MissionType.special: return AppColors.orange;
      case MissionType.seasonal:return const Color(0xFF7C6CFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final claimState = ref.watch(missionsControllerProvider);
    final isClaiming = claimState.claimingMissionId == m.id;

    final isJustClaimed = claimState.successMissionId == m.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: m.isClaimed
            ? AppColors.card.withOpacity(0.5)
            : m.canClaim
                ? _typeColor.withOpacity(0.06)
                : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: m.canClaim
              ? _typeColor.withOpacity(0.4)
              : m.isClaimed
                  ? AppColors.cardBorder.withOpacity(0.4)
                  : AppColors.cardBorder,
          width: m.canClaim ? 1.5 : 1,
        ),
        boxShadow: m.canClaim
            ? [
                BoxShadow(
                  color: _typeColor.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji circle
                _EmojiCircle(
                  emoji: m.isClaimed ? '✅' : m.emoji,
                  color: m.isClaimed ? AppColors.textHint : _typeColor,
                  size: 52,
                ),
                const SizedBox(width: 12),

                // Title + badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type + difficulty chips
                      Row(
                        children: [
                          _TypeChip(mission: m, color: _typeColor),
                          const SizedBox(width: 6),
                          _DifficultyChip(
                            difficulty: m.difficulty,
                            color: _difficultyColor,
                          ),
                          const Spacer(),
                          // Timer
                          if (!m.isClaimed)
                            _TimerBadge(mission: m),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: m.isClaimed
                              ? TextDecoration.lineThrough
                              : null,
                          color: m.isClaimed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Description ────────────────────────────────────────────
            if (!m.isClaimed)
              Text(
                m.description,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
              ),

            const SizedBox(height: 14),

            // ── Progress bar ───────────────────────────────────────────
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => _ProgressSection(
                mission: m,
                animatedProgress: _progressAnim.value,
                barColor: m.isClaimed ? AppColors.textHint : _typeColor,
              ),
            ),

            const SizedBox(height: 14),

            // ── Rewards + Claim button ──────────────────────────────────
            Row(
              children: [
                // Reward chips
                _RewardChip(
                    emoji: '🪙', value: '+${m.rewardCoins}',
                    color: const Color(0xFFFFD700)),
                const SizedBox(width: 6),
                _RewardChip(
                    emoji: '⭐', value: '+${m.rewardStars}',
                    color: const Color(0xFF7C6CFF)),
                const SizedBox(width: 6),
                _RewardChip(
                    emoji: '⚡', value: '+${m.rewardScore}',
                    color: AppColors.orange),
                const Spacer(),

                // Claim button
                if (m.canClaim)
                  ScaleTransition(
                    scale: _claimPulse,
                    child: _ClaimButton(
                      isLoading: isClaiming,
                      color: _typeColor,
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        ref
                            .read(missionsControllerProvider.notifier)
                            .claimReward(
                              userId: widget.userId,
                              mission: m,
                            );
                      },
                    ),
                  ),

                if (m.isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Claimed',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            // Event label
            if (m.eventName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(m.eventBannerEmoji ?? '🌿',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    m.eventName!,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF7C6CFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _EmojiCircle extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;

  const _EmojiCircle(
      {required this.emoji, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.44)),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final Mission mission;
  final Color color;

  const _TypeChip({required this.mission, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mission.type.emoji, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 3),
          Text(
            mission.type.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final MissionDifficulty difficulty;
  final Color color;

  const _DifficultyChip(
      {required this.difficulty, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final Mission mission;

  const _TimerBadge({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 11,
          color: mission.isUrgent ? AppColors.error : AppColors.textHint,
        ),
        const SizedBox(width: 3),
        Text(
          mission.timeLeft,
          style: AppTextStyles.caption.copyWith(
            color: mission.isUrgent ? AppColors.error : AppColors.textHint,
            fontWeight:
                mission.isUrgent ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Mission mission;
  final double animatedProgress;
  final Color barColor;

  const _ProgressSection({
    required this.mission,
    required this.animatedProgress,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mission.isClaimed
                  ? 'Completed ✓'
                  : mission.isCompleted
                      ? 'Ready to claim!'
                      : mission.progressLabel,
              style: AppTextStyles.caption.copyWith(
                color: mission.isCompleted
                    ? barColor
                    : AppColors.textSecondary,
                fontWeight: mission.isCompleted
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            Text(
              '${(animatedProgress * 100).toInt()}%',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: animatedProgress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _RewardChip(
      {required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final bool isLoading;
  final Color color;
  final VoidCallback onTap;

  const _ClaimButton(
      {required this.isLoading, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Claim 🎁',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

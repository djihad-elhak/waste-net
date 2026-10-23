import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/theme/app_theme.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';
import 'package:trash/features/home/presentation/controllers/home_controller.dart';

class RewardsCarousel extends ConsumerWidget {
  final List<RewardItem> rewards;
  final int userCoins;
  final String userId;

  const RewardsCarousel({
    super.key,
    required this.rewards,
    required this.userCoins,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rewards', style: AppTextStyles.headlineMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '$userCoins coins',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _RewardCard(
              reward: rewards[i],
              userCoins: userCoins,
              onTap: () => _showRedeemSheet(context, ref, rewards[i]),
            ),
          ),
        ),
      ],
    );
  }

  void _showRedeemSheet(
      BuildContext context, WidgetRef ref, RewardItem reward) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _RedeemSheet(
          reward: reward,
          userCoins: userCoins,
          userId: userId,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward Card
// ─────────────────────────────────────────────────────────────────────────────
class _RewardCard extends StatelessWidget {
  final RewardItem reward;
  final int userCoins;
  final VoidCallback onTap;

  const _RewardCard({
    required this.reward,
    required this.userCoins,
    required this.onTap,
  });

  bool get _canAfford => userCoins >= reward.coinCost;

  Color get _categoryColor {
    switch (reward.category) {
      case RewardCategory.internet:
        return const Color(0xFF4D9FFF);
      case RewardCategory.food:
        return AppColors.orange;
      case RewardCategory.entertainment:
        return const Color(0xFF7C6CFF);
      case RewardCategory.books:
        return const Color(0xFF1FD47A);
      case RewardCategory.other:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _canAfford
                ? _categoryColor.withOpacity(0.35)
                : AppColors.cardBorder,
          ),
          boxShadow: _canAfford
              ? [
                  BoxShadow(
                    color: _categoryColor.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + affordability dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      reward.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                if (!_canAfford)
                  const Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: AppColors.textHint,
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              reward.title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Cost chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _canAfford
                    ? _categoryColor.withOpacity(0.15)
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 3),
                  Text(
                    '${reward.coinCost}',
                    style: TextStyle(
                      color: _canAfford ? _categoryColor : AppColors.textHint,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Redeem Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _RedeemSheet extends ConsumerWidget {
  final RewardItem reward;
  final int userCoins;
  final String userId;

  const _RedeemSheet({
    required this.reward,
    required this.userCoins,
    required this.userId,
  });

  bool get _canAfford => userCoins >= reward.coinCost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(redeemControllerProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: state.isSuccess
          ? _RedeemSuccess(
              code: state.successCode!,
              reward: state.redeemedItem ?? reward,
              onDone: () {
                ref.read(redeemControllerProvider.notifier).reset();
                Navigator.of(context).pop();
              },
            )
          : _RedeemConfirm(
              reward: reward,
              userCoins: userCoins,
              canAfford: _canAfford,
              isLoading: state.isLoading,
              errorMessage: state.errorMessage,
              onRedeem: () => ref.read(redeemControllerProvider.notifier).redeem(
                    userId: userId,
                    reward: reward,
                    userCoins: userCoins,
                  ),
              onCancel: () => Navigator.of(context).pop(),
            ),
    );
  }
}

class _RedeemConfirm extends StatelessWidget {
  final RewardItem reward;
  final int userCoins;
  final bool canAfford;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRedeem;
  final VoidCallback onCancel;

  const _RedeemConfirm({
    required this.reward,
    required this.userCoins,
    required this.canAfford,
    required this.isLoading,
    this.errorMessage,
    required this.onRedeem,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final shortage = reward.coinCost - userCoins;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Emoji
        Text(reward.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),

        Text(reward.title, style: AppTextStyles.headlineLarge),
        const SizedBox(height: 4),
        Text(reward.description, style: AppTextStyles.bodyMedium),
        Text(
          'by ${reward.partnerName}',
          style: AppTextStyles.caption,
        ),

        const SizedBox(height: 24),

        // Cost row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cost: ', style: AppTextStyles.bodyMedium),
            const Text('🪙', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              '${reward.coinCost} coins',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          'Your balance: 🪙 $userCoins coins',
          style: AppTextStyles.caption,
        ),

        if (!canAfford) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'You need $shortage more coins to unlock this reward.',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],

        const SizedBox(height: 24),

        // Buttons
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (canAfford && !isLoading) ? onRedeem : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              disabledBackgroundColor: AppColors.forestGreen.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textPrimary),
                    ),
                  )
                : Text(
                    canAfford ? 'Redeem Now' : 'Not Enough Coins',
                    style: AppTextStyles.labelLarge,
                  ),
          ),
        ),

        const SizedBox(height: 10),

        TextButton(
          onPressed: onCancel,
          child: Text('Cancel',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _RedeemSuccess extends StatelessWidget {
  final String code;
  final RewardItem reward;
  final VoidCallback onDone;

  const _RedeemSuccess({
    required this.code,
    required this.reward,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentGreen.withOpacity(0.1),
            border: Border.all(
                color: AppColors.accentGreen.withOpacity(0.3), width: 2),
          ),
          child: const Center(
            child: Text('✅', style: TextStyle(fontSize: 38)),
          ),
        ),

        const SizedBox(height: 16),

        Text('Reward Unlocked!', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 6),
        Text(reward.title,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.accentGreen)),

        const SizedBox(height: 24),

        // Code box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text('Your Code', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              SelectableText(
                code,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied!')),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('Tap to copy', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Done', style: AppTextStyles.labelLarge),
          ),
        ),
      ],
    );
  }
}

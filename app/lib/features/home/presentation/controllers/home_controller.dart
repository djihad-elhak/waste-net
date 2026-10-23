import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/home/data/providers/home_providers.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Redeem State
// ─────────────────────────────────────────────────────────────────────────────
class RedeemState {
  final bool isLoading;
  final String? errorMessage;
  final String? successCode;
  final RewardItem? redeemedItem;

  const RedeemState({
    this.isLoading = false,
    this.errorMessage,
    this.successCode,
    this.redeemedItem,
  });

  bool get isSuccess => successCode != null;

  RedeemState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successCode,
    RewardItem? redeemedItem,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RedeemState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successCode: clearSuccess ? null : (successCode ?? this.successCode),
      redeemedItem: clearSuccess ? null : (redeemedItem ?? this.redeemedItem),
    );
  }
}

class RedeemController extends Notifier<RedeemState> {
  @override
  RedeemState build() => const RedeemState();

  Future<void> redeem({
    required String userId,
    required RewardItem reward,
    required int userCoins,
  }) async {
    if (userCoins < reward.coinCost) {
      state = state.copyWith(
        errorMessage:
            'You need ${reward.coinCost - userCoins} more coins for this reward.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final useCase = ref.read(redeemRewardUseCaseProvider);
    final result = await useCase(
      userId: userId,
      rewardId: reward.id,
      coinCost: reward.coinCost,
    );

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        successCode: result.code,
        redeemedItem: reward,
      );
    }
  }

  void reset() => state = const RedeemState();
}

final redeemControllerProvider =
    NotifierProvider<RedeemController, RedeemState>(RedeemController.new);

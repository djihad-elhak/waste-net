import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/missions/data/providers/missions_providers.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Claim Reward State
// ─────────────────────────────────────────────────────────────────────────────
class ClaimRewardState {
  final bool isLoading;
  final String? claimingMissionId;
  final String? errorMessage;
  final String? successMissionId;

  const ClaimRewardState({
    this.isLoading = false,
    this.claimingMissionId,
    this.errorMessage,
    this.successMissionId,
  });

  ClaimRewardState copyWith({
    bool? isLoading,
    String? claimingMissionId,
    String? errorMessage,
    String? successMissionId,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ClaimRewardState(
      isLoading: isLoading ?? this.isLoading,
      claimingMissionId:
          claimingMissionId ?? this.claimingMissionId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMissionId: clearSuccess
          ? null
          : (successMissionId ?? this.successMissionId),
    );
  }
}

class MissionsController extends Notifier<ClaimRewardState> {
  @override
  ClaimRewardState build() => const ClaimRewardState();

  Future<void> claimReward({
    required String userId,
    required Mission mission,
  }) async {
    if (!mission.canClaim) return;

    state = state.copyWith(
      isLoading: true,
      claimingMissionId: mission.id,
      clearError: true,
    );

    final useCase = ref.read(claimMissionRewardUseCaseProvider);
    final result = await useCase(
      userId: userId,
      missionId: mission.id,
      coins: mission.rewardCoins,
      stars: mission.rewardStars,
      score: mission.rewardScore,
    );

    if (result.failure != null) {
      state = state.copyWith(
        isLoading: false,
        claimingMissionId: null,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        claimingMissionId: null,
        successMissionId: mission.id,
      );
    }
  }

  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

final missionsControllerProvider =
    NotifierProvider<MissionsController, ClaimRewardState>(
        MissionsController.new);

// ── Active filter tab ─────────────────────────────────────────────────────────
final missionFilterProvider =
    StateProvider<MissionType?>((ref) => null); // null = All

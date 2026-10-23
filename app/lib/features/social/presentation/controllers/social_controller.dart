import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/social/data/providers/social_providers.dart';
import 'package:trash/features/social/domain/entities/social_entities.dart';

class SocialActionState {
  final Set<String> loadingUids;
  final Set<String> sentRequestUids;
  final String? errorMessage;

  const SocialActionState({
    this.loadingUids = const {},
    this.sentRequestUids = const {},
    this.errorMessage,
  });

  SocialActionState copyWith({
    Set<String>? loadingUids,
    Set<String>? sentRequestUids,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SocialActionState(
      loadingUids: loadingUids ?? this.loadingUids,
      sentRequestUids: sentRequestUids ?? this.sentRequestUids,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SocialController extends Notifier<SocialActionState> {
  @override
  SocialActionState build() => const SocialActionState();

  Future<void> sendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    state = state.copyWith(
      loadingUids: {...state.loadingUids, toUserId},
    );

    final useCase = ref.read(sendFriendRequestUseCaseProvider);
    final result =
        await useCase(fromUserId: fromUserId, toUserId: toUserId);

    final newLoading = Set<String>.from(state.loadingUids)
      ..remove(toUserId);

    if (result.failure != null) {
      state = state.copyWith(
        loadingUids: newLoading,
        errorMessage: result.failure!.message,
      );
    } else {
      state = state.copyWith(
        loadingUids: newLoading,
        sentRequestUids: {...state.sentRequestUids, toUserId},
      );
    }
  }

  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    state = state.copyWith(
        loadingUids: {...state.loadingUids, friendId});
    final useCase = ref.read(removeFriendUseCaseProvider);
    await useCase(userId: userId, friendId: friendId);

    final newLoading = Set<String>.from(state.loadingUids)
      ..remove(friendId);
    state = state.copyWith(loadingUids: newLoading);
  }
}

final socialControllerProvider =
    NotifierProvider<SocialController, SocialActionState>(
        SocialController.new);

// Leaderboard UI state
final leaderboardScopeProvider =
    StateProvider<LeaderboardScope>((_) => LeaderboardScope.global);
final leaderboardPeriodProvider =
    StateProvider<LeaderboardPeriod>((_) => LeaderboardPeriod.weekly);

// Social tab
final socialTabProvider = StateProvider<int>((_) => 0);

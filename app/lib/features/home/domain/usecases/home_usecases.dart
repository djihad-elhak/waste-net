import 'package:trash/core/error/failures.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';
import 'package:trash/features/home/domain/repositories/home_repository.dart';

class WatchUserStatsUseCase {
  final HomeRepository _repo;
  const WatchUserStatsUseCase(this._repo);

  Stream<UserStats> call(String userId) => _repo.watchUserStats(userId);
}

class GetDailyMissionsUseCase {
  final HomeRepository _repo;
  const GetDailyMissionsUseCase(this._repo);

  Future<({List<MissionPreview> missions, Failure? failure})> call(
          String userId) =>
      _repo.getDailyMissions(userId);
}

class GetAvailableRewardsUseCase {
  final HomeRepository _repo;
  const GetAvailableRewardsUseCase(this._repo);

  Future<({List<RewardItem> rewards, Failure? failure})> call() =>
      _repo.getAvailableRewards();
}

class RedeemRewardUseCase {
  final HomeRepository _repo;
  const RedeemRewardUseCase(this._repo);

  Future<({String? code, Failure? failure})> call({
    required String userId,
    required String rewardId,
    required int coinCost,
  }) =>
      _repo.redeemReward(
          userId: userId, rewardId: rewardId, coinCost: coinCost);
}

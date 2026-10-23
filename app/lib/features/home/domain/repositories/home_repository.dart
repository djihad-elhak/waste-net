import 'package:trash/core/error/failures.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';

abstract class HomeRepository {
  /// Real-time stream of user stats (coins, level, streak, etc.)
  Stream<UserStats> watchUserStats(String userId);

  /// One-shot fetch of today's mission previews
  Future<({List<MissionPreview> missions, Failure? failure})> getDailyMissions(
      String userId);

  /// Fetch available rewards for the carousel
  Future<({List<RewardItem> rewards, Failure? failure})> getAvailableRewards();

  /// Redeem a reward — deducts coins, returns partner code
  Future<({String? code, Failure? failure})> redeemReward({
    required String userId,
    required String rewardId,
    required int coinCost,
  });
}

import 'package:trash/core/error/failures.dart';
import 'package:trash/features/home/data/datasources/home_datasource.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';
import 'package:trash/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _ds;
  const HomeRepositoryImpl(this._ds);

  @override
  Stream<UserStats> watchUserStats(String userId) =>
      _ds.watchUserStats(userId);

  @override
  Future<({List<MissionPreview> missions, Failure? failure})> getDailyMissions(
          String userId) =>
      _ds.getDailyMissions(userId);

  @override
  Future<({List<RewardItem> rewards, Failure? failure})>
      getAvailableRewards() => _ds.getAvailableRewards();

  @override
  Future<({String? code, Failure? failure})> redeemReward({
    required String userId,
    required String rewardId,
    required int coinCost,
  }) =>
      _ds.redeemReward(
          userId: userId, rewardId: rewardId, coinCost: coinCost);
}

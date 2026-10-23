import 'package:trash/core/error/failures.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';
import 'package:trash/features/missions/domain/repositories/missions_repository.dart';

class WatchMissionsUseCase {
  final MissionsRepository _repo;
  const WatchMissionsUseCase(this._repo);

  Stream<List<Mission>> call(String userId) =>
      _repo.watchMissions(userId);
}

class ClaimMissionRewardUseCase {
  final MissionsRepository _repo;
  const ClaimMissionRewardUseCase(this._repo);

  Future<({bool success, Failure? failure})> call({
    required String userId,
    required String missionId,
    required int coins,
    required int stars,
    required int score,
  }) =>
      _repo.claimMissionReward(
        userId: userId,
        missionId: missionId,
        coins: coins,
        stars: stars,
        score: score,
      );
}

class SeedMissionsUseCase {
  final MissionsRepository _repo;
  const SeedMissionsUseCase(this._repo);

  Future<void> call(String userId) => _repo.seedMissionsIfEmpty(userId);
}

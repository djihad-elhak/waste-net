import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/missions/data/datasources/missions_datasource.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';
import 'package:trash/features/missions/domain/repositories/missions_repository.dart';
import 'package:trash/features/missions/domain/usecases/missions_usecases.dart';

// ── Repository impl ───────────────────────────────────────────────────────────
class MissionsRepositoryImpl implements MissionsRepository {
  final MissionsDataSource _ds;
  const MissionsRepositoryImpl(this._ds);

  @override
  Stream<List<Mission>> watchMissions(String userId) =>
      _ds.watchMissions(userId);

  @override
  Future<({bool success, Failure? failure})> claimMissionReward({
    required String userId,
    required String missionId,
    required int coins,
    required int stars,
    required int score,
  }) =>
      _ds.claimMissionReward(
        userId: userId,
        missionId: missionId,
        coins: coins,
        stars: stars,
        score: score,
      );

  @override
  Future<void> seedMissionsIfEmpty(String userId) =>
      _ds.seedMissionsIfEmpty(userId);
}

// ── Providers ─────────────────────────────────────────────────────────────────
final missionsDataSourceProvider =
    Provider<MissionsDataSource>((_) => MissionsDataSource());

final missionsRepositoryProvider = Provider<MissionsRepository>(
  (ref) => MissionsRepositoryImpl(ref.read(missionsDataSourceProvider)),
);

final watchMissionsUseCaseProvider = Provider(
  (ref) => WatchMissionsUseCase(ref.read(missionsRepositoryProvider)),
);

final claimMissionRewardUseCaseProvider = Provider(
  (ref) => ClaimMissionRewardUseCase(ref.read(missionsRepositoryProvider)),
);

final seedMissionsUseCaseProvider = Provider(
  (ref) => SeedMissionsUseCase(ref.read(missionsRepositoryProvider)),
);

// Live missions stream
final missionsProvider =
    StreamProvider.family<List<Mission>, String>((ref, userId) {
  return ref.read(watchMissionsUseCaseProvider).call(userId);
});

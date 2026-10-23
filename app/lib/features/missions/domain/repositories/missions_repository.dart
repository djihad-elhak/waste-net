import 'package:trash/core/error/failures.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';

abstract class MissionsRepository {
  /// Real-time stream of all missions for a user (with their progress)
  Stream<List<Mission>> watchMissions(String userId);

  /// Claim reward for a completed mission
  Future<({bool success, Failure? failure})> claimMissionReward({
    required String userId,
    required String missionId,
    required int coins,
    required int stars,
    required int score,
  });

  /// Seed default daily/weekly missions if none exist (called on app open)
  Future<void> seedMissionsIfEmpty(String userId);
}

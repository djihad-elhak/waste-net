import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';
import 'package:trash/features/claim_map/domain/repositories/claim_map_repository.dart';

class WatchOwnPinsUseCase {
  final ClaimMapRepository _repo;
  const WatchOwnPinsUseCase(this._repo);
  Stream<List<ClaimPin>> call(String userId) => _repo.watchOwnPins(userId);
}

class WatchFriendPinsUseCase {
  final ClaimMapRepository _repo;
  const WatchFriendPinsUseCase(this._repo);
  Stream<List<ClaimPin>> call(String userId) => _repo.watchFriendPins(userId);
}

class GetHeatZonesUseCase {
  final ClaimMapRepository _repo;
  const GetHeatZonesUseCase(this._repo);

  Future<({List<HeatZone> zones, Failure? failure})> call({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) =>
      _repo.getHeatZones(
          swLat: swLat, swLng: swLng, neLat: neLat, neLng: neLng);
}

class GetUserImpactStatsUseCase {
  final ClaimMapRepository _repo;
  const GetUserImpactStatsUseCase(this._repo);

  Future<({UserImpactStats? stats, Failure? failure})> call(String userId) =>
      _repo.getUserImpactStats(userId);
}

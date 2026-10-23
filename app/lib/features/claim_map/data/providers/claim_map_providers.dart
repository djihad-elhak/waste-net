import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claim_map/data/datasources/claim_map_datasource.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';
import 'package:trash/features/claim_map/domain/repositories/claim_map_repository.dart';
import 'package:trash/features/claim_map/domain/usecases/claim_map_usecases.dart';

// ── Repository Impl ───────────────────────────────────────────────────────────
class ClaimMapRepositoryImpl implements ClaimMapRepository {
  final ClaimMapDataSource _ds;
  const ClaimMapRepositoryImpl(this._ds);

  @override
  Stream<List<ClaimPin>> watchOwnPins(String userId) =>
      _ds.watchOwnPins(userId);

  @override
  Stream<List<ClaimPin>> watchFriendPins(String userId) =>
      _ds.watchFriendPins(userId);

  @override
  Future<({List<HeatZone> zones, Failure? failure})> getHeatZones({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) =>
      _ds.getHeatZones(
          swLat: swLat, swLng: swLng, neLat: neLat, neLng: neLng);

  @override
  Future<({UserImpactStats? stats, Failure? failure})> getUserImpactStats(
          String userId) =>
      _ds.getUserImpactStats(userId);

  @override
  Future<({ClaimPin? pin, Failure? failure})> getClaimDetail(
          String claimId) =>
      _ds.getClaimDetail(claimId, '');
}

// ── Providers ─────────────────────────────────────────────────────────────────
final claimMapDataSourceProvider =
    Provider<ClaimMapDataSource>((_) => ClaimMapDataSource());

final claimMapRepositoryProvider = Provider<ClaimMapRepository>(
  (ref) => ClaimMapRepositoryImpl(ref.read(claimMapDataSourceProvider)),
);

final watchOwnPinsUseCaseProvider = Provider(
  (ref) => WatchOwnPinsUseCase(ref.read(claimMapRepositoryProvider)),
);

final watchFriendPinsUseCaseProvider = Provider(
  (ref) => WatchFriendPinsUseCase(ref.read(claimMapRepositoryProvider)),
);

final getHeatZonesUseCaseProvider = Provider(
  (ref) => GetHeatZonesUseCase(ref.read(claimMapRepositoryProvider)),
);

final getUserImpactStatsUseCaseProvider = Provider(
  (ref) => GetUserImpactStatsUseCase(ref.read(claimMapRepositoryProvider)),
);

// Live pin streams
final ownPinsProvider =
    StreamProvider.family<List<ClaimPin>, String>((ref, userId) {
  return ref.read(watchOwnPinsUseCaseProvider).call(userId);
});

final friendPinsProvider =
    StreamProvider.family<List<ClaimPin>, String>((ref, userId) {
  return ref.read(watchFriendPinsUseCaseProvider).call(userId);
});

final userImpactStatsProvider =
    FutureProvider.family<UserImpactStats?, String>((ref, userId) async {
  final result =
      await ref.read(getUserImpactStatsUseCaseProvider).call(userId);
  return result.stats;
});

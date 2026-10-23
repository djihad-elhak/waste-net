import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';

abstract class ClaimMapRepository {
  /// Stream of own claim pins (green) – real-time
  Stream<List<ClaimPin>> watchOwnPins(String userId);

  /// Stream of friend pins (blue) – real-time
  Stream<List<ClaimPin>> watchFriendPins(String userId);

  /// Fetch community heat zones for the visible map region
  Future<({List<HeatZone> zones, Failure? failure})> getHeatZones({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  });

  /// User's personal impact stats
  Future<({UserImpactStats? stats, Failure? failure})> getUserImpactStats(
      String userId);

  /// Fetch full claim detail by ID (for pin tap bottom sheet)
  Future<({ClaimPin? pin, Failure? failure})> getClaimDetail(String claimId);
}

import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';

abstract class ClaimingRepository {
  /// Save a claim to Firestore + update user stats atomically
  Future<({TrashClaim? claim, Failure? failure})> saveClaim(TrashClaim claim);

  /// Upload photo to Firebase Storage, returns download URL
  Future<({String? url, Failure? failure})> uploadClaimPhoto({
    required String localPath,
    required String userId,
    required String claimId,
  });

  /// Check if this image hash was already claimed (anti-cheat)
  Future<({bool isDuplicate, Failure? failure})> checkDuplicateImage(
      String imageHash);

  /// Check distance from last claim (anti-cheat: >50m required)
  Future<({bool isValid, Failure? failure})> checkLocationValid({
    required String userId,
    required double latitude,
    required double longitude,
  });

  /// Get user's claim history
  Future<({List<TrashClaim> claims, Failure? failure})> getUserClaims(
      String userId);

  /// Queue a claim for offline sync
  Future<void> queueOfflineClaim(TrashClaim claim);

  /// Flush offline queue when back online
  Future<void> syncOfflineClaims(String userId);
}

import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claiming/data/datasources/claiming_datasource.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';
import 'package:trash/features/claiming/domain/repositories/claiming_repository.dart';

class ClaimingRepositoryImpl implements ClaimingRepository {
  final ClaimingDataSource _dataSource;

  const ClaimingRepositoryImpl(this._dataSource);

  @override
  Future<({TrashClaim? claim, Failure? failure})> saveClaim(
      TrashClaim claim) async {
    final result = await _dataSource.saveClaim(claim);
    return (claim: result.claim, failure: result.failure);
  }

  @override
  Future<({String? url, Failure? failure})> uploadClaimPhoto({
    required String localPath,
    required String userId,
    required String claimId,
  }) =>
      _dataSource.uploadClaimPhoto(
          localPath: localPath, userId: userId, claimId: claimId);

  @override
  Future<({bool isDuplicate, Failure? failure})> checkDuplicateImage(
          String imageHash) =>
      _dataSource.checkDuplicateImage(imageHash);

  @override
  Future<({bool isValid, Failure? failure})> checkLocationValid({
    required String userId,
    required double latitude,
    required double longitude,
  }) =>
      _dataSource.checkLocationValid(
          userId: userId, latitude: latitude, longitude: longitude);

  @override
  Future<({List<TrashClaim> claims, Failure? failure})> getUserClaims(
      String userId) async {
    final result = await _dataSource.getUserClaims(userId);
    return (claims: result.claims, failure: result.failure);
  }

  @override
  Future<void> queueOfflineClaim(TrashClaim claim) =>
      _dataSource.queueOfflineClaim(claim);

  @override
  Future<void> syncOfflineClaims(String userId) =>
      _dataSource.syncOfflineClaims(userId);
}

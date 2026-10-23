import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:trash/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claiming/data/models/trash_claim_model.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';

class ClaimingDataSource {
  final FirebaseFirestore _firestore;

  static const String _claimsCollection = 'claims';
  static const String _usersCollection = 'users';
  static const String _imageHashesCollection = 'image_hashes';
  static const String _offlineClaimsBox = 'offline_claims';

  // Anti-cheat: minimum distance in metres between claims
  static const double _minClaimDistanceMetres = 50.0;

  ClaimingDataSource({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Save Claim + Update User Stats (atomic) ───────────────────────────────
  Future<({TrashClaimModel? claim, Failure? failure})> saveClaim(
      TrashClaim claim) async {
    try {
      final batch = _firestore.batch();

      // 1. New claim document
      final claimRef = _firestore.collection(_claimsCollection).doc();
      final model = TrashClaimModel.fromEntity(claim);
      batch.set(claimRef, model.toFirestore());

      // 2. Register image hash
      if (claim.imageHash != null) {
        final hashRef = _firestore
            .collection(_imageHashesCollection)
            .doc(claim.imageHash);
        batch.set(hashRef, {
          'claimId': claimRef.id,
          'userId': claim.userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Update user stats atomically
      final userRef =
          _firestore.collection(_usersCollection).doc(claim.userId);
      batch.update(userRef, {
        'coins': FieldValue.increment(claim.coinsAwarded),
        'score': FieldValue.increment(claim.scoreAwarded),
        'stars': FieldValue.increment(claim.starsAwarded),
        'totalClaims': FieldValue.increment(1),
        'lastClaimAt': FieldValue.serverTimestamp(),
        'lastClaimLat': claim.latitude,
        'lastClaimLng': claim.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (claim.localPhotoPath != null) {
        CloudinaryService.uploadClaimPhoto(
          localFilePath: claim.localPhotoPath!,
          claimId: claimRef.id,
          userId: claim.userId,
        ).then((photoUrl) {
          if (photoUrl != null) {
            // Update the claim document with the Cloudinary URL
            _firestore
                .collection(_claimsCollection)
                .doc(claimRef.id)
                .update({'photoUrl': photoUrl})
                .catchError((e) {
              debugPrint('[Claiming] Failed to update photoUrl: $e');
            });
          }
        });
      }

      return (
        claim: TrashClaimModel(
          id: claimRef.id,
          userId: claim.userId,
          category: claim.category,
          confidence: claim.confidence,
          coinsAwarded: claim.coinsAwarded,
          scoreAwarded: claim.scoreAwarded,
          starsAwarded: claim.starsAwarded,
          latitude: claim.latitude,
          longitude: claim.longitude,
          localPhotoPath: claim.localPhotoPath,
          imageHash: claim.imageHash,
          isSynced: true,
          createdAt: claim.createdAt,
        ),
        failure: null,
      );
    } on FirebaseException catch (e) {
      return (
        claim: null,
        failure: ServerFailure(e.message ?? 'Failed to save claim.'),
      );
    } catch (_) {
      return (claim: null, failure: const ServerFailure());
    }
  }

  // ── Upload Photo ──────────────────────────────────────────────────────────
  // AFTER (Cloudinary version — ADD THIS):
  Future<({String? url, Failure? failure})> uploadClaimPhoto({
    required String localPath,
    required String userId,
    required String claimId,
  }) async {
    final url = await CloudinaryService.uploadClaimPhoto(
      localFilePath: localPath,
      claimId: claimId,
      userId: userId,
    );

    if (url != null) {
      return (url: url, failure: null);
    } else {
      // Non-fatal — claim saved fine, just no photo URL
      return (url: null, failure: null);
    }
  }

  // ── Duplicate Image Check ─────────────────────────────────────────────────
  Future<({bool isDuplicate, Failure? failure})> checkDuplicateImage(
      String imageHash) async {
    try {
      final doc = await _firestore
          .collection(_imageHashesCollection)
          .doc(imageHash)
          .get();
      return (isDuplicate: doc.exists, failure: null);
    } catch (_) {
      // On error, allow the claim (don't block user)
      return (isDuplicate: false, failure: null);
    }
  }

  // ── Location Distance Check ───────────────────────────────────────────────
  Future<({bool isValid, Failure? failure})> checkLocationValid({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      final data = userDoc.data();
      if (data == null) return (isValid: true, failure: null);

      final lastLat = (data['lastClaimLat'] as num?)?.toDouble();
      final lastLng = (data['lastClaimLng'] as num?)?.toDouble();

      if (lastLat == null || lastLng == null) {
        return (isValid: true, failure: null); // First claim ever
      }

      final distance = _haversineDistance(
        lat1: lastLat,
        lng1: lastLng,
        lat2: latitude,
        lng2: longitude,
      );

      return (
        isValid: distance >= _minClaimDistanceMetres,
        failure: null,
      );
    } catch (_) {
      return (isValid: true, failure: null); // Fail open
    }
  }

  // ── Get User Claims ───────────────────────────────────────────────────────
  Future<({List<TrashClaimModel> claims, Failure? failure})> getUserClaims(
      String userId) async {
    try {
      final query = await _firestore
          .collection(_claimsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final claims =
          query.docs.map(TrashClaimModel.fromFirestore).toList();
      return (claims: claims, failure: null);
    } catch (_) {
      return (claims: <TrashClaimModel>[], failure: const ServerFailure());
    }
  }

  // ── Offline Queue ─────────────────────────────────────────────────────────
  Future<void> queueOfflineClaim(TrashClaim claim) async {
    final box = await Hive.openBox<String>(_offlineClaimsBox);
    final model = TrashClaimModel.fromEntity(claim);
    await box.add(model.toFirestore().toString());
  }

  Future<void> syncOfflineClaims(String userId) async {
    // Implementation: drain Hive box → saveClaim for each entry
    final box = await Hive.openBox<String>(_offlineClaimsBox);
    if (box.isEmpty) return;
    // TODO: deserialize & retry each queued claim
    await box.clear();
  }

  // ── Haversine Distance ────────────────────────────────────────────────────
  double _haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadius = 6371000.0; // metres
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;
}

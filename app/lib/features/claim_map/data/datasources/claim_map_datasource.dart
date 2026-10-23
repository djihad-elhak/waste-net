import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/claim_map/data/models/claim_pin_model.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';

class ClaimMapDataSource {
  final FirebaseFirestore _firestore;

  ClaimMapDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Own pins – real-time stream ───────────────────────────────────────────
  Stream<List<ClaimPin>> watchOwnPins(String userId) {
    return _firestore
        .collection('claims')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ClaimPinModel.fromFirestore(
                  doc,
                  currentUserId: userId,
                  friendIds: const {},
                ))
            .where((p) => p.latitude != 0 && p.longitude != 0)
            .toList());
  }

  // ── Friend pins – real-time stream ────────────────────────────────────────
  Stream<List<ClaimPin>> watchFriendPins(String userId) async* {
    // First fetch friend IDs
    final friendsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();

    final friendIds =
        friendsSnap.docs.map((d) => d.id).toSet();

    if (friendIds.isEmpty) {
      yield [];
      return;
    }

    // Firestore whereIn supports up to 30 values
    final batch = friendIds.take(30).toList();

    yield* _firestore
        .collection('claims')
        .where('userId', whereIn: batch)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ClaimPinModel.fromFirestore(
                  doc,
                  currentUserId: userId,
                  friendIds: friendIds,
                ))
            .where((p) => p.latitude != 0 && p.longitude != 0)
            .toList());
  }

  // ── Heat zones ────────────────────────────────────────────────────────────
  // Approach: query claims in bounding box, cluster by ~0.005° grid cells
  Future<({List<HeatZone> zones, Failure? failure})> getHeatZones({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    try {
      // Firestore doesn't support 2D range queries natively without GeoFlutterFire.
      // We query by latitude range; longitude filtering is done client-side.
      final snap = await _firestore
          .collection('claims')
          .where('latitude', isGreaterThanOrEqualTo: swLat)
          .where('latitude', isLessThanOrEqualTo: neLat)
          .limit(500)
          .get();

      // Filter longitude client-side
      final inBounds = snap.docs.where((doc) {
        final data = doc.data();
        final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
        return lng >= swLng && lng <= neLng;
      }).toList();

      // Cluster into ~300m grid cells (≈0.003°)
      const gridSize = 0.003;
      final Map<String, List<_LatLng>> clusters = {};

      for (final doc in inBounds) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
        if (lat == 0 && lng == 0) continue;

        final cellLat = (lat / gridSize).floor() * gridSize;
        final cellLng = (lng / gridSize).floor() * gridSize;
        final key = '$cellLat,$cellLng';

        clusters.putIfAbsent(key, () => []).add(_LatLng(lat, lng));
      }

      final zones = clusters.entries.map((e) {
        final points = e.value;
        final avgLat =
            points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
        final avgLng =
            points.map((p) => p.lng).reduce((a, b) => a + b) / points.length;

        return HeatZone(
          latitude: avgLat,
          longitude: avgLng,
          claimCount: points.length,
        );
      }).toList();

      return (zones: zones, failure: null);
    } catch (_) {
      return (zones: <HeatZone>[], failure: const ServerFailure());
    }
  }

  // ── User impact stats ─────────────────────────────────────────────────────
  Future<({UserImpactStats? stats, Failure? failure})> getUserImpactStats(
      String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Total claims
      final totalQuery = await _firestore
          .collection('claims')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      // This month's claims
      final monthQuery = await _firestore
          .collection('claims')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .count()
          .get();

      // Distinct areas (approximate: count distinct ~0.01° grid cells)
      final locationSnap = await _firestore
          .collection('claims')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      final cells = <String>{};
      for (final doc in locationSnap.docs) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
        if (lat == 0 && lng == 0) continue;
        final cell =
            '${(lat / 0.01).floor()},${(lng / 0.01).floor()}';
        cells.add(cell);
      }

      final stats = UserImpactStats.fromClaimCount(
        total: totalQuery.count ?? 0,
        thisMonth: monthQuery.count ?? 0,
        areas: cells.length,
      );

      return (stats: stats, failure: null);
    } catch (_) {
      return (
        stats: UserImpactStats.fromClaimCount(
            total: 0, thisMonth: 0, areas: 0),
        failure: null,
      );
    }
  }

  // ── Single claim detail ───────────────────────────────────────────────────
  Future<({ClaimPin? pin, Failure? failure})> getClaimDetail(
      String claimId, String currentUserId) async {
    try {
      final doc =
          await _firestore.collection('claims').doc(claimId).get();
      if (!doc.exists) {
        return (pin: null, failure: const ServerFailure('Claim not found.'));
      }
      final pin = ClaimPinModel.fromFirestore(
        doc,
        currentUserId: currentUserId,
        friendIds: const {},
      );
      return (pin: pin, failure: null);
    } catch (_) {
      return (pin: null, failure: const ServerFailure());
    }
  }
}

class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}

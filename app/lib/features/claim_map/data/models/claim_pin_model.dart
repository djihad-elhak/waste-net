import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/features/claim_map/domain/entities/claim_pin.dart';
import 'package:trash/features/claiming/data/datasources/trash_label_map.dart';

class ClaimPinModel extends ClaimPin {
  const ClaimPinModel({
    required super.id,
    required super.userId,
    required super.latitude,
    required super.longitude,
    required super.category,
    required super.claimedAt,
    super.photoUrl,
    required super.isOwn,
    super.isFriend,
  });

  factory ClaimPinModel.fromFirestore(
    DocumentSnapshot doc, {
    required String currentUserId,
    required Set<String> friendIds,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final categoryIndex = data['categoryIndex'] as int? ?? 0;
    final docUserId = data['userId'] as String? ?? '';

    final location = data['location'] as GeoPoint?;
    final lat = location?.latitude ??
        (data['latitude'] as num?)?.toDouble() ??
        0.0;
    final lng = location?.longitude ??
        (data['longitude'] as num?)?.toDouble() ??
        0.0;

    return ClaimPinModel(
      id: doc.id,
      userId: docUserId,
      latitude: lat,
      longitude: lng,
      category: TrashLabelMap.byIndex(categoryIndex) ??
          TrashLabelMap.categories.first,
      claimedAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      isOwn: docUserId == currentUserId,
      isFriend: friendIds.contains(docUserId),
    );
  }
}

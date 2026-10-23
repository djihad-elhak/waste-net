import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/features/claiming/data/datasources/trash_label_map.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';

class TrashClaimModel extends TrashClaim {
  const TrashClaimModel({
    super.id,
    required super.userId,
    required super.category,
    required super.confidence,
    required super.coinsAwarded,
    required super.scoreAwarded,
    required super.starsAwarded,
    super.latitude,
    super.longitude,
    super.photoUrl,
    super.localPhotoPath,
    super.imageHash,
    super.note,
    super.isSynced,
    required super.createdAt,
  });

  factory TrashClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categoryIndex = data['categoryIndex'] as int? ?? 0;

    return TrashClaimModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      category: TrashLabelMap.byIndex(categoryIndex) ?? TrashLabelMap.categories.first,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      coinsAwarded: data['coinsAwarded'] as int? ?? 0,
      scoreAwarded: data['scoreAwarded'] as int? ?? 0,
      starsAwarded: data['starsAwarded'] as int? ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photoUrl: data['photoUrl'] as String?,
      imageHash: data['imageHash'] as String?,
      note: data['note'] as String?,
      isSynced: true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryIndex': category.classIndex,
      'categoryKey': category.modelKey,
      'categoryDisplayName': category.displayName,
      'confidence': confidence,
      'coinsAwarded': coinsAwarded,
      'scoreAwarded': scoreAwarded,
      'starsAwarded': starsAwarded,
      'latitude': latitude,
      'longitude': longitude,
      if (latitude != null && longitude != null)
        'location': GeoPoint(latitude!, longitude!),
      'photoUrl': photoUrl,
      'imageHash': imageHash,
      'note': note,
      'rarity': category.rarity.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TrashClaimModel.fromEntity(TrashClaim claim) {
    return TrashClaimModel(
      id: claim.id,
      userId: claim.userId,
      category: claim.category,
      confidence: claim.confidence,
      coinsAwarded: claim.coinsAwarded,
      scoreAwarded: claim.scoreAwarded,
      starsAwarded: claim.starsAwarded,
      latitude: claim.latitude,
      longitude: claim.longitude,
      photoUrl: claim.photoUrl,
      localPhotoPath: claim.localPhotoPath,
      imageHash: claim.imageHash,
      note: claim.note,
      isSynced: claim.isSynced,
      createdAt: claim.createdAt,
    );
  }
}

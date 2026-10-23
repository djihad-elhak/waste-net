import 'package:trash/features/claiming/data/datasources/trash_label_map.dart';

class TrashClaim {
  final String? id;                 // Firestore doc ID (null before saved)
  final String userId;
  final TrashCategory category;
  final double confidence;
  final int coinsAwarded;
  final int scoreAwarded;
  final int starsAwarded;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;           // Firebase Storage URL after upload
  final String? localPhotoPath;     // Local file path before upload
  final String? imageHash;          // SHA256 for duplicate detection
  final String? note;
  final bool isSynced;
  final DateTime createdAt;

  const TrashClaim({
    this.id,
    required this.userId,
    required this.category,
    required this.confidence,
    required this.coinsAwarded,
    required this.scoreAwarded,
    required this.starsAwarded,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.localPhotoPath,
    this.imageHash,
    this.note,
    this.isSynced = false,
    required this.createdAt,
  });

  TrashClaim copyWith({
    String? id,
    String? userId,
    TrashCategory? category,
    double? confidence,
    int? coinsAwarded,
    int? scoreAwarded,
    int? starsAwarded,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? localPhotoPath,
    String? imageHash,
    String? note,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return TrashClaim(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      scoreAwarded: scoreAwarded ?? this.scoreAwarded,
      starsAwarded: starsAwarded ?? this.starsAwarded,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      imageHash: imageHash ?? this.imageHash,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Reward calculation result returned to presentation
class ClaimRewards {
  final int coins;
  final int score;
  final int stars;
  final double bonusMultiplier;
  final bool isFirstClaimToday;
  final bool streakBonus;

  const ClaimRewards({
    required this.coins,
    required this.score,
    required this.stars,
    required this.bonusMultiplier,
    required this.isFirstClaimToday,
    required this.streakBonus,
  });
}

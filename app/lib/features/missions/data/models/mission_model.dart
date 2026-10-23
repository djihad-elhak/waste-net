import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';

class MissionModel extends Mission {
  const MissionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.emoji,
    required super.type,
    required super.status,
    required super.difficulty,
    required super.targetCount,
    required super.currentCount,
    required super.rewardCoins,
    required super.rewardStars,
    required super.rewardScore,
    super.rewardBadgeId,
    required super.expiresAt,
    super.completedAt,
    super.claimedAt,
    super.requiredCategory,
    super.requiredArea,
    super.requiresLocation,
    super.eventName,
    super.eventBannerEmoji,
  });

  factory MissionModel.fromFirestore(
    DocumentSnapshot missionDoc,
    Map<String, dynamic>? progressData,
  ) {
    final d = missionDoc.data() as Map<String, dynamic>;
    final current = progressData?['current'] as int? ?? 0;
    final claimedAt =
        (progressData?['claimedAt'] as Timestamp?)?.toDate();
    final completedAt =
        (progressData?['completedAt'] as Timestamp?)?.toDate();

    final target = d['targetCount'] as int? ?? 1;
    final isComplete = current >= target;

    MissionStatus status;
    if (claimedAt != null) {
      status = MissionStatus.claimed;
    } else if (isComplete) {
      status = MissionStatus.completed;
    } else {
      status = MissionStatus.active;
    }

    return MissionModel(
      id: missionDoc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '🎯',
      type: MissionType.values.firstWhere(
        (t) => t.name == (d['type'] as String?),
        orElse: () => MissionType.daily,
      ),
      status: status,
      difficulty: MissionDifficulty.values.firstWhere(
        (d2) => d2.name == (d['difficulty'] as String?),
        orElse: () => MissionDifficulty.easy,
      ),
      targetCount: target,
      currentCount: current,
      rewardCoins: d['rewardCoins'] as int? ?? 50,
      rewardStars: d['rewardStars'] as int? ?? 1,
      rewardScore: d['rewardScore'] as int? ?? 10,
      rewardBadgeId: d['rewardBadgeId'] as String?,
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      completedAt: completedAt,
      claimedAt: claimedAt,
      requiredCategory: d['requiredCategory'] as String?,
      requiredArea: d['requiredArea'] as String?,
      requiresLocation: d['requiresLocation'] as bool? ?? false,
      eventName: d['eventName'] as String?,
      eventBannerEmoji: d['eventBannerEmoji'] as String?,
    );
  }

  /// Seeded mission template → Firestore document
  static Map<String, dynamic> seedTemplate({
    required String title,
    required String description,
    required String emoji,
    required MissionType type,
    required MissionDifficulty difficulty,
    required int targetCount,
    required int rewardCoins,
    required int rewardStars,
    required int rewardScore,
    String? requiredCategory,
    String? eventName,
  }) {
    final now = DateTime.now();
    final expiry = type == MissionType.weekly
        ? DateTime(now.year, now.month, now.day + (7 - now.weekday))
            .add(const Duration(hours: 23, minutes: 59))
        : DateTime(now.year, now.month, now.day, 23, 59);

    return {
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.name,
      'difficulty': difficulty.name,
      'targetCount': targetCount,
      'rewardCoins': rewardCoins,
      'rewardStars': rewardStars,
      'rewardScore': rewardScore,
      if (requiredCategory != null) 'requiredCategory': requiredCategory,
      if (eventName != null) 'eventName': eventName,
      'requiresLocation': false,
      'expiresAt': Timestamp.fromDate(expiry),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

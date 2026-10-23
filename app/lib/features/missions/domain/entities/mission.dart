// ─────────────────────────────────────────────────────────────────────────────
// Mission – full entity (richer than MissionPreview used on home screen)
// ─────────────────────────────────────────────────────────────────────────────

enum MissionType { daily, weekly, special, seasonal }

enum MissionStatus { locked, active, completed, claimed }

enum MissionDifficulty { easy, medium, hard, legendary }

class Mission {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final MissionType type;
  final MissionStatus status;
  final MissionDifficulty difficulty;

  // Progress
  final int targetCount;
  final int currentCount;

  // Rewards
  final int rewardCoins;
  final int rewardStars;
  final int rewardScore;
  final String? rewardBadgeId; // Optional badge unlock

  // Timing
  final DateTime expiresAt;
  final DateTime? completedAt;
  final DateTime? claimedAt;

  // Optional constraints
  final String? requiredCategory;   // e.g. 'plastic_bottle'
  final String? requiredArea;       // e.g. 'near_school'
  final bool requiresLocation;

  // Event info (for seasonal)
  final String? eventName;          // e.g. 'Earth Day Marathon'
  final String? eventBannerEmoji;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.status,
    required this.difficulty,
    required this.targetCount,
    required this.currentCount,
    required this.rewardCoins,
    required this.rewardStars,
    required this.rewardScore,
    this.rewardBadgeId,
    required this.expiresAt,
    this.completedAt,
    this.claimedAt,
    this.requiredCategory,
    this.requiredArea,
    this.requiresLocation = false,
    this.eventName,
    this.eventBannerEmoji,
  });

  // ── Computed ─────────────────────────────────────────────────────────────
  double get progress =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == MissionStatus.completed ||
      status == MissionStatus.claimed;

  bool get isClaimed => status == MissionStatus.claimed;

  bool get canClaim =>
      status == MissionStatus.completed && claimedAt == null;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get progressLabel => '$currentCount / $targetCount';

  String get timeLeft {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 1) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours >= 1) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m left';
  }

  bool get isUrgent {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inHours < 3 && !isCompleted;
  }

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    MissionType? type,
    MissionStatus? status,
    MissionDifficulty? difficulty,
    int? targetCount,
    int? currentCount,
    int? rewardCoins,
    int? rewardStars,
    int? rewardScore,
    String? rewardBadgeId,
    DateTime? expiresAt,
    DateTime? completedAt,
    DateTime? claimedAt,
    String? requiredCategory,
    String? requiredArea,
    bool? requiresLocation,
    String? eventName,
    String? eventBannerEmoji,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardStars: rewardStars ?? this.rewardStars,
      rewardScore: rewardScore ?? this.rewardScore,
      rewardBadgeId: rewardBadgeId ?? this.rewardBadgeId,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      requiredCategory: requiredCategory ?? this.requiredCategory,
      requiredArea: requiredArea ?? this.requiredArea,
      requiresLocation: requiresLocation ?? this.requiresLocation,
      eventName: eventName ?? this.eventName,
      eventBannerEmoji: eventBannerEmoji ?? this.eventBannerEmoji,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension helpers
// ─────────────────────────────────────────────────────────────────────────────
extension MissionTypeLabel on MissionType {
  String get label {
    switch (this) {
      case MissionType.daily:    return 'Daily';
      case MissionType.weekly:   return 'Weekly';
      case MissionType.special:  return 'Special';
      case MissionType.seasonal: return 'Seasonal';
    }
  }
  String get emoji {
    switch (this) {
      case MissionType.daily:    return '☀️';
      case MissionType.weekly:   return '📅';
      case MissionType.special:  return '⚡';
      case MissionType.seasonal: return '🌿';
    }
  }
}

extension MissionDifficultyLabel on MissionDifficulty {
  String get label {
    switch (this) {
      case MissionDifficulty.easy:       return 'Easy';
      case MissionDifficulty.medium:     return 'Medium';
      case MissionDifficulty.hard:       return 'Hard';
      case MissionDifficulty.legendary:  return 'Legendary';
    }
  }

  // Using Flutter Color
  int get colorValue {
    switch (this) {
      case MissionDifficulty.easy:       return 0xFF1FD47A; // green
      case MissionDifficulty.medium:     return 0xFFFFB830; // amber
      case MissionDifficulty.hard:       return 0xFFFF6B2C; // orange
      case MissionDifficulty.legendary:  return 0xFFB46EFF; // purple
    }
  }
}

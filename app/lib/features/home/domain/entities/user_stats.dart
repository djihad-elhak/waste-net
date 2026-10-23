// ─────────────────────────────────────────────────────────────────────────────
// UserStats – everything the Home Dashboard needs from Firestore
// ─────────────────────────────────────────────────────────────────────────────

class UserStats {
  final String uid;
  final String firstName;
  final String username;
  final String? photoUrl;

  // Currency
  final int coins;
  final int stars;
  final int score;

  // Levelling
  final int level;
  final int totalClaims;

  // Streak
  final int streak;
  final DateTime? lastClaimAt;

  // Today
  final int claimsToday;

  // Rank
  final int? globalRank;

  const UserStats({
    required this.uid,
    required this.firstName,
    required this.username,
    this.photoUrl,
    required this.coins,
    required this.stars,
    required this.score,
    required this.level,
    required this.totalClaims,
    required this.streak,
    this.lastClaimAt,
    required this.claimsToday,
    this.globalRank,
  });

  // Stars needed per level: level N requires N * 50 stars
  int get starsForCurrentLevel => (level - 1) * 50;
  int get starsForNextLevel => level * 50;
  int get starsIntoCurrentLevel => stars - starsForCurrentLevel;
  int get starsNeededForNextLevel => starsForNextLevel - starsForCurrentLevel;

  double get levelProgress {
    if (starsNeededForNextLevel <= 0) return 1.0;
    return (starsIntoCurrentLevel / starsNeededForNextLevel).clamp(0.0, 1.0);
  }

  bool get isStreakActive {
    if (lastClaimAt == null) return false;
    final now = DateTime.now();
    final diff = now.difference(lastClaimAt!);
    return diff.inHours < 48;
  }

  UserStats copyWith({
    String? uid,
    String? firstName,
    String? username,
    String? photoUrl,
    int? coins,
    int? stars,
    int? score,
    int? level,
    int? totalClaims,
    int? streak,
    DateTime? lastClaimAt,
    int? claimsToday,
    int? globalRank,
  }) {
    return UserStats(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      coins: coins ?? this.coins,
      stars: stars ?? this.stars,
      score: score ?? this.score,
      level: level ?? this.level,
      totalClaims: totalClaims ?? this.totalClaims,
      streak: streak ?? this.streak,
      lastClaimAt: lastClaimAt ?? this.lastClaimAt,
      claimsToday: claimsToday ?? this.claimsToday,
      globalRank: globalRank ?? this.globalRank,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RewardItem – shown in the rewards carousel
// ─────────────────────────────────────────────────────────────────────────────

class RewardItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int coinCost;
  final String partnerName;
  final bool isAvailable;
  final RewardCategory category;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.coinCost,
    required this.partnerName,
    required this.isAvailable,
    required this.category,
  });

  bool canAfford(int userCoins) => userCoins >= coinCost;
}

enum RewardCategory { internet, food, entertainment, books, other }

// ─────────────────────────────────────────────────────────────────────────────
// MissionPreview – lightweight version for home screen
// ─────────────────────────────────────────────────────────────────────────────

class MissionPreview {
  final String id;
  final String title;
  final String emoji;
  final int targetCount;
  final int currentCount;
  final int rewardCoins;
  final bool isCompleted;
  final DateTime expiresAt;

  const MissionPreview({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetCount,
    required this.currentCount,
    required this.rewardCoins,
    required this.isCompleted,
    required this.expiresAt,
  });

  double get progress =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  String get progressLabel => '$currentCount / $targetCount';

  String get timeLeft {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inHours >= 1) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}

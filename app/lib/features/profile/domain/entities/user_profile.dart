// ─────────────────────────────────────────────────────────────────────────────
// UserProfile – full profile as shown on the profile screen
// ─────────────────────────────────────────────────────────────────────────────
class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? photoUrl;

  // Stats
  final int coins;
  final int stars;
  final int score;
  final int level;
  final int totalClaims;
  final int streak;
  final int globalRank;

  // Distribution by category
  final Map<String, int> claimsByCategory;

  // Badges earned
  final List<TrashBadge > badges;

  // Account
  final DateTime joinedAt;
  final bool isEmailVerified;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.coins,
    required this.stars,
    required this.score,
    required this.level,
    required this.totalClaims,
    required this.streak,
    required this.globalRank,
    required this.claimsByCategory,
    required this.badges,
    required this.joinedAt,
    required this.isEmailVerified,
  });

  String get fullName => '$firstName $lastName';
  int get starsForNextLevel => level * 50;
  double get levelProgress =>
      ((stars - (level - 1) * 50) / 50).clamp(0.0, 1.0);

  String get levelTitle {
    if (level < 3)  return 'Rookie Cleaner';
    if (level < 6)  return 'Street Guardian';
    if (level < 10) return 'Eco Warrior';
    if (level < 15) return 'City Champion';
    return 'TrashGo Legend';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge
// ─────────────────────────────────────────────────────────────────────────────
class TrashBadge  {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final BadgeRarity rarity;
  final DateTime earnedAt;

  const TrashBadge ({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.rarity,
    required this.earnedAt,
  });
}

enum BadgeRarity { bronze, silver, gold, platinum }

extension BadgeRarityExt on BadgeRarity {
  String get label => switch (this) {
        BadgeRarity.bronze   => 'Bronze',
        BadgeRarity.silver   => 'Silver',
        BadgeRarity.gold     => 'Gold',
        BadgeRarity.platinum => 'Platinum',
      };
  int get colorValue => switch (this) {
        BadgeRarity.bronze   => 0xFFCD7F32,
        BadgeRarity.silver   => 0xFFADB5BD,
        BadgeRarity.gold     => 0xFFFFD700,
        BadgeRarity.platinum => 0xFFB46EFF,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Edit Form data
// ─────────────────────────────────────────────────────────────────────────────
class ProfileEditData {
  final String firstName;
  final String lastName;
  final String username;
  final String? photoUrl;

  const ProfileEditData({
    required this.firstName,
    required this.lastName,
    required this.username,
    this.photoUrl,
  });
}

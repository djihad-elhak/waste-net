// ─────────────────────────────────────────────────────────────────────────────
// Friend
// ─────────────────────────────────────────────────────────────────────────────
class Friend {
  final String uid;
  final String username;
  final String firstName;
  final String? photoUrl;
  final int level;
  final int totalClaims;
  final int coins;
  final int streak;
  final FriendStatus status;
  final DateTime? friendSince;

  const Friend({
    required this.uid,
    required this.username,
    required this.firstName,
    this.photoUrl,
    required this.level,
    required this.totalClaims,
    required this.coins,
    required this.streak,
    required this.status,
    this.friendSince,
  });
}

enum FriendStatus { accepted, pending, requested }

// ─────────────────────────────────────────────────────────────────────────────
// Friend Activity Feed Item
// ─────────────────────────────────────────────────────────────────────────────
class FeedItem {
  final String id;
  final String userId;
  final String username;
  final String firstName;
  final String? photoUrl;
  final FeedItemType type;
  final String categoryDisplayName;
  final String categoryEmoji;
  final int coinsEarned;
  final int claimCount;       // for "X claimed Y items" batch
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.firstName,
    this.photoUrl,
    required this.type,
    required this.categoryDisplayName,
    required this.categoryEmoji,
    required this.coinsEarned,
    required this.claimCount,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

enum FeedItemType { claim, levelUp, missionComplete, streak }

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard Entry
// ─────────────────────────────────────────────────────────────────────────────
class LeaderboardEntry {
  final int rank;
  final String uid;
  final String username;
  final String firstName;
  final String? photoUrl;
  final int level;
  final int coins;
  final int totalClaims;
  final int score;
  final int streak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.username,
    required this.firstName,
    this.photoUrl,
    required this.level,
    required this.coins,
    required this.totalClaims,
    required this.score,
    required this.streak,
    required this.isCurrentUser,
  });
}

enum LeaderboardScope { global, local, friends }
enum LeaderboardPeriod { weekly, allTime }

// ─────────────────────────────────────────────────────────────────────────────
// User Search Result
// ─────────────────────────────────────────────────────────────────────────────
class UserSearchResult {
  final String uid;
  final String username;
  final String firstName;
  final String? photoUrl;
  final int level;
  final bool isFriend;
  final bool hasRequestPending;

  const UserSearchResult({
    required this.uid,
    required this.username,
    required this.firstName,
    this.photoUrl,
    required this.level,
    required this.isFriend,
    required this.hasRequestPending,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/social/domain/entities/social_entities.dart';


class SocialDataSource {
  final FirebaseFirestore _db;

  SocialDataSource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Friends stream ────────────────────────────────────────────────────────
  Stream<List<Friend>> watchFriends(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) return <Friend>[];

      final friendIds = snap.docs.map((d) => d.id).toList();
      final friendDocs = await Future.wait(
        friendIds.map((id) =>
            _db.collection('users').doc(id).get()),
      );

      return friendDocs
          .where((d) => d.exists)
          .map((d) => _friendFromDoc(d, snap.docs
              .firstWhere((s) => s.id == d.id,
                  orElse: () => snap.docs.first)
              .data()))
          .toList();
    });
  }

  Friend _friendFromDoc(
      DocumentSnapshot userDoc, Map<String, dynamic> friendMeta) {
    final d = userDoc.data() as Map<String, dynamic>;
    return Friend(
      uid: userDoc.id,
      username: d['username'] as String? ?? '',
      firstName: d['firstName'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      level: d['level'] as int? ?? 1,
      totalClaims: d['totalClaims'] as int? ?? 0,
      coins: d['coins'] as int? ?? 0,
      streak: d['streak'] as int? ?? 0,
      status: FriendStatus.accepted,
      friendSince:
          (friendMeta['since'] as Timestamp?)?.toDate(),
    );
  }

  // ── Friend activity feed ──────────────────────────────────────────────────
  Future<({List<FeedItem> items, Failure? failure})> getFriendFeed(
      String userId) async {
    try {
      final friendsSnap = await _db
          .collection('users')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .limit(30)
          .get();

      final friendIds =
          friendsSnap.docs.map((d) => d.id).toList();

      if (friendIds.isEmpty) return (items: _mockFeed(), failure: null);

      final batch = friendIds.take(30).toList();
      final claimsSnap = await _db
          .collection('claims')
          .where('userId', whereIn: batch)
          .orderBy('createdAt', descending: true)
          .limit(40)
          .get();

      // Fetch friend user docs for display names
      final userDocs = await Future.wait(
        friendIds.take(10).map((id) =>
            _db.collection('users').doc(id).get()),
      );
      final userMap = {
        for (final d in userDocs.where((d) => d.exists))
          d.id: d.data() as Map<String, dynamic>
      };

      final items = claimsSnap.docs.map((doc) {
        final d = doc.data();
        final uid = d['userId'] as String? ?? '';
        final u = userMap[uid] ?? {};
        return FeedItem(
          id: doc.id,
          userId: uid,
          username: u['username'] as String? ?? 'user',
          firstName: u['firstName'] as String? ?? '',
          photoUrl: u['photoUrl'] as String?,
          type: FeedItemType.claim,
          categoryDisplayName:
              d['categoryDisplayName'] as String? ?? 'Trash',
          categoryEmoji:
              _emojiForKey(d['categoryKey'] as String? ?? ''),
          coinsEarned: d['coinsAwarded'] as int? ?? 0,
          claimCount: 1,
          createdAt:
              (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      return (items: items.isEmpty ? _mockFeed() : items, failure: null);
    } catch (_) {
      return (items: _mockFeed(), failure: null);
    }
  }

  String _emojiForKey(String key) {
    const map = {
      'plastic_bottle': '🍶',
      'plastic_bag': '🛍️',
      'metal_can': '🥫',
      'glass': '🍾',
      'paper': '📄',
      'cardboard': '📦',
      'organic': '🍂',
      'cigarette': '🚬',
      'electronics': '📱',
      'carton_milk': '🥛',
    };
    return map[key] ?? '♻️';
  }

  List<FeedItem> _mockFeed() => [
        FeedItem(
          id: 'mock1',
          userId: 'u1',
          username: 'greenwarrior',
          firstName: 'Ahmed',
          type: FeedItemType.claim,
          categoryDisplayName: 'Plastic Bottle',
          categoryEmoji: '🍶',
          coinsEarned: 35,
          claimCount: 3,
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        FeedItem(
          id: 'mock2',
          userId: 'u2',
          username: 'ecohero42',
          firstName: 'Sara',
          type: FeedItemType.missionComplete,
          categoryDisplayName: 'Daily Mission',
          categoryEmoji: '🎯',
          coinsEarned: 100,
          claimCount: 5,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        FeedItem(
          id: 'mock3',
          userId: 'u3',
          username: 'cleanstreets',
          firstName: 'Youssef',
          type: FeedItemType.levelUp,
          categoryDisplayName: 'Level Up',
          categoryEmoji: '⬆️',
          coinsEarned: 0,
          claimCount: 0,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];

  // ── Leaderboard ───────────────────────────────────────────────────────────
  Future<({List<LeaderboardEntry> entries, Failure? failure})> getLeaderboard({
    required String userId,
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    String? city,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _db.collection('users');

      // Sort by score (all-time) or weekly score
      final scoreField =
          period == LeaderboardPeriod.allTime ? 'score' : 'weeklyScore';
      query = query.orderBy(scoreField, descending: true).limit(100);

      if (scope == LeaderboardScope.friends) {
        // Friends leaderboard: get friend IDs first
        final friendsSnap = await _db
            .collection('users')
            .doc(userId)
            .collection('friends')
            .where('status', isEqualTo: 'accepted')
            .get();
        final friendIds = [
          userId,
          ...friendsSnap.docs.map((d) => d.id)
        ];
        if (friendIds.length > 1) {
          query = _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendIds.take(30).toList())
              .orderBy(scoreField, descending: true);
        }
      }

      final snap = await query.get();
      final entries = snap.docs.asMap().entries.map((e) {
        final rank = e.key + 1;
        final d = e.value.data();
        return LeaderboardEntry(
          rank: rank,
          uid: e.value.id,
          username: d['username'] as String? ?? '',
          firstName: d['firstName'] as String? ?? '',
          photoUrl: d['photoUrl'] as String?,
          level: d['level'] as int? ?? 1,
          coins: d['coins'] as int? ?? 0,
          totalClaims: d['totalClaims'] as int? ?? 0,
          score: d[scoreField] as int? ?? 0,
          streak: d['streak'] as int? ?? 0,
          isCurrentUser: e.value.id == userId,
        );
      }).toList();

      return (entries: entries.isEmpty ? _mockLeaderboard(userId) : entries, failure: null);
    } catch (_) {
      return (entries: _mockLeaderboard(userId), failure: null);
    }
  }

  List<LeaderboardEntry> _mockLeaderboard(String userId) => [
        _mockEntry(1, 'trashking_dz', 'Karim', 9842, false),
        _mockEntry(2, 'ecowarrior', 'Amira', 8765, false),
        _mockEntry(3, 'greenalgiers', 'Sofiane', 7230, false),
        _mockEntry(4, 'cleanstreets', 'Nadia', 6540, false),
        _mockEntry(5, 'you', 'You', 4320, true),
        _mockEntry(6, 'ecohero42', 'Sara', 3980, false),
        _mockEntry(7, 'dirtbuster', 'Omar', 3210, false),
        _mockEntry(8, 'greenwarrior', 'Ahmed', 2980, false),
        _mockEntry(9, 'claimer99', 'Zied', 2450, false),
        _mockEntry(10, 'tidycity', 'Leila', 1980, false),
      ];

  LeaderboardEntry _mockEntry(int rank, String username, String firstName,
      int score, bool isCurrentUser) {
    return LeaderboardEntry(
      rank: rank,
      uid: 'uid_$username',
      username: username,
      firstName: firstName,
      level: (score / 500).floor().clamp(1, 20),
      coins: score * 3,
      totalClaims: (score / 12).floor(),
      score: score,
      streak: rank < 4 ? 7 : 1,
      isCurrentUser: isCurrentUser,
    );
  }

  // ── Search users ──────────────────────────────────────────────────────────
  Future<({List<UserSearchResult> results, Failure? failure})> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    try {
      if (query.trim().length < 2) return (results: <UserSearchResult>[], failure: null);

      final snap = await _db
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(15)
          .get();

      final friendsSnap = await _db
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .get();
      final friendIds = friendsSnap.docs.map((d) => d.id).toSet();

      final results = snap.docs
          .where((d) => d.id != currentUserId)
          .map((d) {
        final data = d.data();
        return UserSearchResult(
          uid: d.id,
          username: data['username'] as String? ?? '',
          firstName: data['firstName'] as String? ?? '',
          photoUrl: data['photoUrl'] as String?,
          level: data['level'] as int? ?? 1,
          isFriend: friendIds.contains(d.id),
          hasRequestPending: false,
        );
      }).toList();

      return (results: results, failure: null);
    } catch (_) {
      return (results: <UserSearchResult>[], failure: const ServerFailure());

    }
  }

  // ── Friend requests ───────────────────────────────────────────────────────
  Future<({bool success, Failure? failure})> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final batch = _db.batch();
      final now = Timestamp.now();

      // Outgoing: requester's side
      batch.set(
        _db.collection('users').doc(fromUserId)
            .collection('friends').doc(toUserId),
        {'status': 'requested', 'since': now},
      );

      // Incoming: recipient's side
      batch.set(
        _db.collection('users').doc(toUserId)
            .collection('friends').doc(fromUserId),
        {'status': 'pending', 'since': now},
      );

      await batch.commit();
      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  Future<({bool success, Failure? failure})> acceptFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    try {
      final batch = _db.batch();
      batch.update(
        _db.collection('users').doc(userId)
            .collection('friends').doc(requesterId),
        {'status': 'accepted'},
      );
      batch.update(
        _db.collection('users').doc(requesterId)
            .collection('friends').doc(userId),
        {'status': 'accepted'},
      );
      await batch.commit();
      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  Future<({bool success, Failure? failure})> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(userId)
          .collection('friends').doc(friendId));
      batch.delete(_db.collection('users').doc(friendId)
          .collection('friends').doc(userId));
      await batch.commit();
      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/home/domain/entities/user_stats.dart';

class HomeDataSource {
  final FirebaseFirestore _firestore;

  HomeDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Real-time user stats ──────────────────────────────────────────────────
  Stream<UserStats> watchUserStats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snap) async {
      if (!snap.exists || snap.data() == null) {
        return UserStats(
          uid: userId,
          firstName: '',
          username: '',
          coins: 0,
          stars: 0,
          score: 0,
          level: 1,
          totalClaims: 0,
          streak: 0,
          claimsToday: 0,
        );
      }

      final data = snap.data() ?? {};

      // Count today's claims
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayQuery = await _firestore
          .collection('claims')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();

      return UserStats(
        uid: snap.id,
        firstName: data['firstName'] as String? ?? '',
        username: data['username'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        coins: data['coins'] as int? ?? 0,
        stars: data['stars'] as int? ?? 0,
        score: data['score'] as int? ?? 0,
        level: data['level'] as int? ?? 1,
        totalClaims: data['totalClaims'] as int? ?? 0,
        streak: data['streak'] as int? ?? 0,
        lastClaimAt:
            (data['lastClaimAt'] as Timestamp?)?.toDate(),
        claimsToday: todayQuery.count ?? 0,
        globalRank: data['globalRank'] as int?,
      );
    });
  }

  // ── Daily missions ────────────────────────────────────────────────────────
  Future<({List<MissionPreview> missions, Failure? failure})>
      getDailyMissions(String userId) async {
    try {
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snap = await _firestore
          .collection('missions')
          .where('type', isEqualTo: 'daily')
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .limit(3)
          .get();

      // Get user's progress for each mission
      final progressSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mission_progress')
          .get();

      final progressMap = {
        for (final d in progressSnap.docs) d.id: d.data()
      };

      final missions = snap.docs.map((doc) {
        final data = doc.data();
        final progress = progressMap[doc.id] ?? {};
        final current = progress['current'] as int? ?? 0;
        final target = data['targetCount'] as int? ?? 1;

        return MissionPreview(
          id: doc.id,
          title: data['title'] as String? ?? '',
          emoji: data['emoji'] as String? ?? '🎯',
          targetCount: target,
          currentCount: current,
          rewardCoins: data['rewardCoins'] as int? ?? 50,
          isCompleted: current >= target,
          expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        );
      }).toList();

      // If no missions in Firestore yet, return placeholders
      if (missions.isEmpty) {
        return (missions: _placeholderMissions(endOfDay), failure: null);
      }

      return (missions: missions, failure: null);
    } catch (_) {
      final endOfDay = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59);
      return (missions: _placeholderMissions(endOfDay), failure: null);
    }
  }

  List<MissionPreview> _placeholderMissions(DateTime expires) => [
        MissionPreview(
          id: 'daily_1',
          title: 'Claim 5 plastic items',
          emoji: '♻️',
          targetCount: 5,
          currentCount: 0,
          rewardCoins: 100,
          isCompleted: false,
          expiresAt: expires,
        ),
        MissionPreview(
          id: 'daily_2',
          title: 'Claim in 2 different streets',
          emoji: '🗺️',
          targetCount: 2,
          currentCount: 0,
          rewardCoins: 80,
          isCompleted: false,
          expiresAt: expires,
        ),
        MissionPreview(
          id: 'daily_3',
          title: 'Make your first claim today',
          emoji: '📸',
          targetCount: 1,
          currentCount: 0,
          rewardCoins: 50,
          isCompleted: false,
          expiresAt: expires,
        ),
      ];

  // ── Available rewards ─────────────────────────────────────────────────────
  Future<({List<RewardItem> rewards, Failure? failure})>
      getAvailableRewards() async {
    try {
      final snap = await _firestore
          .collection('rewards')
          .where('isAvailable', isEqualTo: true)
          .orderBy('coinCost')
          .get();

      if (snap.docs.isNotEmpty) {
        final rewards = snap.docs.map((doc) {
          final d = doc.data();
          return RewardItem(
            id: doc.id,
            title: d['title'] as String? ?? '',
            description: d['description'] as String? ?? '',
            emoji: d['emoji'] as String? ?? '🎁',
            coinCost: d['coinCost'] as int? ?? 100,
            partnerName: d['partnerName'] as String? ?? '',
            isAvailable: d['isAvailable'] as bool? ?? true,
            category: RewardCategory.values.firstWhere(
              (c) => c.name == (d['category'] as String?),
              orElse: () => RewardCategory.other,
            ),
          );
        }).toList();
        return (rewards: rewards, failure: null);
      }

      // Hardcoded fallback rewards
      return (rewards: _defaultRewards, failure: null);
    } catch (_) {
      return (rewards: _defaultRewards, failure: null);
    }
  }

  static final _defaultRewards = [
    const RewardItem(
      id: 'r1',
      title: '2 Hours Free Internet',
      description: 'Djezzy / Mobilis / Ooredoo',
      emoji: '📶',
      coinCost: 150,
      partnerName: 'Djezzy',
      isAvailable: true,
      category: RewardCategory.internet,
    ),
    const RewardItem(
      id: 'r2',
      title: 'Free eBook',
      description: 'Choose any title from our library',
      emoji: '📚',
      coinCost: 80,
      partnerName: 'BookLib',
      isAvailable: true,
      category: RewardCategory.books,
    ),
    const RewardItem(
      id: 'r3',
      title: 'Coffee Voucher',
      description: 'Redeemable at partner cafés',
      emoji: '☕',
      coinCost: 200,
      partnerName: 'Café Partner',
      isAvailable: true,
      category: RewardCategory.food,
    ),
    const RewardItem(
      id: 'r4',
      title: 'Cinema Ticket',
      description: 'Any screening this week',
      emoji: '🎬',
      coinCost: 350,
      partnerName: 'Cinéma',
      isAvailable: true,
      category: RewardCategory.entertainment,
    ),
    const RewardItem(
      id: 'r5',
      title: '500MB Data Pack',
      description: 'Instant top-up',
      emoji: '📡',
      coinCost: 75,
      partnerName: 'Ooredoo',
      isAvailable: true,
      category: RewardCategory.internet,
    ),
  ];

  // ── Redeem reward ─────────────────────────────────────────────────────────
  Future<({String? code, Failure? failure})> redeemReward({
    required String userId,
    required String rewardId,
    required int coinCost,
  }) async {
    try {
      final batch = _firestore.batch();

      // Deduct coins
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'coins': FieldValue.increment(-coinCost),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log redemption
      final redemptionRef = _firestore.collection('redemptions').doc();
      batch.set(redemptionRef, {
        'userId': userId,
        'rewardId': rewardId,
        'coinCost': coinCost,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      await batch.commit();

      // In production: call Cloud Function to generate partner code
      // For now return a mock code
      final mockCode =
          'TG-${rewardId.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      return (code: mockCode, failure: null);
    } catch (_) {
      return (
        code: null,
        failure: const ServerFailure('Redemption failed. Please try again.')
      );
    }
  }
}

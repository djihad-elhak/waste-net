import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/missions/data/models/mission_model.dart';
import 'package:trash/features/missions/domain/entities/mission.dart';

class MissionsDataSource {
  final FirebaseFirestore _db;

  MissionsDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const _missionsCol = 'missions';
  static const _usersCol = 'users';

  // ── Watch missions with user progress ─────────────────────────────────────
  Stream<List<Mission>> watchMissions(String userId) {
    final now = DateTime.now();

    // Stream global missions that haven't expired
    return _db
        .collection(_missionsCol)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .snapshots()
        .asyncMap((snap) async {
      // Fetch user's progress for each mission in one read
      final progressSnap = await _db
          .collection(_usersCol)
          .doc(userId)
          .collection('mission_progress')
          .get();

      final progressMap = {
        for (final d in progressSnap.docs) d.id: d.data(),
      };

      final missions = snap.docs.map((doc) {
        return MissionModel.fromFirestore(doc, progressMap[doc.id]);
      }).toList();

      // Sort: active first, then completed, then claimed
      missions.sort((a, b) {
        final order = {
          MissionStatus.active: 0,
          MissionStatus.completed: 1,
          MissionStatus.locked: 2,
          MissionStatus.claimed: 3,
        };
        return (order[a.status] ?? 0).compareTo(order[b.status] ?? 0);
      });

      return missions;
    });
  }

  // ── Claim mission reward ──────────────────────────────────────────────────
  Future<({bool success, Failure? failure})> claimMissionReward({
    required String userId,
    required String missionId,
    required int coins,
    required int stars,
    required int score,
  }) async {
    try {
      final batch = _db.batch();

      // Mark mission as claimed for this user
      final progressRef = _db
          .collection(_usersCol)
          .doc(userId)
          .collection('mission_progress')
          .doc(missionId);

      batch.update(progressRef, {
        'claimedAt': FieldValue.serverTimestamp(),
        'status': 'claimed',
      });

      // Add rewards to user stats
      final userRef = _db.collection(_usersCol).doc(userId);
      batch.update(userRef, {
        'coins': FieldValue.increment(coins),
        'stars': FieldValue.increment(stars),
        'score': FieldValue.increment(score),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return (success: true, failure: null);
    } on FirebaseException catch (e) {
      return (
        success: false,
        failure: ServerFailure(e.message ?? 'Failed to claim reward.'),
      );
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  // ── Seed missions if empty ────────────────────────────────────────────────
  Future<void> seedMissionsIfEmpty(String userId) async {
    try {
      final now = DateTime.now();
      final snap = await _db
          .collection(_missionsCol)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) return; // Already seeded

      final batch = _db.batch();
      final templates = _defaultMissionTemplates();

      for (final template in templates) {
        final ref = _db.collection(_missionsCol).doc();
        batch.set(ref, template);
      }

      await batch.commit();
    } catch (_) {
      // Non-fatal — missions just won't show
    }
  }

  List<Map<String, dynamic>> _defaultMissionTemplates() {
    return [
      // ── Daily ─────────────────────────────────────────────────────────
      MissionModel.seedTemplate(
        title: 'Claim 5 plastic items',
        description: 'Find and claim 5 plastic bottles or bags in your area.',
        emoji: '♻️',
        type: MissionType.daily,
        difficulty: MissionDifficulty.easy,
        targetCount: 5,
        rewardCoins: 100,
        rewardStars: 2,
        rewardScore: 30,
        requiredCategory: 'plastic_bottle',
      ),
      MissionModel.seedTemplate(
        title: 'Make your first claim today',
        description: 'Get out there and make at least one claim today.',
        emoji: '📸',
        type: MissionType.daily,
        difficulty: MissionDifficulty.easy,
        targetCount: 1,
        rewardCoins: 50,
        rewardStars: 1,
        rewardScore: 15,
      ),
      MissionModel.seedTemplate(
        title: 'Claim in 2 different streets',
        description: 'Explore your neighbourhood and claim in two locations.',
        emoji: '🗺️',
        type: MissionType.daily,
        difficulty: MissionDifficulty.medium,
        targetCount: 2,
        rewardCoins: 80,
        rewardStars: 1,
        rewardScore: 20,
      ),
      MissionModel.seedTemplate(
        title: 'Find a rare item today',
        description: 'Claim an Epic or Rare rarity trash item.',
        emoji: '💎',
        type: MissionType.daily,
        difficulty: MissionDifficulty.hard,
        targetCount: 1,
        rewardCoins: 150,
        rewardStars: 3,
        rewardScore: 50,
      ),

      // ── Weekly ────────────────────────────────────────────────────────
      MissionModel.seedTemplate(
        title: 'Clean 20 organic items this week',
        description: 'Banana peels, food scraps – go organic this week.',
        emoji: '🍂',
        type: MissionType.weekly,
        difficulty: MissionDifficulty.medium,
        targetCount: 20,
        rewardCoins: 250,
        rewardStars: 5,
        rewardScore: 80,
        requiredCategory: 'organic',
      ),
      MissionModel.seedTemplate(
        title: 'Claim 3 days in a row',
        description: 'Build your streak by claiming on 3 consecutive days.',
        emoji: '🔥',
        type: MissionType.weekly,
        difficulty: MissionDifficulty.medium,
        targetCount: 3,
        rewardCoins: 200,
        rewardStars: 4,
        rewardScore: 60,
      ),
      MissionModel.seedTemplate(
        title: '10 total claims this week',
        description: 'Make 10 claims over the course of the week.',
        emoji: '🏆',
        type: MissionType.weekly,
        difficulty: MissionDifficulty.hard,
        targetCount: 10,
        rewardCoins: 300,
        rewardStars: 6,
        rewardScore: 100,
      ),

      // ── Special ───────────────────────────────────────────────────────
      MissionModel.seedTemplate(
        title: 'Clean 3 areas near schools',
        description:
            'Help keep school zones clean. Claim within 500m of a school.',
        emoji: '🏫',
        type: MissionType.special,
        difficulty: MissionDifficulty.hard,
        targetCount: 3,
        rewardCoins: 400,
        rewardStars: 8,
        rewardScore: 150,
      ),

      // ── Seasonal ──────────────────────────────────────────────────────
      MissionModel.seedTemplate(
        title: 'Earth Day Marathon',
        description: 'Claim 25 items to celebrate Earth Day!',
        emoji: '🌍',
        type: MissionType.seasonal,
        difficulty: MissionDifficulty.legendary,
        targetCount: 25,
        rewardCoins: 750,
        rewardStars: 15,
        rewardScore: 300,
        eventName: 'Earth Day 2026',
      ),
    ];
  }
}

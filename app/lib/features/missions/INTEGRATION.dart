// ─────────────────────────────────────────────────────────────────────────────
// INTEGRATION.dart – Missions module wiring
// ─────────────────────────────────────────────────────────────────────────────

// ── 1. Router – replace Missions placeholder in ShellRoute ───────────────────
//
//   import 'package:trashgo/features/missions/missions.dart';
//
//   GoRoute(
//     path: AppConstants.routeMissions,  // '/missions'
//     pageBuilder: (_, state) => CustomTransitionPage(
//       key: state.pageKey,
//       child: const MissionsScreen(),
//       transitionsBuilder: _fadeTransition,
//     ),
//   ),

// ── 2. Wire real userId ───────────────────────────────────────────────────────
//
//   Replace _mockUserId in missions_screen.dart:
//     final user = ref.watch(authStateProvider).valueOrNull;
//     final userId = user?.uid ?? '';

// ── 3. Auto-update mission progress after a claim ────────────────────────────
//
//   In claiming_datasource.dart, after saveClaim() succeeds, call a
//   Cloud Function (or do it client-side) to increment mission progress:
//
//   // Cloud Function trigger on claims/{claimId} create:
//   async function updateMissionProgress(claim) {
//     const userId = claim.userId;
//     const category = claim.categoryKey;
//
//     // Fetch active missions for user
//     const missions = await db.collection('missions')
//       .where('expiresAt', '>', now).get();
//
//     for (const mission of missions.docs) {
//       const m = mission.data();
//       const needsCategory = m.requiredCategory;
//
//       // Check if this claim counts toward the mission
//       if (!needsCategory || needsCategory === category) {
//         await db.collection('users').doc(userId)
//           .collection('mission_progress').doc(mission.id)
//           .set({
//             current: FieldValue.increment(1),
//             updatedAt: now,
//           }, { merge: true });
//       }
//     }
//   }
//
//   This approach keeps mission progress consistent server-side.
//   Alternatively, do it client-side in ClaimingDataSource after saveClaim().

// ── 4. Firestore structure ────────────────────────────────────────────────────
//
//   /missions/{missionId}               ← global mission templates
//     title, description, emoji, type,
//     difficulty, targetCount,
//     rewardCoins, rewardStars, rewardScore,
//     requiredCategory?, expiresAt, createdAt
//
//   /users/{uid}/mission_progress/{missionId}   ← per-user progress
//     current: int
//     completedAt?: Timestamp
//     claimedAt?: Timestamp
//
//   Required Firestore index:
//   Collection: missions
//   Fields: expiresAt (ASC)

// ── 5. Scheduled Cloud Function to seed fresh missions daily ─────────────────
//
//   exports.seedDailyMissions = functions.pubsub
//     .schedule('0 0 * * *')  // every midnight
//     .onRun(async () => {
//       const endOfDay = new Date();
//       endOfDay.setHours(23, 59, 59);
//
//       const missions = [
//         { title: 'Claim 5 plastic items', emoji: '♻️',
//           type: 'daily', targetCount: 5, rewardCoins: 100, ... },
//         ...
//       ];
//
//       const batch = db.batch();
//       for (const m of missions) {
//         const ref = db.collection('missions').doc();
//         batch.set(ref, { ...m, expiresAt: endOfDay });
//       }
//       await batch.commit();
//     });
//
//   Until the Cloud Function is deployed, the client-side
//   seedMissionsIfEmpty() in MissionsDataSource handles first-run seeding.

// ── 6. Mission progress update from claiming (client-side option) ─────────────
//
//   Add this to ClaimingDataSource.saveClaim(), after batch.commit():
//
//   // Increment progress for matching missions
//   final missionSnap = await _firestore
//     .collection('missions')
//     .where('expiresAt', isGreaterThan: Timestamp.now())
//     .get();
//
//   final progressBatch = _firestore.batch();
//   for (final doc in missionSnap.docs) {
//     final requiredCat = doc.data()['requiredCategory'] as String?;
//     if (requiredCat == null || requiredCat == claim.category.modelKey) {
//       final ref = _firestore
//         .collection('users').doc(claim.userId)
//         .collection('mission_progress').doc(doc.id);
//       progressBatch.set(ref,
//         {'current': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()},
//         SetOptions(merge: true));
//     }
//   }
//   await progressBatch.commit();

// ─────────────────────────────────────────────────────────────────────────────
// INTEGRATION.dart – Home Module wiring instructions
// ─────────────────────────────────────────────────────────────────────────────

// ── 1. Replace the placeholder HomeScreen in router.dart ─────────────────────
//
// In lib/core/router.dart, remove the placeholder HomeScreen widget and import:
//
//   import 'package:trashgo/features/home/home.dart';
//   import 'package:trashgo/shared/widgets/app_shell.dart';
//
// Wrap the Home route in AppShell:
//
//   ShellRoute(
//     builder: (context, state, child) => AppShell(child: child),
//     routes: [
//       GoRoute(
//         path: AppConstants.routeHome,
//         pageBuilder: (_, state) => CustomTransitionPage(
//           key: state.pageKey,
//           child: const HomeScreen(),
//           transitionsBuilder: _fadeTransition,
//         ),
//       ),
//       GoRoute(
//         path: AppConstants.routeMap,
//         builder: (_, __) => const Scaffold(body: Center(child: Text('Map – coming soon'))),
//       ),
//       GoRoute(
//         path: AppConstants.routeMissions,
//         builder: (_, __) => const Scaffold(body: Center(child: Text('Missions – coming soon'))),
//       ),
//       GoRoute(
//         path: AppConstants.routeSocial,
//         builder: (_, __) => const Scaffold(body: Center(child: Text('Social – coming soon'))),
//       ),
//       GoRoute(
//         path: AppConstants.routeProfile,
//         builder: (_, __) => const Scaffold(body: Center(child: Text('Profile – coming soon'))),
//       ),
//     ],
//   ),
//
// Keep the camera/result routes OUTSIDE the ShellRoute so they cover the bottom nav:
//
//   GoRoute(path: AppConstants.routeCamera, ...),
//   GoRoute(path: AppConstants.routeResult, ...),

// ── 2. Wire real userId from auth ────────────────────────────────────────────
//
// In home_screen.dart and app_shell.dart, replace the static mock userId:
//
//   static const _mockUserId = 'current_user_id';
//
// with the real auth user:
//
//   final user = ref.watch(authStateProvider).valueOrNull;
//   final userId = user?.uid ?? '';
//
// Requires:
//   import 'package:trashgo/features/auth/data/providers/auth_providers.dart';

// ── 3. Level-up system in Firestore ──────────────────────────────────────────
//
// Add this Cloud Function (or do it in claiming_datasource.dart after saveClaim):
//
//   // After updating stars, check if level should increase:
//   final newStars = oldStars + starsAwarded;
//   final newLevel = (newStars / 50).floor() + 1;
//   if (newLevel > oldLevel) {
//     batch.update(userRef, {'level': newLevel});
//     // Also send FCM notification: "You reached Level $newLevel! 🎉"
//   }

// ── 4. Seed daily missions in Firestore ──────────────────────────────────────
//
// Create a Cloud Function (scheduled, runs at midnight) that writes to
// the `missions` collection:
//
//   {
//     "type": "daily",
//     "title": "Claim 5 plastic items",
//     "emoji": "♻️",
//     "targetCount": 5,
//     "rewardCoins": 100,
//     "expiresAt": <end of day timestamp>
//   }
//
// Or seed manually in the Firebase Console for testing.
// The home datasource falls back to hardcoded placeholder missions if empty.

// ── 5. Seed rewards in Firestore ─────────────────────────────────────────────
//
// Populate the `rewards` collection with documents matching this shape:
//
//   {
//     "title": "2 Hours Free Internet",
//     "description": "Djezzy / Mobilis / Ooredoo",
//     "emoji": "📶",
//     "coinCost": 150,
//     "partnerName": "Djezzy",
//     "isAvailable": true,
//     "category": "internet"   // internet | food | entertainment | books | other
//   }
//
// The datasource falls back to 5 hardcoded rewards if the collection is empty.

// ── 6. pubspec.yaml additions (if not already added) ─────────────────────────
//
//   cached_network_image: ^3.3.1   # for avatar network images
//
// The home module uses Image.network directly with an error builder.
// Swap to CachedNetworkImage for better performance/caching in production.

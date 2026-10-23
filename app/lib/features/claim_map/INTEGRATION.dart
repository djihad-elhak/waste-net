// ─────────────────────────────────────────────────────────────────────────────
// INTEGRATION.dart – Claim Map module wiring
// ─────────────────────────────────────────────────────────────────────────────

// ── 1. Router – replace Map placeholder in AppShell ShellRoute ───────────────
//
//   import 'package:trashgo/features/claim_map/claim_map.dart';
//
//   GoRoute(
//     path: AppConstants.routeMap,  // '/map'
//     pageBuilder: (_, state) => CustomTransitionPage(
//       key: state.pageKey,
//       child: const ClaimMapScreen(),
//       transitionsBuilder: _fadeTransition,
//     ),
//   ),

// ── 2. Wire real userId ───────────────────────────────────────────────────────
//
//   In claim_map_screen.dart replace:
//     static const _mockUserId = 'current_user_id';
//   with:
//     final user = ref.watch(authStateProvider).valueOrNull;
//     final userId = user?.uid ?? '';

// ── 3. Firestore indexes needed ───────────────────────────────────────────────
//
//   Add these composite indexes in Firebase Console
//   (or deploy firestore.indexes.json):
//
//   Collection: claims
//   Index 1: userId (ASC) + createdAt (DESC)
//   Index 2: latitude (ASC) + createdAt (DESC)
//   Index 3: userId (ASC) + latitude (ASC)
//
//   Without these indexes, Firestore queries will return an error with
//   a direct link to auto-create the index — just click that link.

// ── 4. Google Maps API key ────────────────────────────────────────────────────
//
//   Already added in AndroidManifest.xml (from auth module setup).
//   For iOS: add to ios/Runner/AppDelegate.swift:
//
//     import GoogleMaps
//     GMSServices.provideAPIKey("YOUR_MAPS_API_KEY")

// ── 5. Dark map style ─────────────────────────────────────────────────────────
//
//   The dark map style JSON is embedded directly in claim_map_screen.dart.
//   It matches the TrashGo eco-dark theme (deep greens, dark roads).
//   Applied via: ctrl.setMapStyle(_darkMapStyle)

// ── 6. Heat zone approach ─────────────────────────────────────────────────────
//
//   Current implementation:
//   - On camera idle, queries Firestore claims in visible bounding box
//   - Client-side clusters into ~300m grid cells (0.003° ≈ 300m)
//   - Renders as Google Maps Circles with orange fill, opacity = intensity
//
//   For scale (10k+ claims), replace with a Cloud Function that pre-aggregates
//   heat tiles server-side and caches them. Query those aggregates instead.

// ── 7. GeoFlutterFire (optional, for geo queries) ────────────────────────────
//
//   For production geo querying at scale, consider:
//     geoflutterfire_plus: ^0.0.17
//
//   This encodes GeoPoints as geohashes, enabling efficient radius queries:
//     geo.collection(collectionRef: ref).within(
//       center: GeoFirePoint(lat, lng),
//       radius: 5, // km
//       field: 'location',
//     )
//
//   Update ClaimingDataSource to store a 'g' field (geohash) alongside 'location'.

// ── 8. pubspec.yaml additions ─────────────────────────────────────────────────
//
//   intl: ^0.19.0     # Already in pubspec — used for DateFormat in PinDetailSheet

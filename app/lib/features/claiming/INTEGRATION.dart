// ─────────────────────────────────────────────────────────────────────────────
// ADD THESE ROUTES to your existing router.dart GoRouter routes list
// ─────────────────────────────────────────────────────────────────────────────
//
// import 'package:trashgo/features/claiming/presentation/screens/camera_screen.dart';
// import 'package:trashgo/features/claiming/presentation/screens/result_screen.dart';
//
// Inside routes: [
//
//   GoRoute(
//     path: AppConstants.routeCamera,   // '/claim/camera'
//     pageBuilder: (_, state) => CustomTransitionPage(
//       key: state.pageKey,
//       child: const CameraScreen(),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return FadeTransition(opacity: animation, child: child);
//       },
//     ),
//   ),
//
//   GoRoute(
//     path: AppConstants.routeResult,   // '/claim/result'
//     pageBuilder: (_, state) => CustomTransitionPage(
//       key: state.pageKey,
//       child: const ResultScreen(),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(0, 1.0),
//             end: Offset.zero,
//           ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
//           child: child,
//         );
//       },
//     ),
//   ),
//
// ]
//
// ─────────────────────────────────────────────────────────────────────────────
// HOW TO TRIGGER THE CLAIM FLOW from Home Dashboard
// ─────────────────────────────────────────────────────────────────────────────
//
// Big CLAIM button on home screen:
//
//   onPressed: () {
//     // Initialize camera in background before navigating
//     ref.read(cameraNotifierProvider.notifier).initCamera();
//     context.push(AppConstants.routeCamera);
//   }
//
// ─────────────────────────────────────────────────────────────────────────────
// HOW TO WIRE userId FROM AUTH
// ─────────────────────────────────────────────────────────────────────────────
//
// In claiming_controller.dart, replace the hardcoded userId:
//
//   // Add to ClaimingNotifier:
//   Future<void> classifyAndClaim({required String imagePath}) async {
//     final authUser = ref.read(authStateProvider).valueOrNull;
//     if (authUser == null) return;
//
//     await _classifyInternal(
//       imagePath: imagePath,
//       userId: authUser.uid,
//       isFirstClaimToday: await _checkFirstClaimToday(authUser.uid),
//       currentStreak: authUser.streak,  // from user model
//     );
//   }
//
// ─────────────────────────────────────────────────────────────────────────────
// ONNX MODEL LABEL ORDER
// ─────────────────────────────────────────────────────────────────────────────
//
// Open trash_label_map.dart and update classIndex to match your model exactly.
// If your model was trained with a different class order, just reorder the list
// or update the classIndex values. The modelKey field should match your
// training label names exactly.
//
// To verify: after running inference, log the raw argmax index and compare
// to what the model should predict for a known test image.
//

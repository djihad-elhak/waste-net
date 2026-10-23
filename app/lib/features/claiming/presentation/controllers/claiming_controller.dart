import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trash/features/claiming/data/providers/claiming_providers.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';
import 'package:trash/features/claiming/domain/usecases/classify_trash_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Camera State
// ─────────────────────────────────────────────────────────────────────────────

enum CameraPhase { initializing, ready, capturing, processing, done, error }

class CameraState {
  final CameraPhase phase;
  final CameraController? controller;
  final double? liveConfidence;   // Real-time confidence from live stream
  final String? errorMessage;
  final List<CameraDescription> cameras;

  const CameraState({
    this.phase = CameraPhase.initializing,
    this.controller,
    this.liveConfidence,
    this.errorMessage,
    this.cameras = const [],
  });

  bool get isReady => phase == CameraPhase.ready;
  bool get isProcessing => phase == CameraPhase.processing;

  CameraState copyWith({
    CameraPhase? phase,
    CameraController? controller,
    double? liveConfidence,
    String? errorMessage,
    List<CameraDescription>? cameras,
  }) {
    return CameraState(
      phase: phase ?? this.phase,
      controller: controller ?? this.controller,
      liveConfidence: liveConfidence ?? this.liveConfidence,
      errorMessage: errorMessage ?? this.errorMessage,
      cameras: cameras ?? this.cameras,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Claiming Flow State
// ─────────────────────────────────────────────────────────────────────────────

enum ClaimingPhase { idle, classifying, success, failure, saving }

class ClaimingState {
  final ClaimingPhase phase;
  final ClassifyResult? classifyResult;
  final TrashClaim? savedClaim;
  final String? errorMessage;
  final ClassifyFailureReason? failureReason;
  final bool isSaving;

  const ClaimingState({
    this.phase = ClaimingPhase.idle,
    this.classifyResult,
    this.savedClaim,
    this.errorMessage,
    this.failureReason,
    this.isSaving = false,
  });

  bool get isSuccess => phase == ClaimingPhase.success;
  bool get isFailure => phase == ClaimingPhase.failure;

  ClaimingState copyWith({
    ClaimingPhase? phase,
    ClassifyResult? classifyResult,
    TrashClaim? savedClaim,
    String? errorMessage,
    ClassifyFailureReason? failureReason,
    bool? isSaving,
  }) {
    return ClaimingState(
      phase: phase ?? this.phase,
      classifyResult: classifyResult ?? this.classifyResult,
      savedClaim: savedClaim ?? this.savedClaim,
      errorMessage: errorMessage ?? this.errorMessage,
      failureReason: failureReason ?? this.failureReason,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera Controller Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CameraNotifier extends Notifier<CameraState> {
  @override
  CameraState build() => const CameraState();

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          phase: CameraPhase.error,
          errorMessage: 'No camera found on this device.',
        );
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      // Tune for fast, stable captures
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFlashMode(FlashMode.off);

      state = state.copyWith(
        phase: CameraPhase.ready,
        controller: controller,
        cameras: cameras,
      );
    } catch (e) {
      state = state.copyWith(
        phase: CameraPhase.error,
        errorMessage: 'Camera initialization failed: ${e.toString()}',
      );
    }
  }

  Future<String?> capturePhoto() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return null;

    try {
      state = state.copyWith(phase: CameraPhase.capturing);
      final xFile = await controller.takePicture();
      state = state.copyWith(phase: CameraPhase.processing);
      return xFile.path;
    } catch (e) {
      state = state.copyWith(
        phase: CameraPhase.ready,
        errorMessage: 'Failed to capture photo.',
      );
      return null;
    }
  }

  void updateLiveConfidence(double confidence) {
    if (state.phase == CameraPhase.ready) {
      state = state.copyWith(liveConfidence: confidence);
    }
  }

  void resetToReady() {
    state = state.copyWith(phase: CameraPhase.ready, liveConfidence: null);
  }

  @override
  void disposeCamera() {
    state.controller?.dispose();
  }
}

final cameraNotifierProvider =
    NotifierProvider<CameraNotifier, CameraState>(CameraNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Claiming Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ClaimingNotifier extends Notifier<ClaimingState> {
  @override
  ClaimingState build() => const ClaimingState();

  Future<void> classifyAndClaim({
    required String imagePath,
    required String userId,
    required bool isFirstClaimToday,
    required int currentStreak,
  }) async {
    state = state.copyWith(phase: ClaimingPhase.classifying);

    // Get current location
    double? lat;
    double? lng;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      // Location optional — claim still works without it
    }

    final useCase = ref.read(classifyTrashUseCaseProvider);
    final result = await useCase(
      imagePath: imagePath,
      userId: userId,
      latitude: lat,
      longitude: lng,
      isFirstClaimToday: isFirstClaimToday,
      currentStreak: currentStreak,
    );

    if (!result.isSuccess) {
      state = state.copyWith(
        phase: ClaimingPhase.failure,
        failureReason: result.failureReason,
        errorMessage: result.message,
      );
      return;
    }

    state = state.copyWith(
      phase: ClaimingPhase.success,
      classifyResult: result,
    );

    // Auto-save in background
    _saveClaimInBackground(result.claim!);
  }

  Future<void> _saveClaimInBackground(TrashClaim claim) async {
    state = state.copyWith(isSaving: true);
    final useCase = ref.read(saveClaimUseCaseProvider);
    final result = await useCase(claim);
    state = state.copyWith(
      isSaving: false,
      savedClaim: result.claim,
    );
  }

  void reset() {
    state = const ClaimingState();
  }
}

final claimingNotifierProvider =
    NotifierProvider<ClaimingNotifier, ClaimingState>(ClaimingNotifier.new);

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:trash/features/claiming/data/datasources/onnx_inference_service.dart';
import 'package:trash/features/claiming/data/datasources/trash_label_map.dart';
import 'package:trash/features/claiming/domain/entities/trash_claim.dart';
import 'package:trash/features/claiming/domain/repositories/claiming_repository.dart';

class ClassifyTrashUseCase {
  final OnnxInferenceService _inferenceService;
  final ClaimingRepository _repo;

  const ClassifyTrashUseCase(this._inferenceService, this._repo);

  /// Run full classify → validate → rewards pipeline
  Future<ClassifyResult> call({
    required String imagePath,
    required String userId,
    required double? latitude,
    required double? longitude,
    required bool isFirstClaimToday,
    required int currentStreak,
  }) async {
    // 1. Run ONNX inference
    final inferResult = await _inferenceService.classifyImage(imagePath);

    if (inferResult.failure != null) {
      return ClassifyResult.failure(
        reason: ClassifyFailureReason.modelError,
        message: inferResult.failure!.message,
      );
    }

    final result = inferResult.result!;

    // 2. Confidence gate
    if (!result.isTrash) {
      return ClassifyResult.failure(
        reason: ClassifyFailureReason.notTrash,
        confidence: result.confidence,
        message: "That doesn't look like trash. Try again with better lighting!",
      );
    }

    // 3. Anti-cheat: duplicate image hash check
    final imageHash = await _computeImageHash(imagePath);
    final dupCheck = await _repo.checkDuplicateImage(imageHash);
    if (dupCheck.isDuplicate) {
      return ClassifyResult.failure(
        reason: ClassifyFailureReason.duplicate,
        message: "This photo was already claimed. Find new litter!",
      );
    }

    // 4. Anti-cheat: location distance check (>50m from last claim)
    if (latitude != null && longitude != null) {
      final locCheck = await _repo.checkLocationValid(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
      );
      if (!locCheck.isValid) {
        return ClassifyResult.failure(
          reason: ClassifyFailureReason.tooClose,
          message: "Move at least 50 metres from your last claim spot!",
        );
      }
    }

    // 5. Calculate rewards
    final multiplier = TrashLabelMap.bonusMultiplier(
      isFirstClaimToday: isFirstClaimToday,
      currentStreak: currentStreak,
    );

    final category = result.category;
    final rewards = ClaimRewards(
      coins: (category.baseCoins * multiplier).round(),
      score: (category.baseScore * multiplier).round(),
      stars: category.baseStars,
      bonusMultiplier: multiplier,
      isFirstClaimToday: isFirstClaimToday,
      streakBonus: currentStreak >= 3,
    );

    // 6. Build claim object
    final claim = TrashClaim(
      userId: userId,
      category: category,
      confidence: result.confidence,
      coinsAwarded: rewards.coins,
      scoreAwarded: rewards.score,
      starsAwarded: rewards.stars,
      latitude: latitude,
      longitude: longitude,
      localPhotoPath: imagePath,
      imageHash: imageHash,
      isSynced: false,
      createdAt: DateTime.now(),
    );

    return ClassifyResult.success(
      claim: claim,
      rewards: rewards,
      allScores: result.allScores,
    );
  }

  Future<String> _computeImageHash(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

enum ClassifyFailureReason {
  notTrash,
  duplicate,
  tooClose,
  modelError,
}

class ClassifyResult {
  final bool isSuccess;
  final TrashClaim? claim;
  final ClaimRewards? rewards;
  final List<double>? allScores;
  final ClassifyFailureReason? failureReason;
  final String? message;
  final double? confidence;

  const ClassifyResult._({
    required this.isSuccess,
    this.claim,
    this.rewards,
    this.allScores,
    this.failureReason,
    this.message,
    this.confidence,
  });

  factory ClassifyResult.success({
    required TrashClaim claim,
    required ClaimRewards rewards,
    required List<double> allScores,
  }) {
    return ClassifyResult._(
      isSuccess: true,
      claim: claim,
      rewards: rewards,
      allScores: allScores,
    );
  }

  factory ClassifyResult.failure({
    required ClassifyFailureReason reason,
    String? message,
    double? confidence,
  }) {
    return ClassifyResult._(
      isSuccess: false,
      failureReason: reason,
      message: message,
      confidence: confidence,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save Claim Use Case
// ─────────────────────────────────────────────────────────────────────────────

class SaveClaimUseCase {
  final ClaimingRepository _repo;
  const SaveClaimUseCase(this._repo);

  Future<({TrashClaim? claim, String? error})> call(TrashClaim claim) async {
    // Upload photo first
    if (claim.localPhotoPath != null && claim.id == null) {
      // Will be handled after we get the Firestore ID
    }

    final result = await _repo.saveClaim(claim);
    if (result.failure != null) {
      return (claim: null, error: result.failure!.message);
    }

    return (claim: result.claim, error: null);
  }
}

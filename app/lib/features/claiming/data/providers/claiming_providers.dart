import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trash/features/claiming/data/datasources/claiming_datasource.dart';
import 'package:trash/features/claiming/data/datasources/onnx_inference_service.dart';
import 'package:trash/features/claiming/data/repositories/claiming_repository_impl.dart';
import 'package:trash/features/claiming/domain/repositories/claiming_repository.dart';
import 'package:trash/features/claiming/domain/usecases/classify_trash_use_case.dart';

final onnxInferenceServiceProvider = Provider<OnnxInferenceService>((ref) {
  final service = OnnxInferenceService();
  ref.onDispose(service.dispose);
  return service;
});

final claimingDataSourceProvider = Provider<ClaimingDataSource>((ref) {
  return ClaimingDataSource();
});

final claimingRepositoryProvider = Provider<ClaimingRepository>((ref) {
  return ClaimingRepositoryImpl(ref.read(claimingDataSourceProvider));
});

final classifyTrashUseCaseProvider = Provider<ClassifyTrashUseCase>((ref) {
  return ClassifyTrashUseCase(
    ref.read(onnxInferenceServiceProvider),
    ref.read(claimingRepositoryProvider),
  );
});

final saveClaimUseCaseProvider = Provider<SaveClaimUseCase>((ref) {
  return SaveClaimUseCase(ref.read(claimingRepositoryProvider));
});

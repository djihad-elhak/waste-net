import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';
import 'package:path_provider/path_provider.dart';

import 'trash_label_map.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

class InferenceResult {
  final TrashCategory category;
  final double confidence;
  final List<double> allScores; // softmax scores for all classes

  const InferenceResult({
    required this.category,
    required this.confidence,
    required this.allScores,
  });

  bool get isTrash => confidence >= TrashLabelMap.confidenceThreshold;
}

class InferenceFailure {
  final String message;
  const InferenceFailure(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────
// ONNX Inference Service
// ─────────────────────────────────────────────────────────────────────────────

class OnnxInferenceService {
  static const String _modelAssetPath = 'assets/models/densenet_waste.onnx';

  // DenseNet ImageNet normalization constants
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];
  static const int _inputSize = 224;

  OrtSession? _session;
  bool _isInitialized = false;

  // ── Singleton ─────────────────────────────────────────────────────────────
  static final OnnxInferenceService _instance = OnnxInferenceService._internal();
  factory OnnxInferenceService() => _instance;
  OnnxInferenceService._internal();

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Copy model from assets to temp dir (ONNX Runtime needs a file path)
    final modelBytes = await rootBundle.load(_modelAssetPath);
    final tempDir = await getTemporaryDirectory();
    final modelFile = File('${tempDir.path}/densenet_waste.onnx');

    if (!await modelFile.exists()) {
      await modelFile.writeAsBytes(modelBytes.buffer.asUint8List());
    }

    // Create ONNX session with GPU acceleration if available
    final sessionOptions = OrtSessionOptions()
      ..setInterOpNumThreads(2)
      ..setIntraOpNumThreads(4)
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

    // Try GPU delegate first, fall back to CPU

    _session = OrtSession.fromFile(modelFile, sessionOptions);
    _isInitialized = true;
  }

  // ── Run inference on a file path ──────────────────────────────────────────
  Future<({InferenceResult? result, InferenceFailure? failure})> classifyImage(
      String imagePath) async {
    try {
      if (!_isInitialized) await initialize();

      final file = File(imagePath);
      if (!await file.exists()) {
        return (result: null, failure: const InferenceFailure('Image file not found.'));
      }

      final imageBytes = await file.readAsBytes();
      final tensor = _preprocessImage(imageBytes);

      return _runInference(tensor);
    } catch (e) {
      return (
        result: null,
        failure: InferenceFailure('Inference failed: ${e.toString()}'),
      );
    }
  }

  // ── Run inference on a CameraImage (live stream) ─────────────────────────
  Future<({InferenceResult? result, InferenceFailure? failure})>
      classifyCameraImage(CameraImage cameraImage) async {
    try {
      if (!_isInitialized) await initialize();
      final tensor = _preprocessCameraImage(cameraImage);
      return _runInference(tensor);
    } catch (e) {
      return (
        result: null,
        failure: InferenceFailure('Live inference failed: ${e.toString()}'),
      );
    }
  }

  // ── Core inference ────────────────────────────────────────────────────────
  Future<({InferenceResult? result, InferenceFailure? failure})> _runInference(
      Float32List inputTensor) async {
    final session = _session;
    if (session == null) {
      return (result: null, failure: const InferenceFailure('Model not loaded.'));
    }

    // Build input: shape [1, 3, 224, 224] (NCHW format for DenseNet)
    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputTensor,
      [1, 3, _inputSize, _inputSize],
    );

    final inputs = {'input': inputOrt};
    final outputs = await session.runAsync(OrtRunOptions(), inputs);

    inputOrt.release();

    if (outputs == null || outputs.isEmpty) {
      return (result: null, failure: const InferenceFailure('Model returned no output.'));
    }

    // Extract logits
    final rawLogits = (outputs.first?.value as List<dynamic>)
        .cast<List<dynamic>>()
        .first
        .cast<double>();

    for (final out in outputs) {
      out?.release();
    }

    final scores = _softmax(rawLogits);
    final maxIndex = _argmax(scores);
    final confidence = scores[maxIndex];

    final category = TrashLabelMap.byIndex(maxIndex);
    if (category == null) {
      return (
        result: null,
        failure: const InferenceFailure('Unknown class index from model.'),
      );
    }

    return (
      result: InferenceResult(
        category: category,
        confidence: confidence,
        allScores: scores,
      ),
      failure: null,
    );
  }

  // ── Image preprocessing (file bytes → Float32List NCHW) ──────────────────
  Float32List _preprocessImage(Uint8List imageBytes) {
    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Could not decode image');

    // Resize to 224×224
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    return _imageToTensor(resized);
  }

  // ── CameraImage → Float32List (YUV420 → RGB → tensor) ───────────────────
  Float32List _preprocessCameraImage(CameraImage cameraImage) {
    final img.Image rgbImage;

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      rgbImage = _yuv420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      rgbImage = _bgra8888ToImage(cameraImage);
    } else {
      throw Exception('Unsupported camera format: ${cameraImage.format.group}');
    }

    final resized = img.copyResize(
      rgbImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    return _imageToTensor(resized);
  }

  Float32List _imageToTensor(img.Image image) {
    // NCHW format: [1, 3, H, W]
    final tensor = Float32List(3 * _inputSize * _inputSize);
    int pixelCount = _inputSize * _inputSize;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        final i = y * _inputSize + x;
        tensor[i] = (r - _mean[0]) / _std[0];              // R channel
        tensor[pixelCount + i] = (g - _mean[1]) / _std[1]; // G channel
        tensor[2 * pixelCount + i] = (b - _mean[2]) / _std[2]; // B channel
      }
    }

    return tensor;
  }

  // ── YUV420 → RGB ──────────────────────────────────────────────────────────
  img.Image _yuv420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * cameraImage.planes[0].bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yVal = yPlane[yIndex];
        final uVal = uPlane[uvIndex] - 128;
        final vVal = vPlane[uvIndex] - 128;

        final r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
        final g = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toInt();
        final b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  // ── BGRA8888 → RGB ────────────────────────────────────────────────────────
  img.Image _bgra8888ToImage(CameraImage cameraImage) {
    final bytes = cameraImage.planes[0].bytes;
    final width = cameraImage.width;
    final height = cameraImage.height;
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        image.setPixelRgb(x, y, bytes[i + 2], bytes[i + 1], bytes[i]);
      }
    }

    return image;
  }

  // ── Math helpers ──────────────────────────────────────────────────────────
  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  int _argmax(List<double> values) {
    int maxIdx = 0;
    double maxVal = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
  }
}

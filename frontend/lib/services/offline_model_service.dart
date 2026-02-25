import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device plant disease inference using TFLite.
///
/// Mirrors the backend's prediction logic including US13
/// confidence / entropy / margin uncertainty checks.
class OfflineModelService {
  OfflineModelService._();

  static final OfflineModelService instance = OfflineModelService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _ready = false;

  bool get isReady => _ready;

  // Same thresholds as backend config
  static const double confidenceThreshold = 0.85;
  static const double entropyThreshold = 2.0;
  static const double marginThreshold = 0.10;
  static const int inputSize = 224;

  /// Copy an asset file to the app's local directory so TFLite can read it.
  Future<File> _copyAssetToLocal(String assetPath, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    return file;
  }

  /// Load model and labels from assets. Safe to call multiple times.
  Future<void> init() async {
    if (_ready) return;

    // Copy model from Flutter assets to local filesystem, then load
    final modelFile = await _copyAssetToLocal(
      'assets/model/crop_disease_model.tflite',
      'crop_disease_model.tflite',
    );
    _interpreter = Interpreter.fromFile(modelFile);

    final raw = await rootBundle.loadString('assets/model/label_map.txt');
    _labels = [];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Format: "0:Apple___Apple_scab"
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex != -1) {
        _labels.add(trimmed.substring(colonIndex + 1));
      } else {
        _labels.add(trimmed);
      }
    }

    _ready = true;
  }

  /// Run prediction on a local image file.
  /// Returns a result map matching the shape of the online API response.
  Future<Map<String, dynamic>> predict(File imageFile, String cropType) async {
    if (!_ready || _interpreter == null) {
      await init();
    }

    // Read and preprocess image
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image.');
    }

    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
    );

    // Build input tensor [1, 224, 224, 3] normalized to [0, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    // Allocate output
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    final predictions = output[0];

    // Top prediction
    int topIdx = 0;
    double topConf = predictions[0];
    for (int i = 1; i < predictions.length; i++) {
      if (predictions[i] > topConf) {
        topConf = predictions[i];
        topIdx = i;
      }
    }

    final diseaseId = topIdx < _labels.length ? _labels[topIdx] : 'Unknown';

    // Entropy
    double entropy = 0.0;
    for (final p in predictions) {
      final clipped = p.clamp(1e-10, 1.0);
      entropy -= clipped * log(clipped);
    }

    // Margin (top1 - top2)
    final sorted = List<double>.from(predictions)
      ..sort((a, b) => b.compareTo(a));
    final margin = sorted.length > 1 ? sorted[0] - sorted[1] : 1.0;

    // Uncertainty decision (mirrors backend)
    final lowConfidence = topConf < confidenceThreshold;
    final highEntropy = entropy > entropyThreshold;
    final lowMargin = margin < marginThreshold;
    final isUncertain = lowConfidence || highEntropy || lowMargin;

    final isHealthy = diseaseId.toLowerCase().contains('healthy');

    String diseaseName;
    if (isUncertain) {
      diseaseName = 'Unknown/Unclear';
    } else {
      diseaseName = _formatDiseaseName(diseaseId);
    }

    // Determine severity from confidence (simple heuristic)
    String severity;
    if (isHealthy || isUncertain) {
      severity = 'unknown';
    } else if (topConf > 0.90) {
      severity = 'high';
    } else if (topConf > 0.70) {
      severity = 'medium';
    } else {
      severity = 'low';
    }

    return {
      'disease_id': diseaseId,
      'disease_name': diseaseName,
      'confidence': topConf,
      'severity': severity,
      'is_healthy': isHealthy,
      'is_uncertain': isUncertain,
      'is_offline': true,
      'crop_type': cropType,
      'image_url': '',
      'heatmap_url': '',
      'bounding_boxes': <dynamic>[],
      'secondary_diagnoses': <dynamic>[],
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  String _formatDiseaseName(String diseaseId) {
    // "Apple___Apple_scab" → "Apple Scab"
    final parts = diseaseId.split('___');
    final name = parts.length > 1 ? parts[1] : parts[0];
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

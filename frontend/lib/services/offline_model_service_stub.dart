import 'dart:io';

/// Stub version of OfflineModelService for platforms where TFLite is not supported (e.g. Web).
class OfflineModelService {
  OfflineModelService._();

  static final OfflineModelService instance = OfflineModelService._();

  bool get isReady => false;

  Future<void> init() async {
    // No-op on web
  }

  Future<Map<String, dynamic>> predict(File imageFile, String cropType) async {
    throw UnsupportedError('Offline TFLite model is not supported on Web.');
  }
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiagnosisCache {
  static const String _storageKey = 'diagnosis_cache';
  final FlutterSecureStorage _storage;

  const DiagnosisCache({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveDiagnosisResult({
    required String diagnosisId,
    required Map<String, dynamic> result,
  }) async {
    final cache = await _readCache();
    cache[diagnosisId] = result;
    // Optional: implement a limit, e.g., keep last 50
    if (cache.length > 50) {
      final keysToRemove = cache.keys.take(cache.length - 50);
      for (final key in keysToRemove) {
        cache.remove(key);
      }
    }
    await _storage.write(key: _storageKey, value: jsonEncode(cache));
  }

  Future<Map<String, dynamic>?> readDiagnosisResult(String diagnosisId) async {
    final cache = await _readCache();
    return cache[diagnosisId];
  }

  Future<Map<String, dynamic>> _readCache() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // If corrupt, return empty
    }
    return <String, dynamic>{};
  }

  Future<void> clearCache() async {
    await _storage.delete(key: _storageKey);
  }
}

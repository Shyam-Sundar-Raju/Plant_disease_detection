import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // Secure storage for tokens plus lightweight caches.
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenTypeKey = 'token_type';
  static const String userProfileKey = 'user_profile';
  static const String historyCacheKey = 'history_cache';
  static const String analyticsCacheKey = 'history_analytics_cache';
  static const String diagnosisCacheKey = 'diagnosis_cache';

  const TokenStorage();

  FlutterSecureStorage get _storage => const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? tokenType,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
    if (tokenType != null) {
      await _storage.write(key: tokenTypeKey, value: tokenType);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: tokenTypeKey);
    await _storage.delete(key: userProfileKey);
    await _storage.delete(key: historyCacheKey);
    await _storage.delete(key: analyticsCacheKey);
    await _storage.delete(key: diagnosisCacheKey);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: refreshTokenKey);
  }

  Future<String?> readTokenType() {
    return _storage.read(key: tokenTypeKey);
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: userProfileKey, value: jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> readUserProfile() async {
    final raw = await _storage.read(key: userProfileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    await _storage.write(key: historyCacheKey, value: jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>?> readHistory() async {
    final raw = await _storage.read(key: historyCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    return null;
  }

  Future<void> saveHistoryAnalytics(Map<String, dynamic> analytics) async {
    await _storage.write(key: analyticsCacheKey, value: jsonEncode(analytics));
  }

  Future<Map<String, dynamic>?> readHistoryAnalytics() async {
    final raw = await _storage.read(key: analyticsCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  // Diagnosis cache moved to DiagnosisCache service.

}

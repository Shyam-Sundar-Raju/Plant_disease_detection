import 'package:flutter/foundation.dart';

class ApiConfig {
  // When running on Web (Docker), we use a relative URL to use the Nginx proxy.
  // This solves CORS and connection issues.
  // For mobile/emulator, we keep the original hardcoded IP.
  static String get baseHost {
    if (kIsWeb) {
      return ''; // Empty host means relative to current domain (localhost)
    }
    return 'http://192.168.1.30:8000';
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1'; // Direct connection to backend
    }
    return '$baseHost/api/v1';
  }

  static const String weatherApiBaseUrl = 'http://api.weatherapi.com/v1';
  static const String weatherApiKey = 'cd3496d48c4442ed860142708260502';
}

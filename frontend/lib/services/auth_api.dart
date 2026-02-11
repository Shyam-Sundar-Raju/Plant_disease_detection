import 'package:dio/dio.dart';

import 'api_config.dart';

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions());

  final Dio _dio;

  static BaseOptions _defaultOptions() {
    // Shared timeouts and headers for auth endpoints.
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String preferredLanguage,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'preferred_language': preferredLanguage,
        // Backend expects location as a string (address text)
        'location': address.isNotEmpty ? address : null,
      },
    );

    return _toJsonMap(response.data);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return _toJsonMap(response.data);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String username,
  }) async {
    final response = await _dio.post(
      '/auth/forgot-password',
      data: {'username': username},
    );

    return _toJsonMap(response.data);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'otp': otp, 'new_password': newPassword},
    );

    return _toJsonMap(response.data);
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    return _toJsonMap(response.data);
  }

  Map<String, dynamic> _toJsonMap(dynamic data) {
    // Enforce a predictable map response shape.
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Unexpected response format.');
  }
}

import 'package:dio/dio.dart';

import 'api_config.dart';

class NotificationApi {
  NotificationApi({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions());

  final Dio _dio;

  static BaseOptions _defaultOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    required String accessToken,
    String? language,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final headers = <String, dynamic>{'Authorization': 'Bearer $accessToken'};
    if (language != null && language.isNotEmpty) {
      headers['Accept-Language'] = language;
    }

    final response = await _dio.get(
      '/notifications/',
      queryParameters: {'limit': limit, 'unread_only': unreadOnly},
      options: Options(headers: headers),
    );

    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception('Unexpected notifications response format.');
  }
}

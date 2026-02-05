import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'api_config.dart';

class HistoryApi {
  HistoryApi({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions());

  final Dio _dio;

  static BaseOptions _defaultOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    );
  }

  Future<List<Map<String, dynamic>>> getHistory({
    required String accessToken,
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/history/',
      queryParameters: {'skip': skip, 'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception('Unexpected history response format.');
  }

  Future<Map<String, dynamic>> getAnalytics({
    required String accessToken,
  }) async {
    final response = await _dio.get(
      '/history/analytics',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception('Unexpected analytics response format.');
  }

  Future<void> deleteHistory({
    required String accessToken,
    required String historyId,
  }) async {
    await _dio.delete(
      '/history/$historyId',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<String> downloadReport({
    required String accessToken,
    required String diagnosisId,
  }) async {
    final response = await _dio.get<List<int>>(
      '/history/report/$diagnosisId',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
        responseType: ResponseType.bytes,
      ),
    );

    final bytes = response.data;
    if (bytes == null) {
      throw Exception('Failed to download report.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/diagnosis_report_$diagnosisId.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }
}

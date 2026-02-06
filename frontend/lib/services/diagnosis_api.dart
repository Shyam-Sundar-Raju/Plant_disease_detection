import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';

class DiagnosisApi {
  DiagnosisApi({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions());

  final Dio _dio;

  static BaseOptions _defaultOptions() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    );
  }

  Future<Map<String, dynamic>> createDiagnosis({
    required String accessToken,
    required String cropType,
    required File imageFile,
    String? language,
  }) async {
    final formData = FormData.fromMap({
      'crop_type': cropType,
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'capture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final headers = <String, dynamic>{'Authorization': 'Bearer $accessToken'};
    if (language != null && language.isNotEmpty) {
      headers['Accept-Language'] = language;
    }

    final response = await _dio.post(
      '/diagnosis/',
      data: formData,
      options: Options(headers: headers),
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception('Unexpected diagnosis response format.');
  }
}

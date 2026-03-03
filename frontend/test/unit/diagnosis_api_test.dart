import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/diagnosis_api.dart';

class MockDio extends Mock implements Dio {}

class MockFile extends Mock implements File {}

void main() {
  late DiagnosisApi diagnosisApi;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    diagnosisApi = DiagnosisApi(dio: mockDio);

    // Register fallback for FormData if needed, but any() usually works for post data.
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  group('DiagnosisApi', () {
    test('createDiagnosis should return result when successful', () async {
      // Arrange
      final responseData = {'id': 'diag_123', 'disease': 'Healthy'};

      // Create a real temp file for testing
      final tempDir = await Directory.systemTemp.createTemp();
      final testFile = File('${tempDir.path}/test_image.jpg');
      await testFile.writeAsBytes([0, 1, 2, 3]);

      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/diagnosis/'),
        ),
      );

      // Act
      final result = await diagnosisApi.createDiagnosis(
        accessToken: 'test_token',
        cropType: 'Tomato',
        imageFile: testFile,
      );

      // Assert
      expect(result['id'], 'diag_123');
      verify(
        () => mockDio.post(
          '/diagnosis/',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);

      // Cleanup
      await tempDir.delete(recursive: true);
    });

    test('getDiagnosis should return result when successful', () async {
      // Arrange
      final responseData = {'id': 'diag_123', 'disease': 'Tomato_Late_blight'};

      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/diagnosis/diag_123'),
        ),
      );

      // Act
      final result = await diagnosisApi.getDiagnosis(
        accessToken: 'test_token',
        diagnosisId: 'diag_123',
      );

      // Assert
      expect(result['id'], 'diag_123');
      verify(
        () =>
            mockDio.get('/diagnosis/diag_123', options: any(named: 'options')),
      ).called(1);
    });
  });
}

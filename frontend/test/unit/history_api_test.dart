import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/history_api.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late HistoryApi historyApi;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    historyApi = HistoryApi(dio: mockDio);
  });

  group('HistoryApi', () {
    test('getHistory should return a list of maps when successful', () async {
      // Arrange
      final responseData = {
        'items': [
          {'id': '1', 'crop': 'Tomato'},
          {'id': '2', 'crop': 'Potato'},
        ],
      };

      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/history/'),
        ),
      );

      // Act
      final result = await historyApi.getHistory(accessToken: 'test_token');

      // Assert
      expect(result.length, 2);
      expect(result[0]['crop'], 'Tomato');
      verify(
        () => mockDio.get(
          '/history/',
          queryParameters: {'skip': 0, 'limit': 20},
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('getAnalytics should return a map when successful', () async {
      // Arrange
      final responseData = {'total_diagnoses': 5};

      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/history/analytics'),
        ),
      );

      // Act
      final result = await historyApi.getAnalytics(accessToken: 'test_token');

      // Assert
      expect(result['total_diagnoses'], 5);
      verify(
        () => mockDio.get('/history/analytics', options: any(named: 'options')),
      ).called(1);
    });

    test('deleteHistory should execute successfully when called', () async {
      // Arrange
      when(
        () => mockDio.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/history/1'),
        ),
      );

      // Act & Assert
      await expectLater(
        historyApi.deleteHistory(accessToken: 'test_token', historyId: '1'),
        completes,
      );
      verify(
        () => mockDio.delete('/history/1', options: any(named: 'options')),
      ).called(1);
    });
  });
}

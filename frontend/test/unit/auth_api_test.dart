import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/auth_api.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AuthApi authApi;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    authApi = AuthApi(dio: mockDio);
  });

  group('AuthApi', () {
    test('login should return a map when successful', () async {
      // Arrange
      final responseData = {
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
      };

      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/login'),
        ),
      );

      // Act
      final result = await authApi.login(
        username: 'testuser',
        password: 'password123',
      );

      // Assert
      expect(result['access_token'], 'test_token');
      verify(
        () => mockDio.post(
          '/auth/login',
          data: {'username': 'testuser', 'password': 'password123'},
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('register should return a map when successful', () async {
      // Arrange
      final responseData = {'message': 'User registered successfully'};

      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/auth/register'),
        ),
      );

      // Act
      final result = await authApi.register(
        name: 'Test User',
        email: 'test@example.com',
        phone: '+911234567890',
        password: 'password123',
        preferredLanguage: 'en',
        latitude: 12.34,
        longitude: 56.78,
        address: 'Test Address',
      );

      // Assert
      expect(result['message'], 'User registered successfully');
      verify(
        () => mockDio.post('/auth/register', data: any(named: 'data')),
      ).called(1);
    });

    test('forgotPassword should return a map when successful', () async {
      // Arrange
      final responseData = {'message': 'OTP sent'};

      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
        ),
      );

      // Act
      final result = await authApi.forgotPassword(username: 'test@example.com');

      // Assert
      expect(result['message'], 'OTP sent');
    });

    test('resetPassword should return a map when successful', () async {
      // Arrange
      final responseData = {'message': 'Password reset successful'};

      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/reset-password'),
        ),
      );

      // Act
      final result = await authApi.resetPassword(
        token: 'test_token',
        otp: '123456',
        newPassword: 'new_password123',
      );

      // Assert
      expect(result['message'], 'Password reset successful');
    });

    test('refreshToken should return a map when successful', () async {
      // Arrange
      final responseData = {'access_token': 'new_token'};

      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/refresh'),
        ),
      );

      // Act
      final result = await authApi.refreshToken(
        refreshToken: 'old_refresh_token',
      );

      // Assert
      expect(result['access_token'], 'new_token');
    });
  });
}

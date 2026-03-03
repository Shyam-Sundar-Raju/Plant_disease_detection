import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late TokenStorage tokenStorage;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockSecureStorage);
  });

  group('TokenStorage', () {
    test('saveTokens should write tokens to secure storage', () async {
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await tokenStorage.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
      );

      verify(
        () => mockSecureStorage.write(key: 'access_token', value: 'access'),
      ).called(1);
      verify(
        () => mockSecureStorage.write(key: 'refresh_token', value: 'refresh'),
      ).called(1);
      verify(
        () => mockSecureStorage.write(key: 'token_type', value: 'Bearer'),
      ).called(1);
    });

    test('readAccessToken should read from secure storage', () async {
      when(
        () => mockSecureStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'stored_token');

      final result = await tokenStorage.readAccessToken();

      expect(result, 'stored_token');
    });

    test('clearTokens should delete all keys from secure storage', () async {
      when(
        () => mockSecureStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenStorage.clearTokens();

      verify(() => mockSecureStorage.delete(key: any(named: 'key'))).called(8);
    });

    test('saveUserProfile should encode and save profile', () async {
      final profile = {'id': 1, 'name': 'Test'};
      when(
        () => mockSecureStorage.write(
          key: 'user_profile',
          value: jsonEncode(profile),
        ),
      ).thenAnswer((_) async {});

      await tokenStorage.saveUserProfile(profile);

      verify(
        () => mockSecureStorage.write(
          key: 'user_profile',
          value: jsonEncode(profile),
        ),
      ).called(1);
    });

    test('readUserProfile should decode and return profile', () async {
      final profile = {'id': 1, 'name': 'Test'};
      when(
        () => mockSecureStorage.read(key: 'user_profile'),
      ).thenAnswer((_) async => jsonEncode(profile));

      final result = await tokenStorage.readUserProfile();

      expect(result, profile);
    });
  });
}

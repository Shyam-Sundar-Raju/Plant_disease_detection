import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/services/auth_api.dart';
import 'package:frontend/services/token_storage.dart';
import 'package:frontend/services/app_localizations.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthApi mockAuthApi;
  late MockTokenStorage mockTokenStorage;

  setUp(() {
    mockAuthApi = MockAuthApi();
    mockTokenStorage = MockTokenStorage();
  });

  Widget createTestWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AppLanguage(),
      child: MaterialApp(home: child),
    );
  }

  group('LoginPage Widget Test', () {
    testWidgets('should show validation errors when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          LoginPage(api: mockAuthApi, storage: mockTokenStorage),
        ),
      );

      // Tap login button without entering anything
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Check for validation error text (using English defaults from AppLanguage)
      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('should call login on AuthApi when fields are valid', (
      WidgetTester tester,
    ) async {
      when(
        () => mockAuthApi.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => {
          'access_token': 'fake_token',
          'refresh_token': 'fake_refresh',
        },
      );

      when(
        () => mockTokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          tokenType: any(named: 'tokenType'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(api: mockAuthApi, storage: mockTokenStorage),
        ),
      );

      // Enter valid email and password
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify the API was called
      verify(
        () => mockAuthApi.login(
          username: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });
}

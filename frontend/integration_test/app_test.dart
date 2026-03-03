import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full App Integration Test', () {
    testWidgets('App starts and shows LoginPage', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check if "AgroScan" title is visible on LoginPage
      expect(find.text('AgroScan'), findsOneWidget);
    });
  });
}

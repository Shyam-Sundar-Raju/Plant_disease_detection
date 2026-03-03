// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  print('==== Starting Frontend Tests ====');

  // 1. Run Analysis
  print('\n[1/3] Running flutter analyze...');
  final analyzeResult = await Process.run('flutter', ['analyze', '--no-pub']);
  print(analyzeResult.stdout);
  if (analyzeResult.exitCode != 0) {
    print('Static analysis failed!');
    exit(analyzeResult.exitCode);
  }

  // 2. Run Unit & Widget Tests
  print('[2/3] Running flutter test...');
  final testResult = await Process.run('flutter', ['test', '--no-pub']);
  print(testResult.stdout);
  if (testResult.exitCode != 0) {
    print('Tests failed!');
    exit(testResult.exitCode);
  }

  // 3. Run Build Check (APK)
  print('[3/3] Running flutter build apk --debug...');
  final buildResult = await Process.run('flutter', [
    'build',
    'apk',
    '--debug',
    '--no-pub',
  ]);
  print(buildResult.stdout);
  if (buildResult.exitCode != 0) {
    print('Build check failed!');
    exit(buildResult.exitCode);
  }

  print('\n==== All Frontend Checks Passed! ====');
}

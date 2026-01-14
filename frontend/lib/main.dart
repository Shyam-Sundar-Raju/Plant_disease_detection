import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// We will create this screen in the next step
import 'screens/auth/login.dart';

void main() async {
  // 1. Initialize Hive (Database)
  await Hive.initFlutter();

  // 2. Open the Box (Table) where we store history
  // Note: We haven't registered the Adapter yet (fixing this next),
  // so we won't open the complex box yet to avoid crashes.
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Doctor',
      debugShowCheckedModeBanner: false, // Removes the ugly "Debug" banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // We start at Login for now
      home: const LoginScreen(),
    );
  }
}

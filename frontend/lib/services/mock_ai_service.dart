import 'dart:math';
import '../models/diagnosis_model.dart';

class MockAIService {
  // Hardcoded Logic for Demo
  final List<Map<String, String>> _dummyDatabase = [
    {
      "name": "Tomato Early Blight",
      "remediation":
          "Prune infected leaves. Ensure good air circulation. Apply copper fungicide.",
    },
    {
      "name": "Potato Late Blight",
      "remediation":
          "Destroy infected plants immediately. Avoid overhead irrigation. Use resistant varieties.",
    },
    {
      "name": "Healthy",
      "remediation":
          "Plant looks healthy! Keep maintaining current water and soil conditions.",
    },
  ];

  Future<DiagnosisModel> predict(String imagePath) async {
    // 1. Simulate Network Delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Randomly pick a result
    var result = _dummyDatabase[Random().nextInt(_dummyDatabase.length)];
    double randomConfidence =
        0.80 + (Random().nextDouble() * 0.19); // 80% to 99%

    // 3. Return the Data Object
    return DiagnosisModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      diseaseName: result['name']!,
      confidence: randomConfidence,
      imagePath: imagePath,
      date: DateTime.now(),
      remediationText: result['remediation']!,
      isSynced: false,
    );
  }
}

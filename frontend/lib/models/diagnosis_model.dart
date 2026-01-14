class DiagnosisModel {
  final String id;
  final String diseaseName;
  final double confidence;
  final String imagePath;
  final DateTime date;
  final String remediationText;
  bool isSynced;

  DiagnosisModel({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    required this.date,
    required this.remediationText,
    this.isSynced = false,
  });
}

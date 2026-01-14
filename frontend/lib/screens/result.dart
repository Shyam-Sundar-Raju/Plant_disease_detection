import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/diagnosis_model.dart';

class ResultScreen extends StatefulWidget {
  final DiagnosisModel diagnosis;

  const ResultScreen({super.key, required this.diagnosis});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  void _saveToHistory() async {
    // For the dummy version, we will save simple Maps to avoid TypeAdapter complexity for now
    var box = await Hive.openBox('history_box');
    box.add({
      "name": widget.diagnosis.diseaseName,
      "date": widget.diagnosis.date.toString(),
      "image": widget.diagnosis.imagePath,
      "confidence": widget.diagnosis.confidence,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diagnosis Result"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.file(
              File(widget.diagnosis.imagePath),
              height: 300,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.diagnosis.diseaseName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    "Confidence: ${(widget.diagnosis.confidence * 100).toStringAsFixed(1)}%",
                  ),
                  const Divider(height: 30),
                  const Text(
                    "Remediation:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.diagnosis.remediationText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/mock_ai_service.dart';
import 'result.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Trigger camera immediately when screen opens
    _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        _cropImage(pickedFile.path);
      } else {
        if (mounted) Navigator.pop(context); // Go back if user cancels
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Disease Area',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
      ],
    );

    if (croppedFile != null) {
      // .path works on both, so this line is safe
      _analyzeImage(croppedFile.path);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _analyzeImage(String path) async {
    setState(() => _isLoading = true);

    // Call our Mock AI
    final result = await MockAIService().predict(path);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(diagnosis: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    "Analyzing Plant...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Container(), // Empty container while we wait for camera
      ),
    );
  }
}

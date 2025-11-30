import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  String? _errorMessage; // Error message save karne ke liye

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      // 1. Available Cameras dhoondo
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = "No Camera Found!\n\nPlease check:\n1. Is Webcam connected?\n2. Check Windows Settings > Privacy > Camera";
        });
        return;
      }

      // 2. Pehla camera uthao
      final firstCamera = cameras.first;

      // 3. Controller set karo
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      // 4. Initialize karo
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      // Agar koi technical error aye
      setState(() {
        _errorMessage = "Camera Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || _controller == null) return;

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a Picture')),
      body: _errorMessage != null
      // --- ERROR STATE ---
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
      )
      // --- SUCCESS STATE ---
          : (_isCameraReady && _controller != null)
          ? SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CameraPreview(_controller!),
      )
      // --- LOADING STATE ---
          : const Center(child: CircularProgressIndicator()),

      floatingActionButton: _isCameraReady
          ? FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
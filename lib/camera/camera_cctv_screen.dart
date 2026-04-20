import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CCTVCameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CCTVCameraScreen({super.key, required this.camera});

  @override
  State<CCTVCameraScreen> createState() => _CCTVCameraScreenState();
}

class _CCTVCameraScreenState extends State<CCTVCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live CCTV View')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// lib/camera/camera_management.dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraManagementScreen extends StatefulWidget {
  const CameraManagementScreen({super.key});

  @override
  State<CameraManagementScreen> createState() => _CameraManagementScreenState();
}

class _CameraManagementScreenState extends State<CameraManagementScreen> {
  bool _loading = true;
  String? _error;
  List<CameraDescription> _cams = const [];

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() {
      _loading = true;
      _error = null;
      _cams = const [];
    });

    try {
      final perms = await _requestPermissions();
      if (!perms) {
        throw Exception('Camera permission denied. Please allow camera permission in Settings.');
      }

      final cams = await availableCameras();
      if (!mounted) return;
      setState(() {
        _cams = cams;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    final camera = await Permission.camera.request();
    if (!camera.isGranted) return false;

    // Gallery saving differs by Android version; request what exists.
    await Permission.photos.request();
    await Permission.storage.request();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone camera'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadCameras,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42),
                        const SizedBox(height: 10),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadCameras,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Select a camera',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._cams.asMap().entries.map((e) {
                      final idx = e.key;
                      final cam = e.value;
                      final lens = cam.lensDirection.name;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: Text('Camera ${idx + 1} ($lens)'),
                          subtitle: Text(cam.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CameraCaptureScreen(camera: cam),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    if (_cams.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No cameras found on this device.'),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class CameraCaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraCaptureScreen({super.key, required this.camera});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      _initFuture = controller.initialize();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera init failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final c = _controller;
    final f = _initFuture;
    if (c == null || f == null) return;

    setState(() => _saving = true);

    try {
      await f;

      final directory = await getTemporaryDirectory();
      final localPath = join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      final XFile picture = await c.takePicture();
      final File savedFile = await File(picture.path).copy(localPath);

      // ✅ Save to Gallery
      await ImageGallerySaverPlus.saveFile(savedFile.path);

      // ✅ Upload to Firebase
      final fileName = 'camera_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(savedFile);
      final downloadUrl = await ref.getDownloadURL();
      debugPrint("☁️ Uploaded to: $downloadUrl");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Picture saved and uploaded')),
      );
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _initFuture;
    final c = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Makhi Camera')),
      body: (future == null || c == null)
          ? const Center(child: Text('Camera not ready'))
          : FutureBuilder<void>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      CameraPreview(c),
                      if (_saving) const Center(child: CircularProgressIndicator()),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _takePicture,
        child: const Icon(Icons.camera),
      ),
    );
  }
}

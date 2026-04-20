import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Esp32CamViewer extends StatefulWidget {
  final String url;
  final String cameraId;

  const Esp32CamViewer({
    super.key,
    required this.url,
    required this.cameraId,
  });

  @override
  State<Esp32CamViewer> createState() => _Esp32CamViewerState();
}

class _Esp32CamViewerState extends State<Esp32CamViewer> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    /// ✅ AUTO FIX STREAM URL
    final finalUrl = widget.url.contains('stream')
        ? widget.url
        : '${widget.url}stream';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cameraId),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
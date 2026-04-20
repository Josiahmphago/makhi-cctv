// lib/camera/camera_hub_screen.dart
import 'package:flutter/material.dart';

class CameraHubScreen extends StatelessWidget {
  const CameraHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HubItem>[
      _HubItem(
        icon: Icons.radar,
        title: 'Find Camera IP (Auto Scan)',
        subtitle: 'Detect cameras on your Wi-Fi network and add them',
        route: '/camera/find_ip',
      ),
      _HubItem(
        icon: Icons.video_library,
        title: 'My CCTV Cameras',
        subtitle: 'View saved cameras and open streams',
        route: '/cameras',
      ),
      _HubItem(
        icon: Icons.add_box,
        title: 'Add Camera Manually',
        subtitle: 'Enter IP or Stream URL manually',
        route: '/cameras/add',
      ),
      _HubItem(
        icon: Icons.qr_code,
        title: 'Configure ESP32-CAM Token',
        subtitle: 'Register / configure a camera token',
        route: '/camera/config',
      ),
      _HubItem(
        icon: Icons.photo_camera,
        title: 'Phone Camera',
        subtitle: 'Take a picture & upload (your existing screen)',
        route: '/camera/capture',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Camera / Streaming')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(it.icon)),
              title: Text(it.title),
              subtitle: Text(it.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, it.route),
            ),
          );
        },
      ),
    );
  }
}

class _HubItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  _HubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

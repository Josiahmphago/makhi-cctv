// lib/screens/cameras/cameras_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../camera/esp32_cam_viewer.dart';

class CamerasScreen extends StatelessWidget {
  const CamerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cctvRef =
        FirebaseFirestore.instance.collection('cctv_cameras');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cameras'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDiscoverCard(context),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          const Text(
            'Your cameras',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: cctvRef.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No cameras found yet.\nTap "Add camera" to register one.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? doc.id).toString();
                  final location = (data['location'] ?? '').toString();
                  final type = (data['type'] ?? '').toString();
                  final isActive = (data['isActive'] ?? false) == true;

                  // Handle both "ipAddress" and "ipAdress"
                  final ipRaw = (data['ipAddress'] ?? data['ipAdress'] ?? '').toString().trim();
                  final streamUrlRaw = (data['streamUrl'] ?? '').toString().trim();

                  // Build URL: prefer streamUrl, else IP, else fallback
                  String url;
                  if (streamUrlRaw.isNotEmpty) {
                    url = streamUrlRaw; // e.g. http://192.168.18.25/
                  } else if (ipRaw.isNotEmpty) {
                    url = 'http://$ipRaw/'; // default root
                  } else {
                    url = 'http://192.168.18.25/'; // fallback demo
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(
                        isActive ? Icons.videocam : Icons.videocam_off,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        [
                          if (location.isNotEmpty) location,
                          if (type.isNotEmpty) '($type)',
                        ].join(' '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Esp32CamViewer(
                              url: url,
                              cameraId: doc.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildComingSoonCard(),
        ],
      ),
    );
  }

  // 🔍 Auto-discover card (stub for now)
  Widget _buildDiscoverCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.router, size: 36, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Auto-discover cameras',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Scan your Wi-Fi network for compatible IP/ESP32 cameras on the same network.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Network scan coming soon (Phase 2).'),
                  ),
                );
              },
              child: const Text('Scan'),
            ),
          ],
        ),
      ),
    );
  }

  // ⚡ Quick actions
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle_outline,
            label: 'Add camera',
            onTap: () {
              Navigator.pushNamed(context, '/cameras/add');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.photo_camera,
            label: 'Device camera',
            onTap: () {
              Navigator.pushNamed(context, '/camera/management');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.map,
            label: 'Street / patrol',
            onTap: () {
              Navigator.pushNamed(context, '/patrol/dashboard');
            },
          ),
        ),
      ],
    );
  }

  // 🎯 Coming soon: AI detection, brand support etc.
  Widget _buildComingSoonCard() {
    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Coming soon:\n'
          '• AI motion & object detection (people, cars, animals)\n'
          '• Support for more camera brands (RTSP/ONVIF)\n'
          '• Per-camera alert preferences',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

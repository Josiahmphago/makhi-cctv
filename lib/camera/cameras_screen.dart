import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../camera/esp32_cam_viewer.dart';

class CamerasScreen extends StatelessWidget {
  const CamerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Safer query: don't require 'name' to exist (order by doc id instead)
    final query = FirebaseFirestore.instance
        .collection('cctv_cameras')
        .orderBy(FieldPath.documentId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV Cameras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/cameras/add'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No cameras configured yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data();

              final name = (data['name'] ?? doc.id).toString();
              final area = (data['area'] ?? '').toString();
              final type = (data['type'] ?? '').toString();

              // Read both spellings (legacy + new)
              final ip = ((data['ipAddress'] ?? data['ipAdress'] ?? '') as String).trim();
              final streamUrl = ((data['streamUrl'] ?? '') as String).trim();

              final url = streamUrl.isNotEmpty
                  ? streamUrl
                  : (ip.isNotEmpty ? 'http://$ip/' : '');

              final subtitleParts = <String>[
                if (area.isNotEmpty) 'Area: $area',
                if (type.isNotEmpty) 'Type: $type',
                if (ip.isNotEmpty) 'IP: $ip',
              ];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.videocam),
                  title: Text(name),
                  subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: url.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Esp32CamViewer(
                                url: url,
                                cameraId: name,
                              ),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add camera'),
        onPressed: () => Navigator.pushNamed(context, '/cameras/add'),
      ),
    );
  }
}

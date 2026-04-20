import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PatrolAlarmFeedScreen extends StatelessWidget {
  final String areaId;
  const PatrolAlarmFeedScreen({super.key, this.areaId = 'Default'});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Patrol Alarm Feed'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('central_alarms') // ✅ FIXED
            .where('areaId', isEqualTo: areaId)
            .where('status', whereIn: ['new', 'ack', 'responding'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No active alarms'));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snap.data!.docs.map((doc) {
              return _AlarmCard(alarmId: doc.id, data: doc.data());
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final String alarmId;
  final Map<String, dynamic> data;

  const _AlarmCard({
    required this.alarmId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final loc = data['location'] ?? {};
    final lat = loc['lat'];
    final lng = loc['lng'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['type'] == 'silent'
                        ? 'Silent Alarm'
                        : 'Emergency Alarm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(data['status'])),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'From: ${data['senderName'] ?? 'Unknown'} (${data['source']})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            if (lat != null && lng != null)
              TextButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Open Map'),
                onPressed: () {
                  final url =
                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                  launchUrl(Uri.parse(url));
                },
              ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _btn('Acknowledge', Colors.orange, () {
                  _update(alarmId, 'ack');
                }),
                _btn('Respond', Colors.blue, () {
                  _update(alarmId, 'responding');
                }),
                _btn('Close', Colors.green, () {
                  _update(alarmId, 'closed');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _btn(String text, Color color, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Text(text),
    );
  }

  static Future<void> _update(String id, String status) {
    return FirebaseFirestore.instance
        .collection('central_alarms')
        .doc(id)
        .update({'status': status});
  }
}

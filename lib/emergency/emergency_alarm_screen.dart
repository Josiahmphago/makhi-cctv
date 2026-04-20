import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlarmScreen extends StatelessWidget {
  final String areaId;
  final String source;

  const EmergencyAlarmScreen({
    super.key,
    required this.areaId,
    required this.source,
  });

  String _formatTime(dynamic ts) {
    if (ts == null) return 'Unknown time';
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy • HH:mm').format(ts.toDate());
    }
    return 'Unknown time';
  }

  Map<String, dynamic>? _readLocation(Map<String, dynamic> d) {
    if (d['location'] != null && d['location'] is Map) {
      final loc = Map<String, dynamic>.from(d['location']);
      if (loc['lat'] != null && loc['lng'] != null) return loc;
    }
    if (d['lat'] != null && d['lng'] != null) {
      return {'lat': d['lat'], 'lng': d['lng']};
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('central_alarms');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Alarms'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref
            .where('areaId', isEqualTo: areaId)
            .orderBy('triggeredAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text('No alarms yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snap.data!.docs[index];
              final d = doc.data() as Map<String, dynamic>;

              final status = (d['status'] ?? 'new').toString();
              final loc = _readLocation(d);
              final sender =
                  (d['senderName'] ?? 'Community Member').toString();
              final time = d['triggeredAt'] ?? d['createdAt'];
              final message = (d['message'] ?? '').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sender,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_formatTime(time),
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      if (message.isNotEmpty) Text(message),
                      const SizedBox(height: 6),

                      // LOCATION (CLICKABLE)
                      if (loc == null)
                        const Text('Location: Unknown')
                      else
                        GestureDetector(
                          onTap: () async {
                            final lat = loc['lat'];
                            final lng = loc['lng'];
                            final uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Text(
                            'Open in Maps',
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline),
                          ),
                        ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          if (status == 'new')
                            _actionBtn(
                              doc.id,
                              context,
                              'RESPOND',
                              Colors.blue,
                              {
                                'status': 'responding',
                                'respondingAt':
                                    FieldValue.serverTimestamp(),
                              },
                            ),
                          if (status == 'responding')
                            _actionBtn(
                              doc.id,
                              context,
                              'RESOLVE',
                              Colors.green,
                              {
                                'status': 'resolved',
                                'resolvedAt':
                                    FieldValue.serverTimestamp(),
                              },
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionBtn(
    String docId,
    BuildContext context,
    String label,
    Color color,
    Map<String, dynamic> update,
  ) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: () async {
          await FirebaseFirestore.instance
              .collection('central_alarms')
              .doc(docId)
              .update(update);
        },
        child: Text(label),
      ),
    );
  }
}
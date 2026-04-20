import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BreakdownInboxScreen extends StatelessWidget {
  const BreakdownInboxScreen({super.key});

  String _fmtTs(dynamic v) {
    if (v is Timestamp) {
      final dt = v.toDate().toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '—';
  }

  Future<void> _openMap(Map<String, dynamic>? loc) async {
    if (loc == null) return;
    final lat = loc['lat'];
    final lng = loc['lng'];
    if (lat is! num || lng is! num) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${lat.toDouble()},${lng.toDouble()}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('breakdown_requests')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(title: const Text('Breakdown Inbox')),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (!s.hasData || s.data!.docs.isEmpty) {
            return const Center(child: Text('No breakdown requests yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: s.data!.docs.map((doc) {
              final m = doc.data() as Map<String, dynamic>;
              final desc = (m['description'] ?? '').toString();
              final status = (m['status'] ?? 'pending').toString();
              final who = (m['requesterName'] ?? 'User').toString();
              final created = _fmtTs(m['createdAt']);
              final loc = (m['location'] is Map) ? (m['location'] as Map).cast<String, dynamic>() : null;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.car_crash),
                  title: Text(desc.isEmpty ? 'Vehicle breakdown' : desc),
                  subtitle: Text('Status: $status\nBy: $who\n$created'),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Open map',
                    icon: const Icon(Icons.map),
                    onPressed: () => _openMap(loc),
                  ),
                  onTap: () async {
                    // quick status cycle
                    final next = status == 'pending'
                        ? 'accepted'
                        : (status == 'accepted' ? 'resolved' : 'pending');
                    await doc.reference.update({'status': next});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked as $next')),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

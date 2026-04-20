import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlertsFeedScreen extends StatelessWidget {
  final String communityId;
  const AlertsFeedScreen({super.key, required this.communityId});

  bool _canAct(Map<String, dynamic>? me) {
    if (me == null) return false;
    final role = (me['role'] ?? 'community') as String;
    return role == 'patrol' || role == 'police' || role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    final meDoc = fs
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(FirebaseAuth.instance.currentUser?.uid ?? '_');

    final alertsQ = fs
        .collection('communities').doc(communityId)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Alerts')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: meDoc.snapshots(),
        builder: (c, meSnap) {
          final me = meSnap.data?.data() as Map<String, dynamic>?;
          final canAct = _canAct(me);

          return StreamBuilder<QuerySnapshot>(
            stream: alertsQ.snapshots(),
            builder: (c, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final docs = s.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No alerts.'));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final id = docs[i].id;
                  final title = d['title'] ?? 'Alert';
                  final body = d['body'] ?? '';
                  final status = d['status'] ?? 'open';
                  final imageUrl = d['imageUrl'] as String?;
                  final kind = d['kind'] ?? 'community';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Chip(label: Text(kind.toString())),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(status.toString()),
                              backgroundColor: status == 'resolved'
                                  ? Colors.green.shade100
                                  : (status == 'ack' ? Colors.orange.shade100 : null),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          if (body.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(body),
                          ],
                          if (imageUrl != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(imageUrl, height: 180, fit: BoxFit.cover),
                            ),
                          ],
                          if (canAct) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: status == 'ack'
                                      ? null
                                      : () {
                                          fs
                                              .collection('communities')
                                              .doc(communityId)
                                              .collection('alerts')
                                              .doc(id)
                                              .update({'status': 'ack'});
                                        },
                                  icon: const Icon(Icons.handshake),
                                  label: const Text('Acknowledge'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: status == 'resolved'
                                      ? null
                                      : () {
                                          fs
                                              .collection('communities')
                                              .doc(communityId)
                                              .collection('alerts')
                                              .doc(id)
                                              .update({'status': 'resolved'});
                                        },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Resolve'),
                                ),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

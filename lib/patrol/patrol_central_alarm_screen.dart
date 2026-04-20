import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrolCentralAlarmScreen extends StatelessWidget {
  final String areaId;

  const PatrolCentralAlarmScreen({super.key, required this.areaId});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'Unknown time';
    return DateFormat('dd MMM yyyy • HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    final alarmsQuery = db
        .collection('central_alarms')
        .where('areaId', isEqualTo: areaId)
        .orderBy('triggeredAt', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Alarms'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: alarmsQuery.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text('Permission error:\n${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No central alarms yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data();

              final status = (data['status'] ?? 'active').toString();
              final source = (data['source'] ?? 'unknown').toString();
              final sender = (data['senderName'] ?? 'Unknown').toString();

              final ts = data['triggeredAt'] as Timestamp?;
              final location = data['location'] as Map<String, dynamic>?;

              final lat = location?['lat'];
              final lng = location?['lng'];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Icon(
                            status == 'resolved'
                                ? Icons.check_circle
                                : status == 'accepted'
                                    ? Icons.pending_actions
                                    : Icons.warning_amber,
                            color: status == 'resolved'
                                ? Colors.green
                                : status == 'accepted'
                                    ? Colors.orange
                                    : Colors.red,
                            size: 28,
                          ),

                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'resolved'
                                  ? Colors.green
                                  : status == 'accepted'
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'From: $sender',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Source: ${source.toUpperCase()}',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _formatTime(ts),
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      if (lat != null && lng != null) ...[
                        Text('📍 Lat: $lat'),
                        Text('📍 Lng: $lng'),
                      ],

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _AlarmActions(
                            docRef: doc.reference,
                            status: status,
                          ),
                        ],
                      ),
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
}

class _AlarmActions extends StatelessWidget {

  final DocumentReference<Map<String, dynamic>> docRef;
  final String status;

  const _AlarmActions({
    required this.docRef,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Wrap(
      spacing: 6,
      children: [

        if (status == 'active')
          IconButton(
            tooltip: 'Accept',
            icon: const Icon(Icons.done),
            onPressed: () {
              docRef.update({
                'status': 'accepted',
                'acceptedBy': user.uid,
                'acceptedAt': FieldValue.serverTimestamp(),
              });
            },
          ),

        if (status != 'resolved')
          IconButton(
            tooltip: 'Resolve',
            icon: const Icon(Icons.task_alt),
            onPressed: () {
              docRef.update({
                'status': 'resolved',
                'resolvedBy': user.uid,
                'resolvedAt': FieldValue.serverTimestamp(),
              });
            },
          ),

        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: () {
            docRef.delete();
          },
        ),
      ],
    );
  }
}
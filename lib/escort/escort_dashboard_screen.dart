import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'escort_request_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EscortDashboardScreen extends StatelessWidget {
  const EscortDashboardScreen({super.key});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'Unknown time';
    return DateFormat('dd MMM • HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {

    final query = FirebaseFirestore.instance
        .collection('escort_requests')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAtClient', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚓 Patrol Dispatch'),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),

        builder: (context, snap) {

          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No active escort requests',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,

            itemBuilder: (_, i) {

              final doc = docs[i];
              final data = doc.data();

              final destination =
                  data['destinationText'] ?? 'Unknown destination';

              final eta = data['etaMinutes'] ?? 0;

              final userId = data['userId'] ?? 'Unknown';

              final createdAt =
                  data['createdAtClient'] as Timestamp?;

              final location = data['location'];

              double lat = 0;
              double lng = 0;

              if (location is Map) {
                lat = (location['lat'] ?? 0).toDouble();
                lng = (location['lng'] ?? 0).toDouble();
              }

              if (location is GeoPoint) {
                lat = location.latitude;
                lng = location.longitude;
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),

                child: Padding(
                  padding: const EdgeInsets.all(12),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          const Icon(Icons.person,
                              color: Colors.black54),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              'User: $userId',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Text(
                            _formatTime(createdAt),
                            style: const TextStyle(
                                color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '📍 $destination',
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 4),

                      Text('⏱ ETA: $eta minutes'),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),

onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  /// 1️⃣ UPDATE ESCORT REQUEST
  await doc.reference.update({
    'status': 'ack',
    'ackBy': user.uid,
    'ackRole': 'patrol',
    'ackAt': FieldValue.serverTimestamp(),
  });

  /// 2️⃣ UPDATE CENTRAL ALARM (CORRECT WAY)
  final alarmQuery = await FirebaseFirestore.instance
      .collection('central_alarms')
      .where('senderId', isEqualTo: data['userId'])
      .where('status', isEqualTo: 'active')
      .limit(1)
      .get();

  if (alarmQuery.docs.isNotEmpty) {
    final alarmDoc = alarmQuery.docs.first;

    await alarmDoc.reference.update({
      'status': 'in_progress',
      'assignedTo': user.uid, // 🔥 THIS WAS MISSING
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 3️⃣ SET PATROL BUSY
  await FirebaseFirestore.instance
      .collection('patrol_live')
      .doc(user.uid)
      .update({
    'status': 'busy',
  });

  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EscortRequestDetailScreen(
          requestId: doc.id,
        ),
      ),
    );
  }
},
            


                          child: const Text('ACCEPT REQUEST'),
                        ),
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
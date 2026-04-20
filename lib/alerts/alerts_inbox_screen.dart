import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertsInboxScreen extends StatelessWidget {
  const AlertsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarms = FirebaseFirestore.instance
        .collection('central_alarms')
        .where('status', isEqualTo: 'active')
        .orderBy('triggeredAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Alarms'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: alarms.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No active alarms",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final alarm = docs[index];
              final data = alarm.data() as Map<String, dynamic>;

              final sender = data['senderName'] ?? 'Unknown';
              final area = data['areaId'] ?? '';
              final location = data['location'] ?? {};

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text("🚨 Alarm from $sender"),
                  subtitle: Text("Area: $area"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("ACCEPT"),
                    onPressed: () async {

                      final user = FirebaseAuth.instance.currentUser;

                      await FirebaseFirestore.instance
                          .collection('central_alarms')
                          .doc(alarm.id)
                          .update({
                        'status': 'accepted',
                        'acceptedBy': user?.uid,
                        'acceptedAt': FieldValue.serverTimestamp(),
                      });

                    },
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
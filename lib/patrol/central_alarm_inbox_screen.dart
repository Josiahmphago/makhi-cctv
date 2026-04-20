import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/dispatch_service.dart';

class CentralAlarmInboxScreen extends StatelessWidget {
  final String areaId;

  const CentralAlarmInboxScreen({super.key, required this.areaId});

  @override
  Widget build(BuildContext context) {
    final alarms = FirebaseFirestore.instance
        .collection('central_alarms')
        .where('areaId', isEqualTo: areaId)
        .where('status', isEqualTo: 'active')
        .orderBy('triggeredAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🚨 Central Alarm Inbox"),
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

          final user = FirebaseAuth.instance.currentUser;

          /// ✅ FILTER OUT SENDER
          final alerts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['senderId'] != user?.uid;
          }).toList();

          /// ✅ USE FILTERED LIST
          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No active alarms",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final doc = alerts[index];
              final alarm = doc.data() as Map<String, dynamic>;

              final address =
                  alarm['address'] ??
                  alarm['senderName'] ??
                  "Unknown location";

              final source = alarm['source'] ?? "unknown";

              final timestamp = alarm['triggeredAt'];

              String timeText = "";
              if (timestamp != null && timestamp is Timestamp) {
                timeText = timestamp.toDate().toString();
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 30,
                  ),
                  title: Text(address),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Source: $source"),
                      if (timeText.isNotEmpty) Text("Time: $timeText"),
                    ],
                  ),

                  /// 🚓 ACCEPT BUTTON (FIXED)
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Accept"),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      await DispatchService.acceptAlert(
                        alertId: doc.id,
                        patrolId: user.uid,
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🚓 Responding to alert"),
                        ),
                      );
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
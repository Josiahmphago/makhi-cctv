// lib/screens/roles/patrol_console_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatrolConsoleScreen extends StatelessWidget {
  const PatrolConsoleScreen({super.key});

  Future<void> _acknowledgeAlert(BuildContext context, String alertId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).set({
        'status': 'ack',
        'ackRole': 'patrol',
        'ackBy': uid,
        'ackAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Alert acknowledged (Patrol)")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patrol Console")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No alerts"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;
              final msg = d['message'] ?? '(no message)';
              final status = d['status'] ?? 'open';

              return Card(
                child: ListTile(
                  title: Text(msg),
                  subtitle: Text("Status: $status"),
                  trailing: ElevatedButton(
                    child: const Text("Ack"),
                    onPressed: status == 'open'
                        ? () => _acknowledgeAlert(context, id)
                        : null,
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

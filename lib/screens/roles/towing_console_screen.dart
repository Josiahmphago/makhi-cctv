// lib/screens/roles/towing_console_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TowingConsoleScreen extends StatelessWidget {
  const TowingConsoleScreen({super.key});

  Future<void> _acknowledgeTow(BuildContext context, String requestId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('tow_requests').doc(requestId).set({
        'status': 'ack',
        'ackRole': 'towing',
        'ackBy': uid,
        'ackAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tow request acknowledged")),
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
      appBar: AppBar(title: const Text("Towing Console")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tow_requests')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No tow requests"));

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
                        ? () => _acknowledgeTow(context, id)
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

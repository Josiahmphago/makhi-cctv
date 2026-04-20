// lib/screens/roles/escort_console_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EscortConsoleScreen extends StatelessWidget {
  const EscortConsoleScreen({super.key});

  Future<void> _acknowledgeEscort(BuildContext context, String requestId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance.collection('escort_requests').doc(requestId).set({
        'status': 'ack',
        'ackRole': 'escort',
        'ackBy': uid,
        'ackAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Escort request acknowledged")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('escort_requests')
        // Prefer client timestamp (always present after our fix)
        .orderBy('createdAtClient', descending: true)
        .limit(20);

    return Scaffold(
      appBar: AppBar(title: const Text("Escort Console")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (c, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No escort requests"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i].data();
              final id = docs[i].id;

              final msg = (d['message'] ?? '(no message)').toString();
              final status = (d['status'] ?? 'open').toString();

              final dest = (d['destinationText'] ?? '').toString();
              final eta = (d['etaMinutes'] ?? '').toString();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(dest.isNotEmpty ? dest : msg),
                  subtitle: Text(
                    "ETA: ${eta.isEmpty ? '—' : '$eta min'} • Status: $status",
                  ),
                  trailing: ElevatedButton(
                    onPressed: status == 'open' ? () => _acknowledgeEscort(context, id) : null,
                    child: const Text("Ack"),
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

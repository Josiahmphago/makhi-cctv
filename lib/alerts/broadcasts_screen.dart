import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastsScreen extends StatelessWidget {
  const BroadcastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Broadcasts"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcasts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No broadcasts yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['message'] ?? ''),
                subtitle: Text(data['senderName'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

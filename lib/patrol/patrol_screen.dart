import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PatrolScreen extends StatelessWidget {
  const PatrolScreen({super.key});

  DateTime? parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patrol Shifts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patrol_shifts')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, size: 80, color: Colors.blue),
                  SizedBox(height: 20),
                  Text('No patrol shifts found.', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final shifts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final data = shifts[index].data() as Map<String, dynamic>;
              final DateTime? startTime = parseDateTime(data['startTime']);
              final DateTime? endTime = parseDateTime(data['endTime']);

              return ListTile(
                leading: const Icon(Icons.directions_walk),
                title: Text('${data['teamName'] ?? "Unknown Team"} (${data['shiftType'] ?? "N/A"})'),
                subtitle: Text(
                  '${data['areaCovered'] ?? "Unknown Area"}\n'
                  'Start: ${startTime != null ? startTime.toLocal().toString().split(".")[0] : "N/A"}\n'
                  'End: ${endTime != null ? endTime.toLocal().toString().split(".")[0] : "N/A"}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/escort_service.dart';

class EscortRequestDetailScreen extends StatelessWidget {
  final String requestId;
  EscortRequestDetailScreen({super.key, required this.requestId});

  final _svc = EscortService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escort Request'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _svc.watchRequest(requestId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data();
          if (data == null) {
            return const Center(child: Text('Request not found'));
          }

          final status = data['status'] ?? 'open';
          final dest = data['destinationText'] ?? '';
          final eta = data['etaMinutes'] ?? 0;
          final ackBy = data['ackBy'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    title: Text(dest),
                    subtitle: Text('ETA: $eta mins'),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: Text('Status: $status'),
                    subtitle:
                        ackBy != null ? Text('Acknowledged by: $ackBy') : null,
                  ),
                ),
                const Spacer(),
                if (status != 'closed')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _svc.closeRequest(requestId);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close Request'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
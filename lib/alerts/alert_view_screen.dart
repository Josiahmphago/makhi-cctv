// lib/alerts/alert_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlertViewScreen extends StatelessWidget {
  const AlertViewScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _alertsCol =>
      FirebaseFirestore.instance.collection('alerts'); // or 'community_alerts' if that’s your collection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _alertsCol
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No alerts yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final type = (data['type'] ?? 'Alert').toString();
              final message = (data['message'] ?? '').toString();
              final sender = (data['sender'] ?? '').toString();
              final createdAt = data['createdAt'];
              final imageUrl = (data['imageUrl'] ?? '').toString();
              final locationUrl = (data['locationUrl'] ?? '').toString();

              DateTime? ts;
              if (createdAt is Timestamp) {
                ts = createdAt.toDate();
              } else if (createdAt is String) {
                ts = DateTime.tryParse(createdAt);
              }
              final timeText =
                  ts != null ? '${ts.toLocal()}' : 'Unknown time';

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (dir) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete alert?'),
                          content:
                              const Text('Are you sure you want to delete this alert?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  await _alertsCol.doc(doc.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert deleted')),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(
                    message.isNotEmpty ? message : type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (sender.isNotEmpty) 'From: $sender',
                      timeText,
                    ].join(' • '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDetailsSheet(
                    context: context,
                    type: type,
                    message: message,
                    sender: sender,
                    timeText: timeText,
                    imageUrl: imageUrl,
                    locationUrl: locationUrl,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsSheet({
    required BuildContext context,
    required String type,
    required String message,
    required String sender,
    required String timeText,
    required String imageUrl,
    required String locationUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (sender.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'From: $sender',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  message.isNotEmpty ? message : '(No message text)',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (locationUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // You can later use url_launcher to open this
                      // For now, just copy to clipboard or show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Location: $locationUrl')),
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Open location'),
                  ),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text(
                        'Could not load image',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

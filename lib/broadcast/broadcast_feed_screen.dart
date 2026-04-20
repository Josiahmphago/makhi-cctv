import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BroadcastFeedScreen extends StatelessWidget {
  const BroadcastFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Compose broadcast',
            onPressed: () => Navigator.pushNamed(context, '/broadcast/compose'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcasts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _error('Failed to load broadcasts');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              // 🔐 SAFE FIELD ACCESS (NO CRASHES)
              final title = (data['title'] ?? 'Community Broadcast').toString();
              final message = (data['message'] ?? '').toString();
              final severity = (data['severity'] ?? 'info').toString();
              final source = (data['source'] ?? 'Community').toString();

              final createdAt = data['createdAt'];
              final dateText = _formatTimestamp(createdAt);

              return _BroadcastCard(
                title: title,
                message: message,
                severity: severity,
                source: source,
                dateText: dateText,
              );
            },
          );
        },
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.campaign_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No broadcasts yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Community, police, or patrol broadcasts will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String msg) {
    return Center(
      child: Text(
        msg,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  static String _formatTimestamp(dynamic value) {
    if (value == null) return 'Unknown time';

    try {
      if (value is Timestamp) {
        final dt = value.toDate();
        return DateFormat('dd MMM yyyy • HH:mm').format(dt);
      }
    } catch (_) {}

    return 'Unknown time';
  }
}

// ============================
// 📦 Broadcast Card Widget
// ============================

class _BroadcastCard extends StatelessWidget {
  final String title;
  final String message;
  final String severity;
  final String source;
  final String dateText;

  const _BroadcastCard({
    required this.title,
    required this.message,
    required this.severity,
    required this.source,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            // Message
            if (message.isNotEmpty)
              Text(
                message,
                style: const TextStyle(height: 1.35),
              ),

            const SizedBox(height: 10),

            // Footer
            Row(
              children: [
                const Icon(Icons.account_circle, size: 16),
                const SizedBox(width: 6),
                Text(
                  source,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }
}

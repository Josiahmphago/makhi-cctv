import 'package:flutter/material.dart';

import '../services/escort_service.dart';
import 'escort_request_screen.dart';

class EscortRequestStatusScreen extends StatefulWidget {
  final String requestId;

  const EscortRequestStatusScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<EscortRequestStatusScreen> createState() => _EscortRequestStatusScreenState();
}

class _EscortRequestStatusScreenState extends State<EscortRequestStatusScreen> {
  final EscortService _svc = EscortService();
  bool _shownAckDialog = false;

  void _goNewRequest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EscortRequestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escort Request Status')),
      body: StreamBuilder(
        stream: _svc.watchRequest(widget.requestId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = (snapshot.data as dynamic).data();
          if (data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Request not found'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _goNewRequest,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Request'),
                  ),
                ],
              ),
            );
          }

          final status = data['status'] ?? 'open';
          final ackBy = data['ackBy'] ?? '';
          final ackRole = data['ackRole'] ?? '';

          if (!_shownAckDialog && status == 'ack') {
            _shownAckDialog = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Acknowledged'),
                  content: Text('By: $ackBy\nRole: $ackRole'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
          }

          IconData icon;
          if (status == 'ack') {
            icon = Icons.verified;
          } else if (status == 'closed') {
            icon = Icons.check_circle;
          } else {
            icon = Icons.hourglass_top;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text('Status: $status'),
                    subtitle: status == 'ack'
                        ? Text('Acknowledged by: $ackBy ($ackRole)')
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Always allow making a new request (this fixes your problem)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goNewRequest,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Request'),
                  ),
                ),

                const Spacer(),

                if (status != 'closed')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _svc.closeRequest(widget.requestId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request closed')),
                        );
                        setState(() {
                          // Keep screen alive; user can press "Create New Request"
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Close Request'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
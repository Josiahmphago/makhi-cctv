import 'package:flutter/material.dart';
import 'escort_request_screen.dart';
import 'escort_dashboard_screen.dart';

class EscortScreen extends StatelessWidget {
  const EscortScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escort')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text('Request Escort'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EscortRequestScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('My Requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EscortDashboardScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

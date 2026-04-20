import 'package:flutter/material.dart';

class ContractorDashboardScreen extends StatelessWidget {
  const ContractorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '📋 Available Jobs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Repair Pothole on Main Street'),
              subtitle: const Text('Reported by: Reporter A'),
              trailing: ElevatedButton(
                child: const Text('Accept'),
                onPressed: () {
                  // Implement job acceptance logic
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🧾 My Accepted Jobs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Fix Drain Blockage - Zone 2'),
              subtitle: const Text('Status: In Progress'),
              trailing: ElevatedButton(
                child: const Text('Update'),
                onPressed: () {
                  // Implement status update logic
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🚨 Patrol Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Night Patrol - Sector B'),
              subtitle: const Text('Time: 21:00 - 02:00'),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.navigate_next),
                label: const Text('Open'),
                onPressed: () {
                  Navigator.pushNamed(context, '/patrol/request');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

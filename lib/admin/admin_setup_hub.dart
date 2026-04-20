import 'package:flutter/material.dart';

class AdminSetupHub extends StatelessWidget {
  const AdminSetupHub({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(String title, IconData icon, String route) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, route),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Setup')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Create the directories that power shifts + nearby help.\n'
              'If these are empty, Nearby Help will always show “No nearby services found”.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          tile('Manage Areas', Icons.map, '/admin/areas'),
          tile('Manage Patrol Teams', Icons.group, '/admin/patrol-teams'),
          tile('Manage Patrol Agents', Icons.person_pin_circle, '/admin/patrol-agents'),
          const Divider(),
          tile('Seed Test Nearby Data (recommended)', Icons.bug_report, '/admin/seed-nearby'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PatrolMenuScreen extends StatelessWidget {
  const PatrolMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final List<_MenuOption> options = [

      /// 🚨 USER REQUESTS
      _MenuOption(
        "Request Patrol",
        Icons.shield,
        '/patrol/request',
      ),

      _MenuOption(
        "Request Escort",
        Icons.directions_walk,
        '/escort/request',
      ),

      _MenuOption(
        "Nearby Security",
        Icons.location_on,
        '/nearby',
      ),

      /// 🚓 PATROL OPERATIONS
      _MenuOption(
        "Patrol Dashboard",
        Icons.dashboard,
        '/patrol/dashboard',
      ),

      _MenuOption(
        "Shift Schedule",
        Icons.schedule,
        '/admin/patrol/planner',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patrol Menu"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {

          final option = options[index];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Icon(option.icon, size: 28),
              title: Text(
                option.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, option.route);
              },
            ),
          );
        },
      ),
    );
  }
}

class _MenuOption {
  final String label;
  final IconData icon;
  final String route;

  _MenuOption(this.label, this.icon, this.route);
}
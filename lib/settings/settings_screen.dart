// lib/settings/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ======================
          // SAFETY
          // ======================
          _sectionTitle("SAFETY"),
          _item(context, "Groups", Icons.group, '/group'),
          _item(context, "Emergency Contacts", Icons.contact_phone, '/alerts'),
          _item(context, "Central Alarm", Icons.notifications_active, '/central/alarms'),

          // ======================
          // COMMUNITY
          // ======================
          _sectionTitle("COMMUNITY"),
          _item(context, "Broadcast Feed", Icons.campaign, '/broadcasts'),
          _item(context, "Community Reports", Icons.report, '/community/reports/inbox'),
          _item(context, "Nearby Help", Icons.location_on, '/nearby'),

          // ======================
          // OPERATIONS
          // ======================
          _sectionTitle("OPERATIONS"),
          _item(context, "Patrol Dashboard", Icons.directions_walk, '/patrol/dashboard'),
          _item(context, "Police Dashboard", Icons.local_police, '/police'),
          _item(context, "Escort Dashboard", Icons.security, '/escort/dashboard'),
          _item(context, "Breakdown Requests", Icons.car_repair, '/breakdown/request'),

          // ======================
          // SERVICES
          // ======================
          _sectionTitle("SERVICES"),
          _item(context, "Buy Airtime", Icons.phone_android, '/airtime'),
          _item(context, "Buy Data", Icons.wifi, '/airtime'),

          // ======================
          // SYSTEM
          // ======================
          _sectionTitle("SYSTEM"),
          _item(context, "Statistics", Icons.bar_chart, '/stats'),
          _item(context, "Admin Panel", Icons.admin_panel_settings, '/admin/roles'),
          _item(context, "Debug Firestore", Icons.bug_report, '/debug/firestore'),

        ],
      ),
    );
  }
}
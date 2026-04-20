import 'package:flutter/material.dart';

// Screens we’ll link to
import '../screens/admin/admin_screen.dart';
import '../patrol/manage_patrol_teams_screen.dart';
import '../patrol/create_patrol_shift_screen.dart';
import '../escort/escort_dashboard_screen.dart';
import '../alerts/alerts_inbox_screen.dart';
import '../alerts/panic_settings_screen.dart';

import 'seed_demo_data.dart';
import 'manage_alert_groups_screen.dart';
import 'assign_group_contacts_screen.dart';
import 'manage_areas_screen.dart';
import 'manage_patrol_agents_screen.dart';
import 'seed_nearby_data_screen.dart';
import 'patrol_shift_planner_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// USERS
          _section('Users & Access', [

            _tile(
              context,
              icon: Icons.admin_panel_settings,
              title: 'User Management',
              subtitle: 'View users, edit roles, send reset email, remove user.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.sos,
              title: 'Panic Contacts',
              subtitle: 'Configure default WhatsApp/SMS recipients for SOS.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PanicSettingsScreen()),
              ),
            ),
          ]),

          /// PATROL
          _section('Patrol & Shifts', [

            _tile(
              context,
              icon: Icons.groups,
              title: 'Manage Patrol Teams',
              subtitle: 'Create/edit teams with auto-location.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePatrolTeamsScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.schedule,
              title: 'Create Patrol Shift',
              subtitle: 'Assign time ranges to teams.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePatrolShiftScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.event_available,
              title: 'Patrol Shift Planner',
              subtitle: 'Plan patrol schedules based on agent availability.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatrolShiftPlannerScreen()),
              ),
            ),
          ]),

          /// OPERATIONS
          _section('Operations', [

            _tile(
              context,
              icon: Icons.security,
              title: 'Escort Requests',
              subtitle: 'Monitor/respond to live escort requests.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EscortDashboardScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.notifications,
              title: 'Alerts Inbox',
              subtitle: 'Community & police alerts stream.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsInboxScreen()),
              ),
            ),
          ]),

          /// ALERT SYSTEM
          _section('Alert System', [

            _tile(
              context,
              icon: Icons.group,
              title: 'Manage Alert Groups',
              subtitle: 'Create police, patrol, family and community groups.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAlertGroupsScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.group_add,
              title: 'Assign Group Contacts',
              subtitle: 'Assign phone contacts to alert groups.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignGroupContactsScreen()),
              ),
            ),
          ]),

          /// LOCATION SYSTEM
          _section('Nearby / Location System', [

            _tile(
              context,
              icon: Icons.map,
              title: 'Manage Areas',
              subtitle: 'Create areas for patrol operations.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAreasScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.person_pin,
              title: 'Manage Patrol Agents',
              subtitle: 'Register and monitor patrol agents.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePatrolAgentsScreen()),
              ),
            ),

            _tile(
              context,
              icon: Icons.location_searching,
              title: 'Seed Nearby Data',
              subtitle: 'Create patrol teams and police for Nearby Help testing.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeedNearbyDataScreen()),
              ),
            ),
          ]),

          /// SETUP
          _section('Setup Helpers', [

            _tile(
              context,
              icon: Icons.auto_fix_high,
              title: 'Seed Demo Data',
              subtitle: 'Create example groups/teams/shifts so everything works now.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeedDemoDataScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
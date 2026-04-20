import 'package:flutter/material.dart';

import 'alert_composer.dart';
import 'alert_view_screen.dart';
import '../emergency/quick_alert_screen.dart';

class AlertsHubScreen extends StatelessWidget {
  const AlertsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit), text: 'New Alert'),
              Tab(icon: Icon(Icons.inbox), text: 'Inbox'),
              Tab(icon: Icon(Icons.flash_on), text: 'Quick Alerts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1) Compose / normal alerts
            AlertComposer(),
            // 2) Inbox / history
            AlertViewScreen(),
            // 3) Quick alert shortcuts / templates
            QuickAlertScreen(),
          ],
        ),
      ),
    );
  }
}

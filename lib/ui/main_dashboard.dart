import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Makhi CCTV"),
          centerTitle: true,

          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => _logout(context),
            ),
          ],

          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shield), text: "Patrol"),
              Tab(icon: Icon(Icons.videocam), text: "Cameras"),
              Tab(icon: Icon(Icons.apps), text: "Services"),
            ],
          ),
        ),

        /// TAB CONTENT
        body: TabBarView(
          children: const [
            PatrolTab(),
            CamerasTab(),
            ServicesTab(),
          ],
        ),

        /// GLOBAL PANIC BUTTON
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.red,
          icon: const Icon(Icons.sos),
          label: const Text("PANIC"),
          onPressed: () {
            Navigator.pushNamed(context, '/quick_alert');
          },
        ),

        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

///////////////////////////////////////////////////////////
/// MENU MODEL
///////////////////////////////////////////////////////////

class MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  const MenuItem(
    this.title,
    this.subtitle,
    this.icon,
    this.routeName,
  );
}

///////////////////////////////////////////////////////////
/// MENU LIST
///////////////////////////////////////////////////////////

class MenuList extends StatelessWidget {
  final List<MenuItem> items;

  const MenuList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(item.icon, size: 30),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(ctx, item.routeName);
            },
          ),
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////
/// PATROL TAB
///////////////////////////////////////////////////////////

class PatrolTab extends StatelessWidget {
  const PatrolTab({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <MenuItem>[
      const MenuItem(
        "Request Patrol / Escort",
        "Ask patrol team for help",
        Icons.shield,
        "/patrol/request",
      ),
      const MenuItem(
        "Patrol Control Center",
        "Central alarms and dispatch",
        Icons.security,
        "/patrol/dashboard",
      ),
      const MenuItem(
        "Compose Alert",
        "Send alert with location",
        Icons.campaign,
        "/alerts/compose",
      ),
      const MenuItem(
        "Alerts Inbox",
        "View alerts",
        Icons.inbox,
        "/alerts",
      ),
    ];

    return Column(
      children: [

        /// BIG PANIC BUTTON
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sos, size: 30),
              label: const Text(
                "EMERGENCY PANIC ALERT",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/quick_alert');
              },
            ),
          ),
        ),

        /// MENU
        Expanded(
          child: MenuList(items: items),
        ),
      ],
    );
  }
}

///////////////////////////////////////////////////////////
/// CAMERAS TAB
///////////////////////////////////////////////////////////

class CamerasTab extends StatelessWidget {
  const CamerasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Camera System Ready 📷",
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

///////////////////////////////////////////////////////////
/// SERVICES TAB
///////////////////////////////////////////////////////////

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <MenuItem>[
      const MenuItem(
        "Groups & Community",
        "Community groups",
        Icons.group,
        "/group",
      ),
      const MenuItem(
        "Community Reports",
        "Submit reports",
        Icons.edit_note,
        "/community/report",
      ),
      const MenuItem(
        "Settings",
        "App settings",
        Icons.settings,
        "/settings",
      ),
    ];

    return MenuList(items: items);
  }
}
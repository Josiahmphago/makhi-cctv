import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 560 ? 3 : 2;
    final tileAspect = width >= 560 ? 1.15 : 0.95;

    final mainItems = _items.where((e) => !e.adminOnly).toList(growable: false);
    final adminItems = _items.where((e) => e.adminOnly).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Makhi CCTV Dashboard')),

      // 🔴 BIG EMERGENCY BUTTON
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _EmergencyFAB(),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomScrollView(
            slivers: [
              _sectionHeader('Main'),
              SliverPadding(
                padding: const EdgeInsets.only(top: 12, bottom: 18),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final it = mainItems[i];
                      return _DashboardTile(
                        icon: it.icon,
                        label: it.label,
                        subtitle: it.subtitle,
                        onTap: () => Navigator.pushNamed(context, it.route),
                      );
                    },
                    childCount: mainItems.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: tileAspect,
                  ),
                ),
              ),
              _sectionHeader('Admin tools'),
              SliverPadding(
                padding: const EdgeInsets.only(top: 12, bottom: 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final it = adminItems[i];
                      return _DashboardTile(
                        icon: it.icon,
                        label: it.label,
                        subtitle: it.subtitle,
                        badge: const _Badge(text: 'ADMIN'),
                        onTap: () => Navigator.pushNamed(context, it.route),
                      );
                    },
                    childCount: adminItems.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: tileAspect,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Divider(height: 1)),
          ],
        ),
      ),
    );
  }
}

/// 🔴 EMERGENCY BUTTON (SAFE + ROUTE-BASED)
class _EmergencyFAB extends StatelessWidget {
  const _EmergencyFAB();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.warning_amber, size: 28),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'EMERGENCY',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      onPressed: () {
        Navigator.pushNamed(context, '/emergency/alarm');
      },
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final String route;
  final String? subtitle;
  final bool adminOnly;

  const _DashboardItem({
    required this.icon,
    required this.label,
    required this.route,
    this.subtitle,
    this.adminOnly = false,
  });
}

/// ⚠️ DATA ONLY — NO WIDGETS HERE
const _items = <_DashboardItem>[
  _DashboardItem(
    icon: Icons.location_searching,
    label: 'Nearby Help',
    subtitle: 'Police • Patrol • Security',
    route: '/nearby',
  ),
  _DashboardItem(
    icon: Icons.warning_amber,
    label: 'Alerts Hub',
    subtitle: 'Create & view alerts',
    route: '/alerts',
  ),
  _DashboardItem(
    icon: Icons.security,
    label: 'Escort',
    subtitle: 'Request escort',
    route: '/escort/dashboard',
  ),
  _DashboardItem(
    icon: Icons.car_repair,
    label: 'Vehicle Breakdown',
    subtitle: 'Towing & help',
    route: '/breakdown/request',
  ),
  _DashboardItem(
    icon: Icons.shield,
    label: 'Patrol Dashboard',
    subtitle: 'Shifts & alerts',
    route: '/patrol/dashboard',
  ),
  _DashboardItem(
    icon: Icons.camera_alt,
    label: 'Cameras',
    subtitle: 'View & add cameras',
    route: '/cameras',
  ),
  _DashboardItem(
    icon: Icons.group,
    label: 'Groups',
    subtitle: 'Family & community',
    route: '/group',
  ),
  _DashboardItem(
    icon: Icons.settings,
    label: 'Settings',
    subtitle: 'Preferences',
    route: '/settings',
  ),

  // ADMIN
  _DashboardItem(
    icon: Icons.apartment,
    label: 'Directory Admin',
    subtitle: 'Police & patrol',
    route: '/admin/directory',
    adminOnly: true,
  ),
  _DashboardItem(
    icon: Icons.auto_fix_high,
    label: 'Seed Demo Data',
    subtitle: 'Sample docs',
    route: '/admin/seed',
    adminOnly: true,
  ),
];

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              if (badge != null) Positioned(right: 0, top: 0, child: badge!),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

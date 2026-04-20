import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Makhi CCTV'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 🔴 SOS BUTTON (MAIN ACTION)
            GestureDetector(
              onLongPress: () {
                Navigator.pushNamed(context, '/panic');
              },
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos, size: 80, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'SOS ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hold to send emergency alert',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🚶 Escort
            _ActionTile(
              icon: Icons.directions_walk,
              label: 'Escort Me Home',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/escort/request'),
            ),

            // 📢 Quick Alert
            _ActionTile(
              icon: Icons.flash_on,
              label: 'Quick Alert',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/quick_alert'),
            ),

            // 📍 Nearby Help
            _ActionTile(
              icon: Icons.location_on,
              label: 'Nearby Help',
              color: Colors.blue,
              onTap: () { Navigator.of(context).pushNamed('/nearby');
              }
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

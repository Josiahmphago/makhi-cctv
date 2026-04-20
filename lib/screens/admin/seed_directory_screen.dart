// lib/screens/admin/seed_directory_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/directory_admin_service.dart';

class SeedDirectoryScreen extends StatefulWidget {
  const SeedDirectoryScreen({super.key});

  @override
  State<SeedDirectoryScreen> createState() => _SeedDirectoryScreenState();
}

class _SeedDirectoryScreenState extends State<SeedDirectoryScreen> {
  final _svc = DirectoryAdminService();

  bool _loading = false;
  String? _status;

  Future<Position> _getPos() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location services are OFF.');

    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    );
  }

  Future<void> _seed() async {
    setState(() {
      _loading = true;
      _status = 'Getting location...';
    });

    try {
      final p = await _getPos();

      setState(() => _status = 'Seeding demo directory data...');

      await _svc.seedNear(lat: p.latitude, lng: p.longitude);

      if (!mounted) return;
      setState(() => _status = '✅ Seeded! Open Nearby Help to see results.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '❌ Seed failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Directory Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'This will create demo Police + Patrol entries near your current location.\n'
                  'It also auto-generates geohash so Nearby Help can find them.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _seed,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: const Text('Seed demo directory data'),
            ),
            const SizedBox(height: 16),
            if (_status != null)
              Text(
                _status!,
                style: TextStyle(
                  color: _status!.startsWith('✅')
                      ? Colors.green
                      : (_status!.startsWith('❌') ? Colors.red : Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

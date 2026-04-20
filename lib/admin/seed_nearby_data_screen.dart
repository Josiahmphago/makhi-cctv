import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SeedNearbyDataScreen extends StatefulWidget {
  const SeedNearbyDataScreen({super.key});

  @override
  State<SeedNearbyDataScreen> createState() => _SeedNearbyDataScreenState();
}

class _SeedNearbyDataScreenState extends State<SeedNearbyDataScreen> {
  bool _busy = false;
  String _status = '';

  Future<void> _seed() async {
    setState(() {
      _busy = true;
      _status = 'Getting GPS...';
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('GPS is off.');

      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final gh = _encodeGeohash(p.latitude, p.longitude, precision: 9);

      setState(() => _status = 'Writing Firestore docs...');

      // Ensure Default area exists
      await FirebaseFirestore.instance.collection('areas').add({
        'name': 'Default',
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Police station
      await FirebaseFirestore.instance.collection('police_stations').add({
        'enabled': true,
        'name': 'Nearest Police (Test)',
        'phoneNumber': '10111',
        'address': 'Test station near your location',
        'location': {'lat': p.latitude, 'lng': p.longitude, 'geohash': gh},
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Patrol team
      await FirebaseFirestore.instance.collection('patrol_teams').add({
        'enabled': true,
        'name': 'Patrol Default (Test)',
        'phoneNumber': '0821234567',
        'address': 'Test patrol team near your location',
        'location': {'lat': p.latitude, 'lng': p.longitude, 'geohash': gh},
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _status = 'Seeded ✅ Now open Nearby Help.');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Nearby Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'This creates sample docs so Nearby Help will NOT be empty.\n'
              'It uses your current GPS and writes to: areas, police_stations, patrol_teams.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _seed,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Seed now'),
              ),
            ),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }

  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  String _encodeGeohash(double lat, double lng, {int precision = 9}) {
    var minLat = -90.0, maxLat = 90.0;
    var minLng = -180.0, maxLng = 180.0;

    final bits = <int>[16, 8, 4, 2, 1];
    var bit = 0;
    var ch = 0;
    var even = true;

    final sb = StringBuffer();
    while (sb.length < precision) {
      if (even) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= bits[bit];
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= bits[bit];
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        sb.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return sb.toString();
  }
}

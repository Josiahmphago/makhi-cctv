import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/patrol_location_service.dart';

class PatrolDashboard extends StatefulWidget {
  final String area;

  const PatrolDashboard({
    super.key,
    required this.area,
  });

  @override
  State<PatrolDashboard> createState() => _PatrolDashboardState();
}

class _PatrolDashboardState extends State<PatrolDashboard> {
  bool _trackingStarted = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for live patrol tracking'),
        ),
      );
      return;
    }

    await PatrolLocationService.startTracking();
    if (!mounted) return;

    setState(() {
      _trackingStarted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Live patrol tracking started')),
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _setBusy() async {
    try {
      await PatrolLocationService.setBusy(areaId: widget.area);
      if (!mounted) return;
      setState(() => _isBusy = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚓 Status set to BUSY')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set busy: $e')),
      );
    }
  }

  Future<void> _setAvailable() async {
    try {
      await PatrolLocationService.setAvailable(areaId: widget.area);
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🟢 Status set to AVAILABLE')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set available: $e')),
      );
    }
  }

  @override
  void dispose() {
    PatrolLocationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _trackingStarted
        ? (_isBusy ? 'BUSY' : 'AVAILABLE')
        : 'TRACKING OFF';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.shield, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Area: ${widget.area}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text('Tracking: ${_trackingStarted ? "ON" : "OFF"}'),
                          Text('Status: $statusText'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _tile(context, 'Patrol', Icons.shield, '/patrol/request'),
                  _tile(context, 'Escort', Icons.directions_walk, '/escort/request'),
                  _tile(context, 'Alarms', Icons.warning, '/central/alarms'),
                  _tile(context, 'Command Map', Icons.map, '/command'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: _setBusy,
                    child: const Text('SET BUSY'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _setAvailable,
                    child: const Text('SET AVAILABLE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
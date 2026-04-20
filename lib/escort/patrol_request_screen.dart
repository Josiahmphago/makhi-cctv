import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/escort_service.dart';
import 'escort_request_detail_screen.dart';

class PatrolRequestScreen extends StatefulWidget {
  const PatrolRequestScreen({super.key});

  @override
  State<PatrolRequestScreen> createState() => _PatrolRequestScreenState();
}

class _PatrolRequestScreenState extends State<PatrolRequestScreen> {
  final _svc = EscortService();

  final _destinationCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  int _etaMinutes = 15;
  bool _sending = false;

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<GeoPoint> _getUserLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location services are disabled');

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(pos.latitude, pos.longitude);
  }

  Future<void> _submit() async {
    final destinationText = _destinationCtrl.text.trim();
    if (destinationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final userLoc = await _getUserLocation();
      final requestId = await _svc.createEscortRequest(
        etaMinutes: _etaMinutes,
        destinationText: destinationText,
        userLocation: userLoc,
        message: _messageCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escort request sent. Waiting for responders…')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EscortRequestDetailScreen(requestId: requestId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Escort')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'ETA (minutes)',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _etaMinutes,
                items: const [10, 15, 20, 30, 45, 60]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                    .toList(),
                onChanged: (v) => setState(() => _etaMinutes = v ?? 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationCtrl,
            decoration: const InputDecoration(
              labelText: 'Destination (address or landmark)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            decoration: const InputDecoration(
              labelText: 'Optional message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: const Icon(Icons.security),
              label: Text(_sending ? 'Sending…' : 'Request Escort'),
            ),
          ),
        ],
      ),
    );
  }
}

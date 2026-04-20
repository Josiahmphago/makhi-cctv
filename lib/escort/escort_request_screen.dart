import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/escort_service.dart';
import 'escort_request_status_screen.dart';

class EscortRequestScreen extends StatefulWidget {
  const EscortRequestScreen({super.key});

  @override
  State<EscortRequestScreen> createState() =>
      _EscortRequestScreenState();
}

class _EscortRequestScreenState
    extends State<EscortRequestScreen> {
  final EscortService _svc = EscortService();

  final TextEditingController _destinationCtrl =
      TextEditingController();
  final TextEditingController _messageCtrl =
      TextEditingController();

  int _etaMinutes = 15;
  bool _loading = false;

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<GeoPoint> _getGeoPoint() async {
    final enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception('Location services disabled');
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      throw Exception(
          'Location permission denied');
    }

    final position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high,
    );

    return GeoPoint(
        position.latitude,
        position.longitude);
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  Future<void> _submit() async {
    if (_loading) return;

    final destination =
        _destinationCtrl.text.trim();

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please enter destination'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔥 Print Firebase project to confirm environment
      print(
          "FIREBASE PROJECT: ${Firebase.app().options.projectId}");

      final userLocation =
          await _getGeoPoint();

      final requestId =
          await _svc.createEscortRequest(
        etaMinutes: _etaMinutes,
        destinationText: destination,
        userLocation: userLocation,
        message: _messageCtrl.text
                .trim()
                .isEmpty
            ? null
            : _messageCtrl.text.trim(),
      );

      print(
          "ESCORT CREATED WITH ID: $requestId");

      // 🔥 Immediately read it back
      final snapshot =
          await FirebaseFirestore.instance
              .collection(
                  'escort_requests')
              .doc(requestId)
              .get();

      print(
          "READ BACK STATUS: ${snapshot.data()?['status']}");

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Escort request created'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EscortRequestStatusScreen(
            requestId: requestId,
          ),
        ),
      );
    } catch (e) {
      print("SUBMIT ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Request Escort'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'ETA (minutes)',
            style: TextStyle(
                fontWeight:
                    FontWeight.bold),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: _etaMinutes,
            items: const [
              5,
              10,
              15,
              20,
              30,
              45,
              60
            ]
                .map(
                  (m) =>
                      DropdownMenuItem(
                    value: m,
                    child:
                        Text('$m minutes'),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() =>
                    _etaMinutes =
                        v ?? 15),
          ),

          const SizedBox(height: 16),

          TextField(
            controller:
                _destinationCtrl,
            decoration:
                const InputDecoration(
              labelText:
                  'Destination',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller:
                _messageCtrl,
            decoration:
                const InputDecoration(
              labelText:
                  'Optional message',
              border:
                  OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child:
                ElevatedButton.icon(
              onPressed:
                  _loading
                      ? null
                      : _submit,
              icon: const Icon(
                  Icons.security),
              label: Text(
                _loading
                    ? 'Sending...'
                    : 'Request Escort',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
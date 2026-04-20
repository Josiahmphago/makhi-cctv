import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../escort/escort_request_status_screen.dart';

class PatrolRequestScreen extends StatefulWidget {
  const PatrolRequestScreen({super.key});

  @override
  State<PatrolRequestScreen> createState() => _PatrolRequestScreenState();
}

class _PatrolRequestScreenState extends State<PatrolRequestScreen> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  int _etaMinutes = 15;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _destinationCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  /// -----------------------------------------
  /// CHECK IF USER ALREADY HAS OPEN PATROL REQUEST
  /// -----------------------------------------
  Future<void> _checkExistingRequest() async {

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final query = await _db
        .collection('patrol_requests')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {

      final requestId = query.docs.first.id;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EscortRequestStatusScreen(
            requestId: requestId,
          ),
        ),
      );
    }
  }

  /// -----------------------------------------
  /// GET USER GPS LOCATION
  /// -----------------------------------------
  Future<GeoPoint> _getGeoPoint() async {

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Location services disabled');

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return GeoPoint(position.latitude, position.longitude);
  }

  /// -----------------------------------------
  /// SUBMIT PATROL REQUEST
  /// -----------------------------------------
  Future<void> _submit() async {

    if (_sending) return;

    final destination = _destinationCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter destination')),
      );
      return;
    }

    setState(() => _sending = true);

    try {

      final user = FirebaseAuth.instance.currentUser!;
      final location = await _getGeoPoint();

      /// CREATE PATROL REQUEST
      final requestRef = await _db.collection('patrol_requests').add({

        'userId': user.uid,
        'destinationText': destination,
        'message': message,
        'etaMinutes': _etaMinutes,

        'status': 'open',

        'location': location,

        'createdAtClient': FieldValue.serverTimestamp(),

      });

      /// CREATE CENTRAL ALARM (FOR COMMAND CENTER)
    await FirebaseFirestore.instance
    .collection('central_alarms')
    .doc(requestRef.id)
    .set({

  'type': 'request',
  'source': 'patrol',

  'status': 'active',

  'title': '🚓 Patrol Request',
  'description': destination,

  'senderId': user.uid,
  'senderName': user.email ?? 'Unknown',

  'triggeredAt': FieldValue.serverTimestamp(),

  'location': {
    'lat': location.latitude,
    'lng': location.longitude,
  }

});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚓 Patrol request sent'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EscortRequestStatusScreen(
            requestId: requestRef.id,
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );

    } finally {

      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// -----------------------------------------
  /// UI
  /// -----------------------------------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Patrol'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            'ETA (minutes)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: _etaMinutes,
            items: const [5, 10, 15, 20, 30, 45, 60]
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text('$m minutes'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _etaMinutes = v ?? 15),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _destinationCtrl,
            decoration: const InputDecoration(
              labelText: 'Destination (address or landmark)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _messageCtrl,
            decoration: const InputDecoration(
              labelText: 'Optional message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: const Icon(Icons.security),
              label: Text(_sending ? 'Sending…' : 'Send Patrol Request'),
            ),
          ),
        ],
      ),
    );
  }
}
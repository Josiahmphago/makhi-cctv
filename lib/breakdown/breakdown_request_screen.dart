// lib/breakdown/breakdown_request_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class BreakdownRequestScreen extends StatefulWidget {
  const BreakdownRequestScreen({super.key});

  @override
  State<BreakdownRequestScreen> createState() => _BreakdownRequestScreenState();
}

class _BreakdownRequestScreenState extends State<BreakdownRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  bool _sending = false;
  Position? _pos;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  /// -----------------------------
  /// GET LOCATION
  /// -----------------------------
  Future<void> _getLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    final perm = await Geolocator.requestPermission();

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true,
    );

    setState(() => _pos = p);
  }

  /// -----------------------------
  /// SEND BREAKDOWN REQUEST
  /// -----------------------------
  Future<void> _send() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {

      await _getLocation();

      final user = FirebaseAuth.instance.currentUser;
      final p = _pos;

      /// CREATE REQUEST DOC ID FIRST
      final requestRef =
          FirebaseFirestore.instance.collection('breakdown_requests').doc();

      /// SAVE BREAKDOWN REQUEST
      await requestRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',

        'requesterUid': user?.uid,
        'requesterName': user?.email ?? 'User',

        'description': _descCtrl.text.trim(),

        'location': (p == null)
            ? null
            : {
                'lat': p.latitude,
                'lng': p.longitude,
              },
      });

      /// CREATE CENTRAL ALARM (COMMAND CENTER)
      await FirebaseFirestore.instance
          .collection('central_alarms')
          .doc(requestRef.id)
          .set({

        'areaId': 'Default',

        'source': 'breakdown_request',

        'status': 'active',

        'senderId': user?.uid,
        'senderName': user?.email ?? 'Unknown',

        'triggeredAt': FieldValue.serverTimestamp(),

        'location': (p == null)
            ? null
            : {
                'lat': p.latitude,
                'lng': p.longitude,
              },

      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Breakdown request sent'),
        ),
      );

      _descCtrl.clear();

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $e')),
      );

    } finally {

      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// -----------------------------
  /// UI
  /// -----------------------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Breakdown Request'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What happened?',
                  hintText: 'e.g. Flat tyre, engine failure, accident…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Enter a short description'
                        : null,
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,

                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),

                  label: Text(_sending ? 'Sending…' : 'Send request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
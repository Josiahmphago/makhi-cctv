import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../location/location_service.dart';

class QuickAlertScreen extends StatefulWidget {
  const QuickAlertScreen({super.key});

  @override
  State<QuickAlertScreen> createState() => _QuickAlertScreenState();
}

class _QuickAlertScreenState extends State<QuickAlertScreen> {
  bool sending = false;

  Future<void> triggerAlarm() async {
    if (sending) return;

    setState(() {
      sending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      print("🚨 PANIC BUTTON PRESSED");

      /// Get location
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        throw Exception("Could not obtain location");
      }

      /// Create alarm document
      await FirebaseFirestore.instance.collection('central_alarms').add({
        'areaId': 'Default',

        /// Alarm status
        'status': 'active',

        'source': 'phone_panic',

        /// Standard timestamp for queries
        'timestamp': FieldValue.serverTimestamp(),

        /// Extra timestamp for analytics
        'triggeredAt': FieldValue.serverTimestamp(),

        /// Sender info
        'senderId': user.uid,
        'senderName': user.email ?? 'Unknown',

        'triggeredBy': user.uid,

        /// Patrol will fill this when accepting
        'acceptedBy': null,

        /// Location structure used by Makhi
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
      });

      print("✅ Alarm written to Firestore");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚨 Emergency alert sent"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Alarm error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sending alert: $e"),
          ),
        );
      }
    }

    setState(() {
      sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Alert"),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.sos, size: 40),
          label: const Text(
            "SEND EMERGENCY ALERT",
            style: TextStyle(fontSize: 20),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 20,
            ),
          ),
          onPressed: sending ? null : triggerAlarm,
        ),
      ),
    );
  }
}
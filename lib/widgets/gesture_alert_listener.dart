import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GestureAlertListener extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTripleTap;

  const GestureAlertListener({
    Key? key,
    required this.child,
    this.onTripleTap,
  }) : super(key: key);

  @override
  State<GestureAlertListener> createState() => _GestureAlertListenerState();
}

class _GestureAlertListenerState extends State<GestureAlertListener> {
  int _tapCount = 0;
  DateTime? _firstTapTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();

        if (_firstTapTime == null ||
            now.difference(_firstTapTime!) > const Duration(seconds: 2)) {
          _firstTapTime = now;
          _tapCount = 1;
        } else {
          _tapCount++;
        }

        if (_tapCount == 3) {
          _tapCount = 0;
          _firstTapTime = null;

          // 🔒 Trigger Silent Alert
          await _sendSilentAlert();

          if (widget.onTripleTap != null) {
            widget.onTripleTap!();
          }
        }
      },
      child: widget.child,
    );
  }

  Future<void> _sendSilentAlert() async {
    try {
     final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) return;

      await FirebaseFirestore.instance.collection('alerts').add({
        'type': 'silent',
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'message': 'Silent alert triggered by triple-tap.',
        'confirmed': false,
      });

      debugPrint("✅ Silent alert sent.");
    } catch (e) {
      debugPrint("❌ Failed to send silent alert: $e");
    }
  }
}

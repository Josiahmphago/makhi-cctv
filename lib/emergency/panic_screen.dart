import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/panic_service.dart';

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  bool _sending = false;

  Future<void> _sendPanic() async {
    setState(() => _sending = true);

    try {
      await PanicService.triggerPanic(
        message: "Emergency! Please assist.",
        areaId: "Default",
        source: "phone",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panic sent ✅')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _stopAlarm() async {
    final ref = FirebaseFirestore.instance
        .collection('central_alarms')
        .where('senderId',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy('triggeredAt', descending: true)
        .limit(1);

    final snap = await ref.get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'alarmActive': false,
        'status': 'accepted',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panic Alert')),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.sos, size: 32),
              label: Text(_sending ? 'Sending…' : 'Send Panic'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              onPressed: _sending ? null : _sendPanic,
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: _stopAlarm,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('Stop Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
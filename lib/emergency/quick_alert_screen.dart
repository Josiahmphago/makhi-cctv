import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class QuickAlertScreen extends StatefulWidget {
  const QuickAlertScreen({super.key});

  @override
  State<QuickAlertScreen> createState() => _QuickAlertScreenState();
}

class _QuickAlertScreenState extends State<QuickAlertScreen> {
  bool _busy = false;

  Future<void> _send(String message) async {
    setState(() => _busy = true);
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) throw Exception('Not signed in');

      await FirebaseFirestore.instance.collection('alerts').add({
        'userId': u.uid,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // best-effort fanout (public function)
      try {
        await http.post(
          Uri.parse('https://panicfanout-wezpkvn2eq-uc.a.run.app'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message}),
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick alert sent')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Alert')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _send('SOS 🚨'),
              icon: const Icon(Icons.sos),
              label: Text(_busy ? 'Sending...' : 'Send SOS'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _send('Escort request 🙏'),
              icon: const Icon(Icons.directions_walk),
              label: const Text('Escort Request'),
            ),
          ],
        ),
      ),
    );
  }
}

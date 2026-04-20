// lib/alerts/panic_trigger_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/alert_sender_service.dart';

class PanicTriggerScreen extends StatefulWidget {
  const PanicTriggerScreen({super.key});

  @override
  State<PanicTriggerScreen> createState() => _PanicTriggerScreenState();
}

class _PanicTriggerScreenState extends State<PanicTriggerScreen> {
  final AlertSenderService _sender = AlertSenderService();

  List<String> _contacts = [];
  String _message = 'Emergency!';
  String _method = 'SMS';
  String _search = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('panic_settings')
          .doc(uid)
          .get();

      if (doc.exists) {
        final d = doc.data()!;
        setState(() {
          _contacts = List<String>.from(d['contacts'] ?? const <String>[]);
          _message = (d['defaultMessage'] ?? 'Emergency!').toString();
          _method = (d['method'] ?? 'SMS').toString();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ No panic settings found. Set them in Admin / Panic Settings.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _send() async {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ No contacts to alert.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Use shared helper to build message + location link
      final text = await _sender.composeMessage(
        baseMessage: _message,
        includeLocation: true,
      );

      final m = _method.toLowerCase();

      if (m == 'telegram') {
        // For Telegram Bot we usually send to a single chatId, not per-contact
        await _sender.sendTelegramBot(text);
      } else {
        // SMS / WhatsApp: send per contact
        for (final number in _contacts) {
          if (m == 'sms') {
            await _sender.sendSms(number, text);
          } else if (m == 'whatsapp') {
            await _sender.sendWhatsApp(number, text);
          } else {
            // fallback to SMS
            await _sender.sendSms(number, text);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Emergency alert sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Send failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _contacts
        .where((c) => c.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Trigger Panic Alert')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Recipients'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search contacts...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No contacts. Configure in Panic Settings.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => ListTile(
                              leading: const Icon(Icons.phone),
                              title: Text(filtered[i]),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _send,
                      icon: const Icon(Icons.warning),
                      label: Text(
                        _loading ? 'Sending…' : 'Send Panic Alert',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

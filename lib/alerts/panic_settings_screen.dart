import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PanicSettingsScreen extends StatefulWidget {
  const PanicSettingsScreen({super.key});

  @override
  State<PanicSettingsScreen> createState() => _PanicSettingsScreenState();
}

class _PanicSettingsScreenState extends State<PanicSettingsScreen> {
  final _contactsCtl = TextEditingController();   // comma-separated
  final _messageCtl  = TextEditingController(text: 'SOS 🚨 Please help me.');
  String _method = 'SMS';
  bool _tapTrigger = false;
  bool _powerButtonTrigger = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contactsCtl.dispose();
    _messageCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('panic_settings').doc(uid).get();
      if (doc.exists) {
        final d = doc.data()!;
        final contacts = List<String>.from(d['contacts'] ?? const <String>[]);
        _contactsCtl.text = contacts.join(', ');
        _messageCtl.text  = (d['defaultMessage'] ?? _messageCtl.text).toString();
        _method           = (d['method'] ?? 'SMS').toString();
        _tapTrigger       = (d['tapTrigger'] ?? false) as bool;
        _powerButtonTrigger = (d['powerButtonTrigger'] ?? false) as bool;
      }
    } catch (_) {
      // ignore and fall back to defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in.')));
      return;
    }

    final list = _contactsCtl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one contact.')));
      return;
    }

    await FirebaseFirestore.instance.collection('panic_settings').doc(uid).set({
      'contacts': list,                        // ["whatsapp:+27...", "+27..."]
      'defaultMessage': _messageCtl.text.trim(),
      'method': _method,                       // "SMS" | "WhatsApp" | "Telegram"
      'tapTrigger': _tapTrigger,
      'powerButtonTrigger': _powerButtonTrigger,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panic Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _messageCtl,
                    decoration: const InputDecoration(
                      labelText: 'Default SOS Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactsCtl,
                    decoration: const InputDecoration(
                      labelText: 'Recipients (comma-separated)',
                      helperText: 'Use E.164 (+27…) or whatsapp:+27… e.g. "whatsapp:+27XXXXXXXXX, +27XXXXXXXXX"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'Primary Method'),
                    items: const [
                      DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                      DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
                      DropdownMenuItem(value: 'Telegram', child: Text('Telegram')),
                    ],
                    onChanged: (v) => setState(() => _method = v ?? 'SMS'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _tapTrigger,
                    title: const Text('Trigger via screen tap (x3)'),
                    onChanged: (v) => setState(() => _tapTrigger = v),
                  ),
                  SwitchListTile(
                    value: _powerButtonTrigger,
                    title: const Text('Trigger via power button (x3)'),
                    onChanged: (v) => setState(() => _powerButtonTrigger = v),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

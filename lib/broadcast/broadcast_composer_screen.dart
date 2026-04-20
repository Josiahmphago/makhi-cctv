// lib/broadcast/broadcast_composer_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BroadcastComposerScreen extends StatefulWidget {
  const BroadcastComposerScreen({super.key});

  @override
  State<BroadcastComposerScreen> createState() =>
      _BroadcastComposerScreenState();
}

class _BroadcastComposerScreenState extends State<BroadcastComposerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _areaCtrl = TextEditingController(text: 'Default');

  String _source = 'patrol'; // police | patrol | system | community
  String _severity = 'info'; // info | warning | critical

  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await FirebaseFirestore.instance.collection('broadcasts').add({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'source': _source,
        'severity': _severity,
        'areaId': _areaCtrl.text.trim(),
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Broadcast'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Official Broadcast',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This message will be visible to all users in the selected area.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _messageCtrl,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Area ID',
                      hintText: 'Default',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ✅ FIXED ROW (NO OVERFLOW)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _source,
                          items: const [
                            DropdownMenuItem(
                                value: 'police', child: Text('Police')),
                            DropdownMenuItem(
                                value: 'patrol', child: Text('Patrol')),
                            DropdownMenuItem(
                                value: 'system', child: Text('System / AI')),
                            DropdownMenuItem(
                                value: 'community', child: Text('Community')),
                          ],
                          onChanged: (v) =>
                              setState(() => _source = v ?? _source),
                          decoration: const InputDecoration(
                            labelText: 'Source',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _severity,
                          items: const [
                            DropdownMenuItem(
                                value: 'info', child: Text('Info')),
                            DropdownMenuItem(
                                value: 'warning', child: Text('Warning')),
                            DropdownMenuItem(
                                value: 'critical', child: Text('Critical')),
                          ],
                          onChanged: (v) =>
                              setState(() => _severity = v ?? _severity),
                          decoration: const InputDecoration(
                            labelText: 'Severity',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _severityColor(_severity).withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _severityColor(_severity),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Severity controls how urgent this broadcast appears.',
                            style: TextStyle(
                              color: _severityColor(_severity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_sending ? 'Sending...' : 'Send Broadcast'),
                      onPressed: _sending ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

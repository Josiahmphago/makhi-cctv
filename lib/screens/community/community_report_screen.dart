// lib/screens/community/community_report_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CommunityReportScreen extends StatefulWidget {
  final String areaId;

  const CommunityReportScreen({
    super.key,
    required this.areaId,
  });

  @override
  State<CommunityReportScreen> createState() =>
      _CommunityReportScreenState();
}

class _CommunityReportScreenState
    extends State<CommunityReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();

  String _category = 'General';
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (_) {}

      await FirebaseFirestore.instance
          .collection('community_reports')
          .add({
        'message': _messageCtrl.text.trim(),
        'category': _category,
        'areaId': widget.areaId,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        if (pos != null) ...{
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Report an Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This report will be reviewed by community admins and patrol teams.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(
                      value: 'General', child: Text('General')),
                  DropdownMenuItem(
                      value: 'Illegal Dumping',
                      child: Text('Illegal Dumping')),
                  DropdownMenuItem(
                      value: 'Vandalism',
                      child: Text('Vandalism')),
                  DropdownMenuItem(
                      value: 'Water',
                      child: Text('Water Issue')),
                  DropdownMenuItem(
                      value: 'Electricity',
                      child: Text('Electricity Issue')),
                ],
                onChanged: (v) =>
                    setState(() => _category = v ?? _category),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _messageCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
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
                  label:
                      Text(_sending ? 'Submitting…' : 'Submit Report'),
                  onPressed: _sending ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

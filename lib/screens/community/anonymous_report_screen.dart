import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AnonymousReportScreen extends StatefulWidget {
  final String communityId;
  const AnonymousReportScreen({super.key, required this.communityId});

  @override
  State<AnonymousReportScreen> createState() => _AnonymousReportScreenState();
}

class _AnonymousReportScreenState extends State<AnonymousReportScreen> {
  final _fs = FirebaseFirestore.instance;
  final _st = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  final _text = TextEditingController();
  File? _image;
  bool _anonymous = true;
  bool _sending = false;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty && _image == null) return;
    setState(() => _sending = true);
    try {
      final doc = _fs.collection('reports').doc();
      String? imageUrl;
      if (_image != null) {
        final ref = _st.ref('anonymous_reports/${doc.id}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      await doc.set({
        'text': _text.text.trim().isEmpty ? null : _text.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _anonymous ? null : _auth.currentUser?.uid,
        'anon': _anonymous,
        'communityId': widget.communityId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
        _text.clear();
        setState(() => _image = null);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anonymous Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
            title: const Text('Send anonymously'),
            subtitle: const Text('Only patrol/police/admin can view anonymous details'),
          ),
          TextField(
            controller: _text,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Describe what happened',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Attach photo'),
              ),
              const SizedBox(width: 12),
              if (_image != null) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sending...' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

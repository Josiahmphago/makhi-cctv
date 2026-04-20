import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({super.key});

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _streamUrlController = TextEditingController();
  final _areaController = TextEditingController(text: 'Default');
  final _locationController = TextEditingController();

  String _type = 'street';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _streamUrlController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _normalizeIp(String raw) => raw.trim();
  String _normalizeUrl(String raw) => raw.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final name = _nameController.text.trim();
      final ip = _normalizeIp(_ipController.text);
      final streamUrl = _normalizeUrl(_streamUrlController.text);

      /// Build fallback URL if only IP is provided
      final finalStreamUrl = streamUrl.isNotEmpty
          ? streamUrl
          : (ip.isNotEmpty ? 'http://$ip/' : '');

      /// 📍 GET LOCATION
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      /// ✅ SAVE TO FIRESTORE
      await FirebaseFirestore.instance.collection('cctv_cameras').add({
        'name': name,
        'area': _areaController.text.trim(),
        'locationText': _locationController.text.trim(),
        'type': _type,

        'ipAddress': ip,
        'ipAdress': ip, // legacy support

        'streamUrl': finalStreamUrl,

        /// ✅ CRITICAL FOR MAP
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },

        'isActive': true,

        'ownerId': user.uid,
        'ownerName': user.email ?? '',
        'ownerContact': '',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Camera added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Camera')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// CAMERA NAME
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Camera name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),

              const SizedBox(height: 12),

              /// AREA
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              /// LOCATION TEXT
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (street / house)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              /// TYPE
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(
                      value: 'street', child: Text('Street camera')),
                  DropdownMenuItem(
                      value: 'home', child: Text('Home camera')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'street'),
                decoration: const InputDecoration(
                  labelText: 'Camera type',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              /// IP
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP address',
                  hintText: '192.168.1.10',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              /// STREAM URL
              TextFormField(
                controller: _streamUrlController,
                decoration: const InputDecoration(
                  labelText: 'Stream URL',
                  hintText: 'http://192.168.1.10/',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v == null || v.isEmpty) &&
                      _ipController.text.trim().isEmpty) {
                    return 'Enter IP or Stream URL';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Camera'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
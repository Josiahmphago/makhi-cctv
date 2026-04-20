// lib/screens/add_camera_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({super.key});

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _streamUrlCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _areaCtrl = TextEditingController(text: 'Default');
  final _ownerNameCtrl = TextEditingController();
  final _ownerContactCtrl = TextEditingController();
  final _patrolTeamIdCtrl = TextEditingController();

  String _type = 'street';
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _streamUrlCtrl.dispose();
    _locationCtrl.dispose();
    _areaCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerContactCtrl.dispose();
    _patrolTeamIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final ip = _ipCtrl.text.trim();
      final streamUrl = _streamUrlCtrl.text.trim();
      final location = _locationCtrl.text.trim();
      final area = _areaCtrl.text.trim();
      final ownerName = _ownerNameCtrl.text.trim();
      final ownerContact = _ownerContactCtrl.text.trim();
      final patrolTeamId = _patrolTeamIdCtrl.text.trim();

      // 🔥 Match your existing Firestore structure:
      // area, ipAdress, isActive, location, name, ownerContact, ownerName,
      // patrolTeamId, streamUrl, thumbnailUrl, type
      await FirebaseFirestore.instance.collection('cctv_cameras').add({
        'name': name,
        'area': area.isNotEmpty ? area : 'Default',
        'location': location,
        'type': _type,
        'isActive': _isActive,

        // Keep the existing typo for backwards compatibility
        'ipAdress': ip, // your existing doc uses 'ipAdress'
        'streamUrl': streamUrl,

        'ownerName': ownerName,
        'ownerContact': ownerContact,
        'patrolTeamId': patrolTeamId,

        'thumbnailUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Camera added')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save camera: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Camera'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Camera name',
                  hintText: 'e.g. cam_block_f_street_1',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'IP address (optional)',
                  hintText: 'e.g. 192.168.18.25',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _streamUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stream URL (optional)',
                  hintText: 'e.g. http://192.168.18.25/',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / description',
                  hintText: 'e.g. pta, block F street corner',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area code',
                  hintText: 'e.g. Default / pta / sosh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Camera type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'street',
                    child: Text('Street camera'),
                  ),
                  DropdownMenuItem(
                    value: 'home',
                    child: Text('Home camera'),
                  ),
                  DropdownMenuItem(
                    value: 'business',
                    child: Text('Business camera'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Camera is active'),
                value: _isActive,
                onChanged: (v) {
                  setState(() => _isActive = v);
                },
              ),
              const SizedBox(height: 12),

              ExpansionTile(
                title: const Text('Owner details (optional)'),
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Owner name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ownerContactCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Owner contact (phone/email)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _patrolTeamIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Linked patrol team ID (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

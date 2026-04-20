import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CameraConfigScreen extends StatefulWidget {
  const CameraConfigScreen({super.key});

  @override
  State<CameraConfigScreen> createState() => _CameraConfigScreenState();
}

class _CameraConfigScreenState extends State<CameraConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController tokenController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerContactController = TextEditingController();

  bool isLoading = false;

  Future<void> saveCameraConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = tokenController.text.trim();
      final docRef = FirebaseFirestore.instance.collection('cctv_cameras').doc(token);

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera with this token already exists!')),
        );
        setState(() => isLoading = false);
        return;
      }

      await docRef.set({
        'location': locationController.text.trim(),
        'type': typeController.text.trim(),
        'isActive': true,
        'patrolTeamId': '', // Add logic later to link team
        'owner': {
          'name': ownerNameController.text.trim(),
          'contact': ownerContactController.text.trim(),
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera configuration saved!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure ESP32-CAM')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Camera Token'),
                validator: (value) => value!.isEmpty ? 'Enter token' : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location / Address'),
                validator: (value) => value!.isEmpty ? 'Enter location' : null,
              ),
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Camera Type (home/street)'),
                validator: (value) => value!.isEmpty ? 'Enter type' : null,
              ),
              TextFormField(
                controller: ownerNameController,
                decoration: const InputDecoration(labelText: 'Owner Name'),
              ),
              TextFormField(
                controller: ownerContactController,
                decoration: const InputDecoration(labelText: 'Owner Contact'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Save Configuration'),
                onPressed: isLoading ? null : saveCameraConfiguration,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

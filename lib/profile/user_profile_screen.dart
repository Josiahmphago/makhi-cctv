import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _fullNameController.text = data['fullName'] ?? '';
      _phoneController.text = data['phoneNumber'] ?? '';
      _bloodTypeController.text = data['bloodType'] ?? '';
      _allergiesController.text = data['allergies'] ?? '';
      _conditionsController.text = data['medicalConditions'] ?? '';
      _noteController.text = data['emergencyNote'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'bloodType': _bloodTypeController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'medicalConditions': _conditionsController.text.trim(),
      'emergencyNote': _noteController.text.trim(),
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Profile saved successfully')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter your name' : null,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.phone,
                      ),
                      TextFormField(
                        controller: _bloodTypeController,
                        decoration:
                            const InputDecoration(labelText: 'Blood Type (e.g. O+)'),
                      ),
                      TextFormField(
                        controller: _allergiesController,
                        decoration:
                            const InputDecoration(labelText: 'Allergies'),
                      ),
                      TextFormField(
                        controller: _conditionsController,
                        decoration: const InputDecoration(
                            labelText: 'Medical Conditions'),
                      ),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                            labelText: 'Emergency Note / Extra Info'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

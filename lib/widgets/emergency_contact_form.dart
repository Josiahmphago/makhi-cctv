import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';

class EmergencyContactForm extends StatefulWidget {
  final EmergencyContact? existing;

  const EmergencyContactForm({super.key, this.existing});

  @override
  State<EmergencyContactForm> createState() => _EmergencyContactFormState();
}

class _EmergencyContactFormState extends State<EmergencyContactForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _noteController;
  String? _priority;
  String? _relationshipType;
  String? _group;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.existing?.phoneNumber ?? '');
    _noteController =
        TextEditingController(text: widget.existing?.note ?? '');
    _priority = widget.existing?.priority;
    _relationshipType = widget.existing?.relationshipType;
    _group = widget.existing?.group;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Contact' : 'Edit Contact'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['High', 'Medium', 'Low']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _priority = val),
              ),
              DropdownButtonFormField<String>(
                value: _relationshipType,
                decoration: const InputDecoration(labelText: 'Relationship Type'),
                items: ['Family', 'Friend', 'Neighbor', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => _relationshipType = val),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Group (optional)'),
                initialValue: _group,
                onChanged: (val) => _group = val,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final contact = EmergencyContact(
                id: widget.existing?.id ?? '',
                name: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                note: _noteController.text.trim(),
                priority: _priority,
                relationshipType: _relationshipType,
                group: _group,
                ownerId: widget.existing?.ownerId ?? '',
              );
              Navigator.pop(context, contact);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';

class ManageEmergencyContactsScreen extends StatelessWidget {
  final String ownerId;
  final EmergencyContactService _service = EmergencyContactService();

  ManageEmergencyContactsScreen({super.key, required this.ownerId});

  void _showContactDialog(BuildContext context, {EmergencyContact? contact}) {
    final nameCtrl = TextEditingController(text: contact?.name ?? '');
    final phoneCtrl = TextEditingController(text: contact?.phoneNumber ?? '');
    final noteCtrl = TextEditingController(text: contact?.note ?? '');
    final priorityCtrl = TextEditingController(text: contact?.priority ?? '');
    final relationCtrl =
        TextEditingController(text: contact?.relationshipType ?? '');
    final groupCtrl = TextEditingController(text: contact?.group ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number')),
              TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note')),
              TextField(
                  controller: priorityCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Priority (e.g. High)')),
              TextField(
                  controller: relationCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Relationship')),
              TextField(
                  controller: groupCtrl,
                  decoration: const InputDecoration(labelText: 'Group')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newContact = EmergencyContact(
                id: contact?.id ?? '',
                name: nameCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
                note: noteCtrl.text.trim(),
                priority: priorityCtrl.text.trim(),
                relationshipType: relationCtrl.text.trim(),
                group: groupCtrl.text.trim(),
                ownerId: ownerId,
              );

              if (contact == null) {
                await _service.addContact(newContact, ownerId);
              } else {
                await _service.updateContact(newContact, contact.id, ownerId);
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Emergency Contacts')),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _service.getContacts(ownerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data!;
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No contacts yet.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Default Contact'),
                    onPressed: () async {
                      final defaultContact = EmergencyContact(
                        id: '',
                        name: 'Police Station',
                        phoneNumber: '+27831234567',
                        note: 'Default emergency contact',
                        priority: 'High',
                        relationshipType: 'Emergency',
                        group: 'Community',
                        ownerId: ownerId,
                      );
                      await _service.addContact(defaultContact, ownerId);
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, i) {
              final c = contacts[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text(c.phoneNumber),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showContactDialog(context, contact: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _service.deleteContact(c.id, ownerId);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

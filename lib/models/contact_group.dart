import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactGroupsScreen extends StatefulWidget {
  const ContactGroupsScreen({Key? key}) : super(key: key);

  @override
  State<ContactGroupsScreen> createState() => _ContactGroupsScreenState();
}

class _ContactGroupsScreenState extends State<ContactGroupsScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Groups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('contact_groups')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading groups'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No groups found.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c,i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed';
              final members = (data['members'] as List<dynamic>?)
                      ?.cast<Map<String,String>>() ?? [];
              return ListTile(
                title: Text(name),
                subtitle: Text('Members: ${members.map((m)=>m['name']).join(', ')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _pickContacts(groupId: doc.id, existing: members),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickContacts({
    required String groupId,
    required List<Map<String,String>> existing,
  }) async {
    if (!await FlutterContacts.requestPermission()) return;
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final existingPhones = existing.map((e)=>e['phone']).toSet();
    final selectedPhones = <String>{};
    final Map<String, String> selected = {};

    final filtered = List.of(contacts);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setState2) {
          return AlertDialog(
            title: const Text('Add Members'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Search'),
                  onChanged: (q) {
                    setState2(() {
                      filtered.retainWhere((c) {
                        final name = c.displayName.toLowerCase();
                        final phones = c.phones.map((p)=>p.number).join(' ').toLowerCase();
                        return name.contains(q.toLowerCase()) || phones.contains(q.toLowerCase());
                      });
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (c,i) {
                      final contact = filtered[i];
                      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                      final label = '${contact.displayName} • $phone';
                      final isExisting = existingPhones.contains(phone);
                      final isSelected = selectedPhones.contains(phone);

                      return CheckboxListTile(
                        title: Text(label),
                        value: isExisting || isSelected,
                        onChanged: isExisting ? null : (val) {
                          setState2((){
                            if (val==true) {
                              selectedPhones.add(phone);
                              selected[phone] = contact.displayName;
                            } else {
                              selectedPhones.remove(phone);
                              selected.remove(phone);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedPhones.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Select at least one')),
                    );
                    return;
                  }
                  // prepare new combined member list
                  final all = List<Map<String,String>>.from(existing)
                    ..addAll(selectedPhones.map((ph) => {'name': selected[ph]!, 'phone':ph}));
                  await _firestore.collection('contact_groups').doc(groupId).update({
                    'members': all,
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      }
    );
  }
}

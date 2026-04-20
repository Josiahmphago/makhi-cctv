import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactGroupsScreen extends StatefulWidget {
  const ContactGroupsScreen({super.key});

  @override
  State<ContactGroupsScreen> createState() => _ContactGroupsScreenState();
}

class _ContactGroupsScreenState extends State<ContactGroupsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _purgeExpiredDeletedGroups();
  }

  Future<void> _purgeExpiredDeletedGroups() async {
    final thirtyDaysAgo =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
    final expired = await _firestore
        .collection('contact_groups')
        .where('deletedAt', isLessThanOrEqualTo: thirtyDaysAgo)
        .get();

    for (var doc in expired.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Groups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('contact_groups')
            .where('deletedAt', isNull: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No groups found.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed';
              final members = (data['members'] as List<dynamic>)
                  .map((m) => "${m['name']} - ${m['phone']} [${m['tag'] ?? ''}]")
                  .join('\n');

              return ListTile(
                title: Text(name),
                subtitle: Text(members),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showGroupDialog(editDocId: doc.id, existingData: data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _softDeleteGroup(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _softDeleteGroup(String docId) async {
    await _firestore.collection('contact_groups').doc(docId).update({
      'deletedAt': Timestamp.now(),
    });
  }

  void _showGroupDialog({String? editDocId, Map<String, dynamic>? existingData}) {
    final nameController = TextEditingController(text: existingData?['name'] ?? '');

    List<MemberField> memberFields = existingData != null
        ? (existingData['members'] as List)
            .map((m) => MemberField(
                  name: m['name'],
                  phone: m['phone'],
                  tag: m['tag'] ?? '',
                ))
            .toList()
        : [MemberField()];

    final predefinedTags = [
      'Family',
      'Neighbour',
      'Police',
      'Responder',
      'Volunteer',
      'Trusted',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editDocId != null ? 'Edit Group' : 'New Contact Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                ),
                const SizedBox(height: 10),
                ...memberFields.map((field) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: field.nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: field.phoneController,
                              decoration: const InputDecoration(labelText: 'Phone'),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        value: predefinedTags.contains(field.tag) ? field.tag : null,
                        items: predefinedTags
                            .map((tag) =>
                                DropdownMenuItem(value: tag, child: Text(tag)))
                            .toList(),
                        onChanged: (val) {
                          if (val == 'Other') {
                            showDialog(
                              context: context,
                              builder: (_) {
                                final otherController = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Enter custom tag'),
                                  content: TextField(controller: otherController),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          field.tag = otherController.text.trim();
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    )
                                  ],
                                );
                              },
                            );
                          } else {
                            setState(() => field.tag = val ?? '');
                          }
                        },
                        hint: const Text('Select Tag'),
                      ),
                      const Divider(),
                    ],
                  );
                }),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => memberFields.add(MemberField()));
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                final validMembers = memberFields
                    .map((f) => {
                          'name': f.nameController.text.trim(),
                          'phone': f.phoneController.text.trim(),
                          'tag': f.tag,
                        })
                    .where((m) =>
                        m['name']!.isNotEmpty && m['phone']!.isNotEmpty)
                    .toList();

                if (name.isEmpty || validMembers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Provide name and at least one member.'),
                  ));
                  return;
                }

                final phoneSet = <String>{};
                final duplicatePhones = validMembers
                    .where((m) => !phoneSet.add(m['phone']!))
                    .toList();
                if (duplicatePhones.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Duplicate phone numbers within the group.'),
                  ));
                  return;
                }

                final newMemberPhones =
                    validMembers.map((m) => m['phone']).toSet();

                final existingGroups = await _firestore
                    .collection('contact_groups')
                    .where('name', isEqualTo: name)
                    .where('deletedAt', isNull: true)
                    .get();

                final isDuplicate = existingGroups.docs.any((doc) {
                  if (editDocId != null && doc.id == editDocId) return false;
                  final existingPhones = (doc.data()['members'] as List)
                      .map((e) => e['phone'])
                      .toSet();
                  return existingPhones.length == newMemberPhones.length &&
                      existingPhones.containsAll(newMemberPhones);
                });

                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('A group with the same name and members already exists.'),
                  ));
                  return;
                }

                final groupData = {
                  'name': name,
                  'members': validMembers,
                  'createdAt': Timestamp.now(),
                  'deletedAt': null,
                };

                if (editDocId != null) {
                  await _firestore.collection('contact_groups').doc(editDocId).update(groupData);
                } else {
                  await _firestore.collection('contact_groups').add(groupData);
                }

                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ This is the missing class that must be defined at the bottom
class MemberField {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  String tag;

  MemberField({String name = '', String phone = '', this.tag = ''})
      : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone);
}

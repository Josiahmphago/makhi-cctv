// lib/group/groups_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/group_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _fs = FirebaseFirestore.instance;
  final _ctrl = TextEditingController();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _createGroup() async {
    final uid = _uid;
    final name = _ctrl.text.trim();
    if (uid == null || name.isEmpty) return;

    final doc = await _fs.collection('groups').add({
      'name': name,
      'ownerId': uid,
      'memberIds': [uid],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _ctrl.clear();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: doc.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final q = _fs
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Groups")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: "New group name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createGroup,
                  child: const Text("Create"),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No groups yet."));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name = (data['name'] ?? 'Group').toString();
                    final ownerId = (data['ownerId'] ?? '').toString();
                    final isOwner = ownerId == uid;

                    return ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(name),
                      subtitle: Text(isOwner ? 'Owner' : 'Member'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupDetailScreen(groupId: d.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   👇 THIS IS GroupDetailScreen (YOU WERE LOOKING FOR THIS)
   ============================================================ */
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _fs = FirebaseFirestore.instance;
  final _service = GroupService();
  final _addCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final docRef = _fs.collection('groups').doc(widget.groupId);

    return Scaffold(
      appBar: AppBar(title: const Text('Group')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data();
          if (data == null) {
            return const Center(child: Text('Group not found'));
          }

          /// ✅ ALWAYS READ NAME
          final groupName = (data['name'] ?? 'Unnamed Group').toString();
          final ownerId = data['ownerId'] as String?;
          final members = List<String>.from(data['memberIds'] ?? []);
          final isOwner = uid == ownerId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// GROUP NAME
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              /// MEMBERS
              Text(
                'Members (${members.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              ...members.map((memberId) {
                final isMe = memberId == uid;

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      isMe ? 'You' : memberId,
                      style: isMe
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : null,
                    ),
                    subtitle: Text(
                      memberId == ownerId
                          ? 'Owner'
                          : isMe
                              ? 'Member (this is you)'
                              : 'Member',
                    ),

                    /// ACTIONS
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// MEMBER LEAVES GROUP
                        if (isMe)
                          TextButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Leave'),
                            onPressed: () async {
                              await _service.leaveGroup(
                                widget.groupId,
                                uid,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),

                        /// OWNER REMOVES MEMBER
                        if (isOwner && !isMe)
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            tooltip: 'Remove member',
                            onPressed: () async {
                              await _service.removeMember(
                                groupId: widget.groupId,
                                memberId: memberId,
                                ownerId: ownerId!,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              /// OWNER ADD MEMBER
              if (isOwner) ...[
                const Text(
                  'Add member (UID / phone / email)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Paste UID / phone / email',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final raw = _addCtrl.text.trim();
                        if (raw.isEmpty) return;

                        await docRef.update({
                          'memberIds': FieldValue.arrayUnion([raw]),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        _addCtrl.clear();
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// lib/screens/admin/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _testWrite(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final u = auth.currentUser;

    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('test_write').add({
        'uid': u.uid,
        'isAnonymous': u.isAnonymous,
        'email': u.email,
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'AdminScreen test write',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ test_write succeeded (rules/auth OK).')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ test_write failed: $e')),
      );
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _myUserDocStream(User? me) {
    if (me == null) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(me.uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin / Roles'),
        actions: [
          IconButton(
            tooltip: 'Directory Admin (Police / Patrol / Teams)',
            icon: const Icon(Icons.apartment),
            onPressed: () => Navigator.pushNamed(context, '/admin/directory'),
          ),
          IconButton(
            tooltip: 'Seed demo directory data',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () => Navigator.pushNamed(context, '/admin/seed'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _myUserDocStream(me),
        builder: (context, mySnap) {
          final myData = mySnap.data?.data() ?? {};
          final myRoles = Map<String, dynamic>.from(myData['roles'] ?? {});
          final isAdmin = myRoles['admin'] == true;

          final uid = me?.uid ?? '(not signed in)';
          final who = (me == null)
              ? 'Not signed in'
              : (me.isAnonymous ? 'Anonymous user' : (me.email ?? 'Signed-in user'));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ----------------- My session status -----------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your current session',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('UID: $uid'),
                      Text('Account: $who'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(isAdmin ? 'Admin: YES' : 'Admin: NO'),
                            backgroundColor:
                                isAdmin ? Colors.green.shade100 : Colors.orange.shade100,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAdmin
                                  ? 'You can manage users + directory tools.'
                                  : 'You cannot list users until roles.admin=true in /users/$uid.',
                              style: TextStyle(
                                color: isAdmin ? Colors.green.shade700 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: me == null ? null : () => _testWrite(context),
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Test write (test_write)'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/admin/directory'),
                            icon: const Icon(Icons.apartment),
                            label: const Text('Directory Admin'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/admin/seed'),
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Seed Demo Data'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (me != null && me.isAnonymous)
                        Text(
                          '⚠️ You are using anonymous auth. If you uninstall / clear app data / change device, your UID changes and your admin role will look “gone”.\n'
                          'Fix: create real login (email/phone) or re-assign admin to the current UID.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ----------------- If NOT admin, do NOT query users -----------------
              if (!isAdmin)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Users & Roles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You are not admin yet, so the app will not list users (it would trigger PERMISSION_DENIED).\n\n'
                          'To make this device admin:\n'
                          '1) Open Firebase Console → Firestore → users → create/update document with ID = your UID\n'
                          '2) Set roles.admin = true\n'
                          '3) Restart the app',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your UID:\n$uid',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),

              // ----------------- Admin-only users list -----------------
              if (isAdmin) ...[
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Users & Roles',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                _UsersList(isMeUid: me?.uid),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  final String? isMeUid;
  const _UsersList({required this.isMeUid});

  @override
  Widget build(BuildContext context) {
    final usersQ = FirebaseFirestore.instance.collection('users').limit(200);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersQ.snapshots(),
      builder: (context, s) {
        if (s.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error loading users: ${s.error}'),
          );
        }
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = s.data!.docs;

        return Column(
          children: docs.map((doc) {
            final d = doc.data();
            final roles = Map<String, dynamic>.from(d['roles'] ?? {});
            final roleStr = roles.keys.where((k) => roles[k] == true).join(', ');

            final isMe = (isMeUid != null && doc.id == isMeUid);

            final displayName = (d['displayName'] ?? d['name'] ?? doc.id).toString();

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(isMe ? Icons.person : Icons.people),
                ),
                title: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  (roleStr.isEmpty ? 'No roles' : roleStr) +
                      (isMe ? '  •  (THIS DEVICE USER)' : ''),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _RoleEditor(docId: doc.id, roles: roles),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RoleEditor extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> roles;
  const _RoleEditor({required this.docId, required this.roles});

  @override
  State<_RoleEditor> createState() => _RoleEditorState();
}

class _RoleEditorState extends State<_RoleEditor> {
  final keys = const ['community', 'patrol', 'escort', 'towing', 'admin'];
  late Map<String, bool> local;

  @override
  void initState() {
    super.initState();
    local = {for (final k in keys) k: (widget.roles[k] == true)};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Roles'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in keys)
              SwitchListTile(
                title: Text(k),
                value: local[k] ?? false,
                onChanged: (v) => setState(() => local[k] = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.docId)
                .set({'roles': local}, SetOptions(merge: true));

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

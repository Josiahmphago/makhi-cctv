import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users').limit(100);

    return Scaffold(
      appBar: AppBar(
        title: const Text("👮 Admin Console"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: users.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final roles = Map<String, dynamic>.from(data['roles'] ?? {});
              final email = data['email'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(data['displayName'] ?? doc.id),
                  subtitle: Text(
                    roles.entries
                        .where((e) => e.value == true)
                        .map((e) => e.key)
                        .join(', ')
                        .isEmpty
                        ? "No roles assigned"
                        : roles.entries
                            .where((e) => e.value == true)
                            .map((e) => e.key)
                            .join(', '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (choice) async {
                      if (choice == 'roles') {
                        showDialog(
                          context: context,
                          builder: (_) => _RoleEditor(
                            docId: doc.id,
                            roles: roles,
                          ),
                        );
                      } else if (choice == 'reset') {

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User has no email registered")),
    );
    return;
  }

  try {

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.trim(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reset link sent to $email"),
        ),
      );
    }

  } catch (e) {

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset failed: $e"),
        ),
      );
    }

  }
} else if (choice == 'delete') {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(doc.id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("User ${doc.id} removed")),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'roles', child: Text('Edit Roles')),
                      if (email.isNotEmpty)
                        const PopupMenuItem(
                            value: 'reset', child: Text('Reset Password')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Remove User')),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
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
    local = {
      for (final k in keys) k: (widget.roles[k] == true),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Roles"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((k) {
          return SwitchListTile(
            title: Text(k),
            value: local[k]!,
            onChanged: (v) => setState(() => local[k] = v),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.docId)
                .set({'roles': local}, SetOptions(merge: true));

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleManagementScreen extends StatelessWidget {
  const RoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Role Management"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final roles = Map<String, dynamic>.from(
                data['roles'] ?? {},
              );

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        doc.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _roleSwitch(doc.id, "community", roles),
                      _roleSwitch(doc.id, "patrol", roles),
                      _roleSwitch(doc.id, "escort", roles),
                      _roleSwitch(doc.id, "police", roles),
                      _roleSwitch(doc.id, "admin", roles),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _roleSwitch(
      String uid,
      String role,
      Map<String, dynamic> roles,
      ) {

    final value = roles[role] == true;

    return StatefulBuilder(
      builder: (context, setState) {

        return SwitchListTile(
          title: Text(role),
          value: value,
          onChanged: (v) async {

            roles[role] = v;

            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({
              'roles': roles,
            });

            setState(() {});
          },
        );
      },
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManagePatrolAgentsScreen extends StatefulWidget {
  const ManagePatrolAgentsScreen({super.key});

  @override
  State<ManagePatrolAgentsScreen> createState() => _ManagePatrolAgentsScreenState();
}

class _ManagePatrolAgentsScreenState extends State<ManagePatrolAgentsScreen> {
  final _name = TextEditingController();
  final _areaId = TextEditingController(text: 'Default');

  bool _enabled = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _areaId.dispose();
    super.dispose();
  }

  Future<void> _registerMeAsAgent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final name = _name.text.trim().isEmpty ? 'Agent' : _name.text.trim();
    final areaId = _areaId.text.trim().isEmpty ? 'Default' : _areaId.text.trim();

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('patrol_agents').doc(uid).set({
        'enabled': _enabled,
        'name': name,
        'onDuty': false,
        'areaId': areaId,
        'areas': [areaId],
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('patrol_agents').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Patrol Agents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Agent name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _areaId,
                  decoration: const InputDecoration(labelText: 'AreaId', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  value: _enabled,
                  onChanged: _saving ? null : (v) => setState(() => _enabled = v),
                ),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _registerMeAsAgent,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_add),
                    label: const Text('Register current user as Patrol Agent'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No patrol agents yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text((data['name'] ?? d.id).toString()),
                      subtitle: Text('areaId: ${(data['areaId'] ?? '').toString()} • onDuty: ${data['onDuty'] == true}'),
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

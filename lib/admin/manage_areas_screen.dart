import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAreasScreen extends StatefulWidget {
  const ManageAreasScreen({super.key});

  @override
  State<ManageAreasScreen> createState() => _ManageAreasScreenState();
}

class _ManageAreasScreenState extends State<ManageAreasScreen> {
  final _name = TextEditingController();
  bool _enabled = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final n = _name.text.trim();
    if (n.isEmpty) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('areas').add({
        'name': n,
        'enabled': _enabled,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _name.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(String id, bool v) async {
    await FirebaseFirestore.instance.collection('areas').doc(id).update({'enabled': v});
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('areas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('areas').orderBy('name').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Areas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Area name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        value: _enabled,
                        onChanged: _saving ? null : (v) => setState(() => _enabled = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _add,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
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
                if (docs.isEmpty) return const Center(child: Text('No areas yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name = (data['name'] ?? d.id).toString();
                    final enabled = data['enabled'] == true;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(d.id),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          Switch(
                            value: enabled,
                            onChanged: (v) => _toggle(d.id, v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _delete(d.id),
                          ),
                        ],
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

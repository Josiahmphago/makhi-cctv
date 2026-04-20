import 'package:flutter/material.dart';
import '../models/alert_group.dart';
import '../services/alert_group_service.dart';
import 'assign_group_contacts_screen.dart';

class ManageAlertGroupsScreen extends StatefulWidget {
  const ManageAlertGroupsScreen({super.key});

  @override
  State<ManageAlertGroupsScreen> createState() => _ManageAlertGroupsScreenState();
}

class _ManageAlertGroupsScreenState extends State<ManageAlertGroupsScreen> {
  final _svc = AlertGroupService();
  bool _savingOrder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Alert Groups'),
        actions: [
          IconButton(
            tooltip: 'Add Group',
            icon: const Icon(Icons.add),
            onPressed: () => _openGroupEditor(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AlertGroup>>(
        stream: _svc.streamGroups(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return const Center(child: Text('No groups yet. Tap + to add.'));
          }

          return Column(
            children: [
              if (_savingOrder)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: groups.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final updated = List<AlertGroup>.from(groups);
                    final item = updated.removeAt(oldIndex);
                    updated.insert(newIndex, item);

                    setState(() => _savingOrder = true);
                    for (int i = 0; i < updated.length; i++) {
                      await _svc.upsertGroup(updated[i].copyWith(priority: i + 1));
                    }
                    setState(() => _savingOrder = false);
                  },
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    final label = "${g.emoji ?? ''} ${g.name}".trim();
                    return Card(
                      key: ValueKey(g.id),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (g.numbers.isNotEmpty) Wrap(
                              spacing: 6, runSpacing: -6,
                              children: g.numbers.map((n) => Chip(label: Text(n))).toList(),
                            ),
                            if (g.teams.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: g.teams.map((t) => Chip(label: Text("${t.name} (${t.numbers.length})"))).toList(),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Assign Contacts',
                              icon: const Icon(Icons.group_add),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignGroupContactsScreen(preselectedGroup: g),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openGroupEditor(context, existing: g),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(context, g),
                            ),

                            PopupMenuButton<String>(
                               onSelected: (v) async {
                              if (v == 'import') {
                             final written = await _svc.importLegacyOnce();
                            if (!mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Imported $written groups from legacy data.')),
                   );
             }
         },
                             itemBuilder: (_) => const [
                            PopupMenuItem(value: 'import', child: Text('Import legacy groups')),
         ],
          ),

                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  'Tip: Drag the handle to reorder (sets priority). Numbers should be in E.164 format, e.g. +27123456789.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AlertGroup g) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text('This will remove "${g.name}". Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await _svc.deleteGroup(g.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${g.name}".')));
      }
    }
  }

  Future<void> _openGroupEditor(BuildContext context, {AlertGroup? existing}) async {
    final idController = TextEditingController(text: existing?.id ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emojiController = TextEditingController(text: existing?.emoji ?? '');
    final numbersController = TextEditingController(
      text: (existing?.numbers ?? []).join('\n'),
    );
    final priorityController = TextEditingController(
      text: (existing?.priority ?? 99).toString(),
    );

    final isNew = existing == null;

    await showDialog(
      context: context,
      builder: (_) {
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text(isNew ? 'Add Group' : 'Edit Group'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isNew)
                      TextFormField(
                        controller: idController,
                        decoration: const InputDecoration(
                          labelText: 'Group ID (e.g., police, patrol, family)',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final ok = RegExp(r'^[a-z0-9_\-]+$').hasMatch(v);
                          if (!ok) return 'Use lowercase letters, numbers, hyphen/underscore';
                          return null;
                        },
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name (e.g., Police)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emojiController,
                      decoration: const InputDecoration(labelText: 'Emoji (optional)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: numbersController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Numbers (one per line, E.164 like +27123456789)',
                        alignLabelWithHint: true,
                      ),
                      minLines: 5,
                      maxLines: 8,
                      validator: (v) {
                        final lines = (v ?? '').split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
                        if (lines.isEmpty) return 'At least one number required';
                        for (final n in lines) {
                          if (!RegExp(r'^\+?[1-9]\d{6,15}$').hasMatch(n)) {
                            return 'Invalid number: $n';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priorityController,
                      decoration: const InputDecoration(labelText: 'Priority (1 = highest)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final id = isNew ? idController.text.trim() : existing!.id;
                final name = nameController.text.trim();
                final emoji = emojiController.text.trim().isEmpty ? null : emojiController.text.trim();
                final nums = numbersController.text
                    .split('\n')
                    .map((e) => e.trim().replaceAll(' ', ''))
                    .where((e) => e.isNotEmpty)
                    .toList();
                final pr = int.tryParse(priorityController.text.trim()) ?? (existing?.priority ?? 99);

                final g = AlertGroup(id: id, name: name, numbers: nums, emoji: emoji, priority: pr);
                await _svc.upsertGroup(g);

                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isNew ? 'Group "$name" added.' : 'Group "$name" updated.')),
                  );
                }
              },
              child: Text(isNew ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

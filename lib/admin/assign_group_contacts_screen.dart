import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alert_group.dart';
import '../services/alert_group_service.dart';

class AssignGroupContactsScreen extends StatefulWidget {
  final AlertGroup? preselectedGroup;
  const AssignGroupContactsScreen({super.key, this.preselectedGroup});

  @override
  State<AssignGroupContactsScreen> createState() => _AssignGroupContactsScreenState();
}

class _AssignGroupContactsScreenState extends State<AssignGroupContactsScreen> {
  final _svc = AlertGroupService();

  AlertGroup? _selectedGroup;
  String _selectedScope = 'All Group'; // or team/shift name
  final TextEditingController _manualNumbersCtrl = TextEditingController();

  List<Contact> _allContacts = [];
  List<Contact> _filtered = [];
  final Set<Contact> _picked = {};

  String _search = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Preselect group if provided
    _selectedGroup = widget.preselectedGroup;

    // Load contacts (request permission)
    if (await FlutterContacts.requestPermission(readonly: true)) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _allContacts = contacts;
        _filtered = contacts;
      });
    }
    setState(() {}); // ensure rebuild to reflect preselected group
  }

  void _filter(String q) {
    _search = q;
    final norm = q.toLowerCase().replaceAll(' ', '');
    setState(() {
      _filtered = _allContacts.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(q.toLowerCase());
        final phone = c.phones.isNotEmpty ? c.phones.first.number.replaceAll(' ', '') : '';
        final phoneMatch = phone.contains(norm);
        return nameMatch || phoneMatch;
      }).toList();
    });
  }

  List<String> _collectNumbers() {
    final fromContacts = _picked
        .where((c) => c.phones.isNotEmpty)
        .map((c) => c.phones.first.number.replaceAll(' ', ''))
        .toList();

    final fromManual = _manualNumbersCtrl.text
        .split('\n')
        .map((e) => e.trim().replaceAll(' ', ''))
        .where((e) => e.isNotEmpty)
        .toList();

    // Merge unique
    final merged = {...fromContacts, ...fromManual}.toList();
    return merged;
  }

  Future<void> _save() async {
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group first.')),
      );
      return;
    }

    final numbers = _collectNumbers();
    if (numbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick contacts or enter numbers to assign.')),
      );
      return;
    }

    setState(() => _loading = true);

    // Fetch latest version of group
    final groups = await _svc.fetchOnce();
    final current = groups.firstWhere(
      (g) => g.id == _selectedGroup!.id,
      orElse: () => _selectedGroup!,
    );

    if (_selectedScope == 'All Group') {
      final updated = current.copyWith(numbers: numbers);
      await _svc.upsertGroup(updated);
    } else {
      // Update or insert the team by name
      final teams = List<GroupTeam>.from(current.teams);
      final i = teams.indexWhere((t) => t.name == _selectedScope);
      if (i >= 0) {
        teams[i] = GroupTeam(name: teams[i].name, numbers: numbers);
      } else {
        teams.add(GroupTeam(name: _selectedScope, numbers: numbers));
      }
      final updated = current.copyWith(teams: teams);
      await _svc.upsertGroup(updated);
    }

    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group contacts saved.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Group Contacts'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select group from Firestore
            StreamBuilder<List<AlertGroup>>(
              stream: _svc.streamGroups(),
              builder: (context, snap) {
                final groups = snap.data ?? [];
                // Initialize selection if none
                if (_selectedGroup == null && groups.isNotEmpty) {
                  _selectedGroup = groups.first;
                }

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGroup?.id,
                        items: groups
                            .map((g) => DropdownMenuItem(
                                  value: g.id,
                                  child: Text('${g.emoji ?? ''} ${g.name}'.trim()),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedGroup = groups.firstWhere((x) => x.id == v);
                            _selectedScope = 'All Group';
                            _picked.clear();
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Group'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (snap.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            // Select scope: All Group or a specific team/shift, plus create new
            if (_selectedGroup != null)
              Builder(
                builder: (_) {
                  final teams = _selectedGroup!.teams.map((t) => t.name).toList();
                  final scopes = ['All Group', ...teams, '➕ Create New Team…'];
                  return DropdownButtonFormField<String>(
                    value: _selectedScope,
                    items: scopes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) async {
                      if (v == '➕ Create New Team…') {
                        final created = await _promptCreateTeam();
                        if (created != null && created.isNotEmpty) {
                          setState(() => _selectedScope = created);
                        }
                        return;
                      }
                      setState(() => _selectedScope = v ?? 'All Group');
                    },
                    decoration: const InputDecoration(labelText: 'Assign To'),
                  );
                },
              ),

            const SizedBox(height: 12),

            // Search
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search contacts',
                border: OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),

            const SizedBox(height: 8),

            // Contacts with checkboxes
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No contacts'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final hasPhone = c.phones.isNotEmpty;
                        final selected = _picked.contains(c);
                        return CheckboxListTile(
                          title: Text(c.displayName),
                          subtitle: hasPhone
                              ? Text(c.phones.first.number)
                              : const Text('No phone'),
                          value: selected,
                          onChanged: hasPhone
                              ? (v) {
                                  setState(() {
                                    if (v == true) {
                                      _picked.add(c);
                                    } else {
                                      _picked.remove(c);
                                    }
                                  });
                                }
                              : null,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),

            // Manual numbers
            TextField(
              controller: _manualNumbersCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Add numbers manually (one per line, E.164 like +27123456789)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptCreateTeam() async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Team/Shift Name'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'e.g. Day Shift, Night Shift, Sector 2'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Create')),
        ],
      ),
    );
  }
}

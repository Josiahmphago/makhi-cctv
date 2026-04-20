// lib/screens/admin/directory_admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/directory_admin_service.dart';

class DirectoryAdminScreen extends StatefulWidget {
  const DirectoryAdminScreen({super.key});

  @override
  State<DirectoryAdminScreen> createState() => _DirectoryAdminScreenState();
}

class _DirectoryAdminScreenState extends State<DirectoryAdminScreen> {
  final _svc = DirectoryAdminService();

  String _collection = 'police_stations';

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('name')
        .limit(200);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory Admin'),
        actions: [
          IconButton(
            tooltip: 'Add entry',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => _DirectoryEntryDialog(
                  collection: _collection,
                  svc: _svc,
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          _collectionPicker(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.snapshots(),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = s.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No entries yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final d = doc.data();

                    final enabled = d['enabled'] != false;
                    final phone = (d['phoneNumber'] ?? d['phone'] ?? '').toString();
                    final st = (d['serviceType'] ?? '').toString();

                    final loc = (d['location'] is Map) ? (d['location'] as Map) : {};
                    final lat = loc['lat'];
                    final lng = loc['lng'];
                    final geo = (loc['geohash'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        title: Text((d['name'] ?? doc.id).toString()),
                        subtitle: Text(
                          [
                            if (st.isNotEmpty) 'Type: $st',
                            if (phone.isNotEmpty) 'Phone: $phone',
                            'Enabled: $enabled',
                            if (lat != null && lng != null) 'Loc: $lat, $lng',
                            if (geo.isNotEmpty) 'Geo: $geo',
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await showDialog(
                                context: context,
                                builder: (_) => _DirectoryEntryDialog(
                                  collection: _collection,
                                  svc: _svc,
                                  docId: doc.id,
                                  initial: d,
                                ),
                              );
                            }
                            if (v == 'toggle') {
                              await _svc.setEnabled(
                                collection: _collection,
                                docId: doc.id,
                                enabled: !enabled,
                              );
                            }
                            if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete entry?'),
                                      content: const Text('This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (ok) {
                                await _svc.delete(collection: _collection, docId: doc.id);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(enabled ? 'Disable' : 'Enable'),
                            ),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
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

  Widget _collectionPicker() {
    final items = const <String, String>{
      'police_stations': 'Police Stations',
      'patrol_teams': 'Patrol Teams',
      'teams': 'Teams (legacy)',
      'alert_groups': 'Alert Groups',
    };

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const Icon(Icons.storage),
            const SizedBox(width: 10),
            const Text('Collection:'),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _collection,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: items.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _collection = v ?? 'police_stations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryEntryDialog extends StatefulWidget {
  final String collection;
  final DirectoryAdminService svc;
  final String? docId;
  final Map<String, dynamic>? initial;

  const _DirectoryEntryDialog({
    required this.collection,
    required this.svc,
    this.docId,
    this.initial,
  });

  @override
  State<_DirectoryEntryDialog> createState() => _DirectoryEntryDialogState();
}

class _DirectoryEntryDialogState extends State<_DirectoryEntryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  bool _enabled = true;
  String _serviceType = '';

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final d = widget.initial ?? {};
    final loc = (d['location'] is Map) ? (d['location'] as Map) : {};

    _name = TextEditingController(text: (d['name'] ?? '').toString());
    _phone = TextEditingController(text: (d['phoneNumber'] ?? d['phone'] ?? '').toString());
    _whatsapp = TextEditingController(text: (d['whatsapp'] ?? d['wa'] ?? '').toString());
    _address = TextEditingController(text: (d['addressText'] ?? d['address'] ?? '').toString());

    _lat = TextEditingController(text: (loc['lat'] ?? '').toString());
    _lng = TextEditingController(text: (loc['lng'] ?? '').toString());

    _enabled = d['enabled'] != false;

    _serviceType = (d['serviceType'] ?? '').toString();
    if (_serviceType.isEmpty) {
      // default by collection
      if (widget.collection == 'police_stations') _serviceType = 'police';
      if (widget.collection == 'patrol_teams' || widget.collection == 'teams') _serviceType = 'patrol';
      if (widget.collection == 'alert_groups') _serviceType = 'group';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAlertGroup = widget.collection == 'alert_groups';

    return AlertDialog(
      title: Text(widget.docId == null ? 'Add entry' : 'Edit entry'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone (phoneNumber)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _whatsapp,
                decoration: const InputDecoration(labelText: 'WhatsApp (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address text (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: const InputDecoration(labelText: 'Service type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'police', child: Text('police')),
                  DropdownMenuItem(value: 'patrol', child: Text('patrol')),
                  DropdownMenuItem(value: 'security', child: Text('security')),
                  DropdownMenuItem(value: 'escort', child: Text('escort')),
                  DropdownMenuItem(value: 'group', child: Text('group')),
                  DropdownMenuItem(value: 'other', child: Text('other')),
                ],
                onChanged: (v) => setState(() => _serviceType = v ?? _serviceType),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Enabled'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 10),

              // For Nearby Help, geohash/location is required.
              // For alert_groups you may not want location, but we still allow it.
              if (!isAlertGroup) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Location (required for Nearby Help)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Location (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lat,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lng,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Tip: If you don’t know lat/lng, open Google Maps, long-press the place, then copy the coordinates.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }

    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());

    // For Nearby Help collections, enforce location
    final requiresLocation =
        widget.collection == 'police_stations' || widget.collection == 'patrol_teams' || widget.collection == 'teams';

    if (requiresLocation && (lat == null || lng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitude and Longitude are required for Nearby Help.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.svc.upsert(
        collection: widget.collection,
        docId: widget.docId,
        name: name,
        phoneNumber: _phone.text.trim(),
        whatsapp: _whatsapp.text.trim(),
        addressText: _address.text.trim(),
        enabled: _enabled,
        serviceType: _serviceType.trim().isEmpty ? 'other' : _serviceType.trim(),
        lat: lat,
        lng: lng,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

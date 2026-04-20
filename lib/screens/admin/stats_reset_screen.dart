import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum _RangePreset { d7, d30, d90, all }

class StatsResetScreen extends StatefulWidget {
  const StatsResetScreen({super.key});

  @override
  State<StatsResetScreen> createState() => _StatsResetScreenState();
}

class _StatsResetScreenState extends State<StatsResetScreen> {
  final _db = FirebaseFirestore.instance;

  final _collections = const [
    'central_alarms', // 🔥 IMPORTANT (main stats source)
    'alerts',
    'escort_requests',
    'breakdown_requests',
    'community_reports',
    'broadcasts',
    'patrol_shifts',
    'patrol_shift_plans',
  ];

  String _collection = 'central_alarms';
  _RangePreset _range = _RangePreset.d30;

  final _areaCtrl = TextEditingController(text: 'Default');
  final _userCtrl = TextEditingController();

  bool _busy = false;
  int? _previewCount;
  String? _lastMsg;

  /// ==========================================================
  /// DATE FILTER
  /// ==========================================================
  DateTime? get _since {
    final now = DateTime.now();
    switch (_range) {
      case _RangePreset.d7:
        return now.subtract(const Duration(days: 7));
      case _RangePreset.d30:
        return now.subtract(const Duration(days: 30));
      case _RangePreset.d90:
        return now.subtract(const Duration(days: 90));
      case _RangePreset.all:
        return null;
    }
  }

  /// ==========================================================
  /// BUILD QUERY (SAFE)
  /// ==========================================================
  Query<Map<String, dynamic>> _buildQuery({required bool forDelete}) {
    Query<Map<String, dynamic>> q = _db.collection(_collection);

    final area = _areaCtrl.text.trim();
    final user = _userCtrl.text.trim();

    /// AREA FILTER
    if (area.isNotEmpty) {
      q = q.where('areaId', isEqualTo: area);
    }

    /// USER FILTER
    if (user.isNotEmpty) {
      q = q.where('senderId', isEqualTo: user);
    }

    final since = _since;

    /// 🔥 HANDLE DIFFERENT DATE FIELDS
    String dateField = 'createdAt';

    if (_collection == 'central_alarms') {
      dateField = 'triggeredAt';
    } else if (_collection == 'patrol_shifts') {
      dateField = 'startAt';
    }

    if (since != null) {
      q = q.where(
        dateField,
        isGreaterThanOrEqualTo: Timestamp.fromDate(since),
      );
    }

    q = q.orderBy(dateField, descending: true);

    return q.limit(forDelete ? 200 : 500);
  }

  /// ==========================================================
  /// PREVIEW
  /// ==========================================================
  Future<void> _preview() async {
    setState(() {
      _busy = true;
      _previewCount = null;
      _lastMsg = null;
    });

    try {
      final snap = await _buildQuery(forDelete: false).get();

      setState(() {
        _previewCount = snap.size;
        _lastMsg = 'Preview ready.';
      });
    } catch (e) {
      setState(() => _lastMsg = 'Preview failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  /// ==========================================================
  /// DELETE
  /// ==========================================================
  Future<void> _delete() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _lastMsg = 'You must be signed in.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠ Confirm DELETE'),
        content: Text(
          'Collection: $_collection\n'
          'Area: ${_areaCtrl.text}\n'
          'User: ${_userCtrl.text.isEmpty ? '(all)' : _userCtrl.text}\n'
          'Range: $_range\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _busy = true;
      _lastMsg = 'Deleting...';
    });

    int deleted = 0;

    try {
      while (true) {
        final snap = await _buildQuery(forDelete: true).get();
        if (snap.docs.isEmpty) break;

        final batch = _db.batch();

        for (final d in snap.docs) {
          batch.delete(d.reference);
        }

        await batch.commit();

        deleted += snap.docs.length;

        if (!mounted) return;

        setState(() => _lastMsg = 'Deleted $deleted...');
      }

      /// 🔥 LOG RESET ACTION
      await _db.collection('admin_logs').add({
        'action': 'stats_reset',
        'collection': _collection,
        'deletedCount': deleted,
        'area': _areaCtrl.text,
        'user': _userCtrl.text,
        'performedBy': user.uid,
        'time': FieldValue.serverTimestamp(),
      });

      setState(() {
        _lastMsg = '✅ Done. Deleted $deleted documents.';
        _previewCount = null;
      });
    } catch (e) {
      setState(() => _lastMsg = '❌ Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  /// ==========================================================
  /// UI
  /// ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Reset Stats')),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [

                  const Text(
                    '⚠ Danger Zone',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _collection,
                    items: _collections
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: _busy ? null : (v) => setState(() => _collection = v!),
                    decoration: const InputDecoration(
                      labelText: 'Collection',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<_RangePreset>(
                    value: _range,
                    items: const [
                      DropdownMenuItem(value: _RangePreset.d7, child: Text('Last 7 days')),
                      DropdownMenuItem(value: _RangePreset.d30, child: Text('Last 30 days')),
                      DropdownMenuItem(value: _RangePreset.d90, child: Text('Last 90 days')),
                      DropdownMenuItem(value: _RangePreset.all, child: Text('All time')),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _range = v!),
                    decoration: const InputDecoration(
                      labelText: 'Range',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Area ID',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'User ID',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _preview,
                          child: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy ? null : _delete,
                          child: const Text('DELETE'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_previewCount != null)
                    Text('Preview: $_previewCount documents'),

                  if (_lastMsg != null) Text(_lastMsg!),

                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
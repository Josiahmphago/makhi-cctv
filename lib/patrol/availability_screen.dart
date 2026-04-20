// lib/patrol/availability_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;

  // weekly: mon..sun -> list of "HH:mm-HH:mm"
  final Map<String, List<String>> _weekly = {
    'mon': [],
    'tue': [],
    'wed': [],
    'thu': [],
    'fri': [],
    'sat': [],
    'sun': [],
  };

  // exceptions: [{startAt,endAt,status,note}]
  final List<Map<String, dynamic>> _exceptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _labelDay(String k) {
    switch (k) {
      case 'mon': return 'Mon';
      case 'tue': return 'Tue';
      case 'wed': return 'Wed';
      case 'thu': return 'Thu';
      case 'fri': return 'Fri';
      case 'sat': return 'Sat';
      case 'sun': return 'Sun';
      default: return k;
    }
  }

  Future<void> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }

    final snap = await _db.collection('patrol_agents').doc(u.uid).get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      final availability = (data['availability'] is Map)
          ? Map<String, dynamic>.from(data['availability'] as Map)
          : <String, dynamic>{};

      final weeklyRaw = availability['weekly'];
      if (weeklyRaw is Map) {
        for (final e in weeklyRaw.entries) {
          final k = e.key.toString();
          final v = e.value;
          if (_weekly.containsKey(k) && v is List) {
            _weekly[k] = List<String>.from(v.map((x) => x.toString()));
          }
        }
      }

      final exRaw = availability['exceptions'];
      if (exRaw is List) {
        _exceptions
          ..clear()
          ..addAll(exRaw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    await _db.collection('patrol_agents').doc(u.uid).set({
      'availability': {
        'weekly': _weekly,
        'exceptions': _exceptions,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Availability saved ✅')),
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(context: context, initialTime: initial);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _addSlot(String dayKey) async {
    final start = await _pickTime(const TimeOfDay(hour: 18, minute: 0));
    if (start == null) return;

    final end = await _pickTime(const TimeOfDay(hour: 22, minute: 0));
    if (end == null) return;

    final slot = '${_fmt(start)}-${_fmt(end)}';
    setState(() => _weekly[dayKey] = [..._weekly[dayKey]!, slot]);
  }

  Future<void> _addException() async {
    final now = DateTime.now();
    final startDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (startDate == null) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: startDate.add(const Duration(days: 30)),
    );
    if (endDate == null) return;

    String status = 'unavailable';
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Availability exception'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'unavailable', child: Text('Unavailable')),
                DropdownMenuItem(value: 'available', child: Text('Available (extra cover)')),
              ],
              onChanged: (v) => status = v ?? 'unavailable',
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _exceptions.add({
        'startAt': Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day, 0, 0)),
        'endAt': Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59)),
        'status': status,
        'note': noteCtrl.text.trim(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Availability'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Weekly availability',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ..._weekly.keys.map((dayKey) {
            final slots = _weekly[dayKey] ?? [];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(_labelDay(dayKey), style: const TextStyle(fontWeight: FontWeight.w600))),
                        TextButton.icon(
                          onPressed: () => _addSlot(dayKey),
                          icon: const Icon(Icons.add),
                          label: const Text('Add time'),
                        ),
                      ],
                    ),
                    if (slots.isEmpty)
                      const Text('No times set', style: TextStyle(color: Colors.grey)),
                    if (slots.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: slots.map((s) {
                          return InputChip(
                            label: Text(s),
                            onDeleted: () {
                              setState(() => _weekly[dayKey] = [...slots]..remove(s));
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'Exceptions (out of town / extra cover)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: _addException,
            icon: const Icon(Icons.event_busy),
            label: const Text('Add exception'),
          ),

          const SizedBox(height: 10),

          if (_exceptions.isEmpty)
            const Text('No exceptions yet', style: TextStyle(color: Colors.grey)),

          ..._exceptions.map((e) {
            final startAt = e['startAt'];
            final endAt = e['endAt'];
            final status = (e['status'] ?? '').toString();
            final note = (e['note'] ?? '').toString();

            String fmtTs(dynamic t) {
              if (t is Timestamp) {
                final d = t.toDate();
                return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              }
              return '-';
            }

            return Card(
              child: ListTile(
                leading: Icon(
                  status == 'available' ? Icons.add_circle : Icons.remove_circle,
                  color: status == 'available' ? Colors.green : Colors.red,
                ),
                title: Text('$status • ${fmtTs(startAt)} → ${fmtTs(endAt)}'),
                subtitle: note.isEmpty ? null : Text(note),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _exceptions.remove(e)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

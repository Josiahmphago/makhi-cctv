// lib/admin/patrol_shift_planner_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/patrol_agent.dart';

class PatrolShiftPlannerScreen extends StatefulWidget {
  const PatrolShiftPlannerScreen({super.key});

  @override
  State<PatrolShiftPlannerScreen> createState() => _PatrolShiftPlannerScreenState();
}

class _PatrolShiftPlannerScreenState extends State<PatrolShiftPlannerScreen> {
  final _db = FirebaseFirestore.instance;

  String _area = 'Default';
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 22, minute: 0);

  bool _loading = false;
  List<PatrolAgent> _agents = [];
  final Set<String> _selected = {};

  DateTime _combine(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) setState(() => _end = picked);
  }

  String _weekdayKey(DateTime d) {
    // DateTime.weekday: 1=Mon ... 7=Sun
    switch (d.weekday) {
      case 1: return 'mon';
      case 2: return 'tue';
      case 3: return 'wed';
      case 4: return 'thu';
      case 5: return 'fri';
      case 6: return 'sat';
      case 7: return 'sun';
      default: return 'mon';
    }
  }

  int _mins(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool _slotCovers(String slot, DateTime startAt, DateTime endAt) {
    // slot: "HH:mm-HH:mm"
    final p = slot.split('-');
    if (p.length != 2) return false;
    final s = _mins(p[0]);
    final e = _mins(p[1]);
    final reqS = startAt.hour * 60 + startAt.minute;
    final reqE = endAt.hour * 60 + endAt.minute;
    return s <= reqS && e >= reqE;
  }

  bool _isAvailable(PatrolAgent a, DateTime startAt, DateTime endAt) {
    // 1) exceptions override
    for (final ex in a.availabilityExceptions) {
      final s = ex['startAt'];
      final e = ex['endAt'];
      final status = (ex['status'] ?? '').toString();
      if (s is Timestamp && e is Timestamp) {
        final ss = s.toDate();
        final ee = e.toDate();
        final overlaps = !(endAt.isBefore(ss) || startAt.isAfter(ee));
        if (overlaps) {
          // if any "unavailable" overlaps => not available
          if (status == 'unavailable') return false;
          if (status == 'available') return true; // explicit available wins
        }
      }
    }

    // 2) weekly check
    final dayKey = _weekdayKey(startAt);
    final slots = a.availabilityWeekly[dayKey] ?? const [];
    for (final slot in slots) {
      if (_slotCovers(slot, startAt, endAt)) return true;
    }

    // If no schedule set, treat as NOT available (forces agents to set availability)
    return false;
  }

  Future<void> _loadAgents() async {
    setState(() {
      _loading = true;
      _agents = [];
      _selected.clear();
    });

    try {
      final startAt = _combine(_date, _start);
      final endAt = _combine(_date, _end);

      // all agents in area (using your existing field name: "area" array)
      final snap = await _db
          .collection('patrol_agents')
          .where('area', arrayContains: _area)
          .get();

      final all = snap.docs.map((d) => PatrolAgent.fromMap(d.id, d.data())).toList();
      final filtered = all.where((a) => _isAvailable(a, startAt, endAt)).toList()
        ..sort((a, b) => (a.name).compareTo(b.name));

      setState(() => _agents = filtered);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePlan() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one available agent')),
      );
      return;
    }

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first')),
      );
      return;
    }

    final startAt = _combine(_date, _start);
    final endAt = _combine(_date, _end);

    setState(() => _loading = true);
    try {
      await _db.collection('patrol_shift_plans').add({
        'areaId': _area,
        'startsAt': Timestamp.fromDate(startAt),
        'endsAt': Timestamp.fromDate(endAt),
        'assignedAgentIds': _selected.toList(),
        'status': 'planned',
        'createdBy': admin.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift plan saved ✅')),
      );

      setState(() => _selected.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startAt = _combine(_date, _start);
    final endAt = _combine(_date, _end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Patrol Shift'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _savePlan,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: _area,
            items: const [
              DropdownMenuItem(value: 'Default', child: Text('Default')),
              DropdownMenuItem(value: 'pta', child: Text('pta')),
              DropdownMenuItem(value: 'sosh', child: Text('sosh')),
            ],
            onChanged: (v) => setState(() => _area = v ?? 'Default'),
            decoration: const InputDecoration(labelText: 'Area'),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStart,
                  icon: const Icon(Icons.schedule),
                  label: Text('Start ${_start.format(context)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEnd,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text('End ${_end.format(context)}'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text('Planned: ${startAt.toLocal()} → ${endAt.toLocal()}',
              style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loading ? null : _loadAgents,
            icon: const Icon(Icons.search),
            label: const Text('Find available agents'),
          ),

          const SizedBox(height: 16),
          const Text('Available agents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (_loading) const Center(child: CircularProgressIndicator()),

          if (!_loading && _agents.isEmpty)
            const Text('No available agents found. Ask agents to set availability.',
                style: TextStyle(color: Colors.grey)),

          if (!_loading && _agents.isNotEmpty)
            ..._agents.map((a) {
              final isSel = _selected.contains(a.id);
              final rate = (a.hourlyRate ?? 0) > 0 ? 'R${a.hourlyRate!.toStringAsFixed(0)}/hr' : 'Volunteer';
              final rating = (a.rating ?? 0) > 0 ? '⭐ ${a.rating!.toStringAsFixed(1)} (${a.ratingCount ?? 0})' : 'No rating';

              return Card(
                child: CheckboxListTile(
                  value: isSel,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(a.id);
                      } else {
                        _selected.remove(a.id);
                      }
                    });
                  },
                  title: Text(a.name),
                  subtitle: Text('$rate • $rating'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

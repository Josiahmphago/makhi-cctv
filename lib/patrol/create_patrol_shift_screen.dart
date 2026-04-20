import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatePatrolShiftScreen extends StatefulWidget {
  const CreatePatrolShiftScreen({super.key});

  @override
  State<CreatePatrolShiftScreen> createState() => _CreatePatrolShiftScreenState();
}

class _CreatePatrolShiftScreenState extends State<CreatePatrolShiftScreen> {
  String? _teamId;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 4));

  @override
  Widget build(BuildContext context) {
    final teams = FirebaseFirestore.instance.collection('teams').orderBy('name');

    return Scaffold(
      appBar: AppBar(title: const Text('Create Patrol Shift')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: teams.snapshots(),
            builder: (c, s) {
              if (!s.hasData) return const LinearProgressIndicator();
              final docs = s.data!.docs;
              if (docs.isEmpty) return const Text('Create a team first.');
              return DropdownButtonFormField<String>(
                value: _teamId,
                items: docs.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  return DropdownMenuItem(value: d.id, child: Text(m['name'] ?? d.id));
                }).toList(),
                onChanged: (v) => setState(() => _teamId = v),
                decoration: const InputDecoration(labelText: 'Team'),
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text('Start: ${_start.toString().substring(0,16)}'),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (d == null) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
              if (t == null) return;
              setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          ListTile(
            leading: const Icon(Icons.stop),
            title: Text('End:   ${_end.toString().substring(0,16)}'),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _end, firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (d == null) return;
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_end));
              if (t == null) return;
              setState(() => _end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Shift'),
            onPressed: _teamId == null ? null : () async {
              await FirebaseFirestore.instance.collection('patrol_shifts').add({
                'teamId': _teamId,
                'startTime': Timestamp.fromDate(_start),
                'endTime': Timestamp.fromDate(_end),
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift created')));
              }
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Upcoming Shifts', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patrol_shifts')
                .orderBy('startTime')
                .snapshots(),
            builder: (c, s) {
              if (!s.hasData) return const SizedBox.shrink();
              final docs = s.data!.docs;
              return Column(
                children: docs.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final st = (m['startTime'] as Timestamp).toDate();
                  final en = (m['endTime'] as Timestamp).toDate();
                  return Card(
                    child: ListTile(
                      title: Text('Team: ${m['teamId']}'),
                      subtitle: Text('${st.toString().substring(0,16)} → ${en.toString().substring(0,16)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => d.reference.delete(),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

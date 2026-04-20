import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestAddTeamsScreen extends StatelessWidget {
  const TestAddTeamsScreen({super.key});

  Future<void> addTestTeams(BuildContext context) async {
    final teams = [
      {
        'name': 'Zone A Patrol Team',
        'areaCovered': 'Zone A',
        'shiftType': 'day',
        'isActive': true,
        'members': [
          {'name': 'John Doe', 'phone': '0812345678'},
          {'name': 'Jane Doe', 'phone': '0823456789'},
        ],
      },
      {
        'name': 'Zone B Patrol Team',
        'areaCovered': 'Zone B',
        'shiftType': 'night',
        'isActive': true,
        'members': [
          {'name': 'Mike Smith', 'phone': '0834567890'},
        ],
      },
      {
        'name': 'Zone C Patrol Team',
        'areaCovered': 'Zone C',
        'shiftType': 'day',
        'isActive': true,
        'members': [
          {'name': 'Lerato Mokoena', 'phone': '0845678901'},
        ],
      },
    ];

    try {
      for (final team in teams) {
        await FirebaseFirestore.instance.collection('patrol_teams').add(team);
      }

      // Notify success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Test patrol teams added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to add teams: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Test Patrol Teams")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Test Teams"),
          onPressed: () => addTestTeams(context),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeedDemoDataScreen extends StatelessWidget {
  const SeedDemoDataScreen({super.key});

  Future<void> _seed(BuildContext context) async {
    final b = FirebaseFirestore.instance.batch();

    // Groups
    final groups = [
      {
        'name': 'Police',
        'emoji': '👮',
        'numbers': ['whatsapp:+27XXXXXXXXX'],
        'priority': 1,
      },
      {
        'name': 'Patrol',
        'emoji': '🛡️',
        'numbers': ['+27XXXXXXXXX'],
        'priority': 2,
      },
    ];
    for (final g in groups) {
      b.set(FirebaseFirestore.instance.collection('alert_groups').doc(), {
        ...g,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Teams (no real location, but Nearby Services will still list them after you edit)
    final teams = [
      {
        'name': 'Block F Patrol',
        'type': 'patrol',
        'contact': {'phone': '+27XXXXXXXXX', 'wa': 'whatsapp:+27XXXXXXXXX'}
      },
      {
        'name': 'Station A (Police)',
        'type': 'police',
        'contact': {'phone': '+27XXXXXXXXX'}
      },
    ];
    for (final t in teams) {
      b.set(FirebaseFirestore.instance.collection('teams').doc(), {
        ...t,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Panic settings
    b.set(FirebaseFirestore.instance.collection('panic_settings').doc('global'), {
      'defaultMessage': 'SOS 🚨 Please help me.',
      'contacts': ['whatsapp:+27XXXXXXXXX', '+27XXXXXXXXX'],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await b.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeded demo data.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Demo Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Creates sample groups, teams, and panic settings so you can test flows immediately.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Seed Now'),
                onPressed: () => _seed(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

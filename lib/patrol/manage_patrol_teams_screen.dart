import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';

class ManagePatrolTeamsScreen extends StatefulWidget {
  const ManagePatrolTeamsScreen({super.key});

  @override
  State<ManagePatrolTeamsScreen> createState() =>
      _ManagePatrolTeamsScreenState();
}

class _ManagePatrolTeamsScreenState extends State<ManagePatrolTeamsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _addTeam() async {
    setState(() => _loading = true);

    try {
      final pos = await Geolocator.getCurrentPosition();

      final geoHasher = GeoHasher();
      final hash = geoHasher.encode(pos.latitude, pos.longitude, precision: 7);

      await _firestore.collection('teams').add({
        'name': _nameCtrl.text,
        'type': 'patrol',
        'location': {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'geohash': hash,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Patrol team added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Patrol Teams')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Team Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _addTeam,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('teams')
                  .where('type', isEqualTo: 'patrol')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No patrol teams yet.'));
                }
                return ListView(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? d.id),
                      subtitle: Text(
                          'Lat: ${data['location']['lat']} | Lng: ${data['location']['lng']}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

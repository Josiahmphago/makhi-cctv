import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

enum NearbyFilter { all, police, patrol }

class NearbyServicesScreen extends StatefulWidget {
  const NearbyServicesScreen({super.key});

  @override
  State<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends State<NearbyServicesScreen> {
  bool _loading = true;
  String? _error;

  NearbyFilter _filter = NearbyFilter.all;

  Position? _pos;
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
    });

    try {
      // ✅ force better/fresher location
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );
      _pos = pos;

      // load both collections
      final policeSnap = await FirebaseFirestore.instance
          .collection('police_stations')
          .where('enabled', isEqualTo: true)
          .get();

      final patrolSnap = await FirebaseFirestore.instance
          .collection('patrol_teams')
          .where('enabled', isEqualTo: true)
          .get();

      void addFrom(QuerySnapshot<Map<String, dynamic>> snap, String type) {
        for (final doc in snap.docs) {
          final data = doc.data();
          final loc = data['location'];
          if (loc == null) continue;

          final lat = loc['lat'];
          final lng = loc['lng'];
          if (lat == null || lng == null) continue;

          final distanceM = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            (lat as num).toDouble(),
            (lng as num).toDouble(),
          );

          // within 20km
          if (distanceM <= 20000) {
            _items.add({
              'id': doc.id,
              'type': type, // 'police' | 'patrol'
              'name': data['name'] ?? (type == 'police' ? 'Police Station' : 'Patrol Team'),
              'phoneNumber': data['phoneNumber'] ?? data['phone'] ?? '',
              'lat': (lat as num).toDouble(),
              'lng': (lng as num).toDouble(),
              'distanceM': distanceM,
            });
          }
        }
      }

      addFrom(policeSnap, 'police');
      addFrom(patrolSnap, 'patrol');

      _items.sort((a, b) => (a['distanceM'] as double).compareTo(b['distanceM'] as double));

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == NearbyFilter.all) return _items;
    final t = _filter == NearbyFilter.police ? 'police' : 'patrol';
    return _items.where((x) => x['type'] == t).toList();
  }

  String _km(double meters) => (meters / 1000).toStringAsFixed(2);

  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final accuracyText = _pos == null ? '' : "GPS accuracy: ${_pos!.accuracy.toStringAsFixed(0)}m";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Services'),
        actions: [
          IconButton(
            onPressed: _loadNearby,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              accuracyText.isEmpty ? "Ready" : accuracyText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          DropdownButton<NearbyFilter>(
                            value: _filter,
                            onChanged: (v) => setState(() => _filter = v ?? NearbyFilter.all),
                            items: const [
                              DropdownMenuItem(value: NearbyFilter.all, child: Text("All")),
                              DropdownMenuItem(value: NearbyFilter.police, child: Text("Police")),
                              DropdownMenuItem(value: NearbyFilter.patrol, child: Text("Patrol")),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text("No nearby services found within 20km"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final item = _filtered[i];
                                final type = item['type'] as String;
                                final meters = item['distanceM'] as double;

                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      type == 'police' ? Icons.local_police : Icons.groups,
                                      color: type == 'police' ? Colors.blue : Colors.green,
                                    ),
                                    title: Text(item['name'] as String),
                                    subtitle: Text("${_km(meters)} km away"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.call),
                                      onPressed: () => _call(item['phoneNumber'] as String),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

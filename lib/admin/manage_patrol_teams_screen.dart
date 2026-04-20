import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ManagePatrolTeamsScreen extends StatefulWidget {
  const ManagePatrolTeamsScreen({super.key});

  @override
  State<ManagePatrolTeamsScreen> createState() => _ManagePatrolTeamsScreenState();
}

class _ManagePatrolTeamsScreenState extends State<ManagePatrolTeamsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _enabled = true;
  bool _saving = false;

  double? _lat;
  double? _lng;
  String? _geohash;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Turn on GPS to set location.'),
          action: SnackBarAction(label: 'Settings', onPressed: Geolocator.openLocationSettings),
        ),
      );
      return;
    }

    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission denied.'),
          action: SnackBarAction(label: 'App settings', onPressed: Geolocator.openAppSettings),
        ),
      );
      return;
    }

    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _lat = p.latitude;
      _lng = p.longitude;
      _geohash = _encodeGeohash(p.latitude, p.longitude, precision: 9);
    });
  }

  Future<void> _add() async {
    final n = _name.text.trim();
    final ph = _phone.text.trim();
    if (n.isEmpty) return;

    // allow phone empty, but recommended
    if (_lat == null || _lng == null || _geohash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set location (Use my GPS).')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('patrol_teams').add({
        'enabled': _enabled,
        'name': n,
        'phoneNumber': ph,
        'address': _address.text.trim(),
        'location': {
          'lat': _lat,
          'lng': _lng,
          'geohash': _geohash,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _name.clear();
      _phone.clear();
      _address.clear();
      setState(() {
        _lat = null;
        _lng = null;
        _geohash = null;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(String id, bool v) async {
    await FirebaseFirestore.instance.collection('patrol_teams').doc(id).update({'enabled': v});
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('patrol_teams').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('patrol_teams').orderBy('name').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Patrol Teams')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Team name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        value: _enabled,
                        onChanged: _saving ? null : (v) => setState(() => _enabled = v),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _useMyLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my GPS'),
                    ),
                  ],
                ),
                if (_lat != null && _lng != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Location: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}\nGeohash: ${_geohash ?? "-"}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _add,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add),
                    label: const Text('Add patrol team'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No patrol teams yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name = (data['name'] ?? d.id).toString();
                    final enabled = data['enabled'] == true;
                    final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(phone.isEmpty ? d.id : phone),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          Switch(value: enabled, onChanged: (v) => _toggle(d.id, v)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(d.id)),
                        ],
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

  // tiny geohash encoder (same logic style you used earlier)
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  String _encodeGeohash(double lat, double lng, {int precision = 9}) {
    var minLat = -90.0, maxLat = 90.0;
    var minLng = -180.0, maxLng = 180.0;

    final bits = <int>[16, 8, 4, 2, 1];
    var bit = 0;
    var ch = 0;
    var even = true;

    final sb = StringBuffer();
    while (sb.length < precision) {
      if (even) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= bits[bit];
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= bits[bit];
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        sb.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return sb.toString();
  }
}

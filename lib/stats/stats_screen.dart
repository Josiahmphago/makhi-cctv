// lib/stats/stats_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum _RangePreset { d7, d30, d90, all }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = FirebaseFirestore.instance;

  _RangePreset _range = _RangePreset.d30;
  String _areaId = 'Default'; // keep consistent with your app

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

  String get _rangeLabel {
    switch (_range) {
      case _RangePreset.d7:
        return 'Last 7 days';
      case _RangePreset.d30:
        return 'Last 30 days';
      case _RangePreset.d90:
        return 'Last 90 days';
      case _RangePreset.all:
        return 'All time';
    }
  }

  Query<Map<String, dynamic>> _baseQuery(String collection) {
    Query<Map<String, dynamic>> q = _db.collection(collection);

    // apply area filter where it exists
    // (alerts/breakdown/escort usually have areaId)
    if (_areaId.trim().isNotEmpty) {
      // We apply where only to collections that are known to have areaId.
      // If a collection doesn't have areaId, Firestore may still allow it but returns 0.
      q = q.where('areaId', isEqualTo: _areaId);
    }

    final since = _since;
    if (since != null) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    return q;
  }

  // --------- counts ----------
  Stream<int> _countStream(Query<Map<String, dynamic>> q) {
    return q.snapshots().map((s) => s.size);
  }

  // --------- trend (per day) ----------
  // Pull last N docs, group by yyyy-mm-dd
  Stream<Map<String, int>> _dailyTrendStream(
    Query<Map<String, dynamic>> q, {
    int limit = 400,
  }) {
    // we must orderBy createdAt for stable results
    final qq = q.orderBy('createdAt', descending: true).limit(limit);
    return qq.snapshots().map((snap) {
      final m = <String, int>{};
      for (final d in snap.docs) {
        final data = d.data();
        final ts = data['createdAt'];
        if (ts is! Timestamp) continue;
        final dt = ts.toDate();
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        m[key] = (m[key] ?? 0) + 1;
      }

      // sort keys ascending
      final sortedKeys = m.keys.toList()..sort();
      final out = <String, int>{};
      for (final k in sortedKeys) {
        out[k] = m[k]!;
      }
      return out;
    });
  }

  // ---------- my performance ----------
  Future<Map<String, dynamic>> _loadMyPerformance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'note': 'Not signed in'};
    }

    final uid = user.uid;

    // accepted/resolved from alerts
    Query<Map<String, dynamic>> qa = _db.collection('alerts').where('acceptedBy', isEqualTo: uid);

    if (_areaId.trim().isNotEmpty) {
      qa = qa.where('areaId', isEqualTo: _areaId);
    }
    final since = _since;
    if (since != null) {
      qa = qa.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }

    final acceptedSnap = await qa.limit(600).get();
    int accepted = acceptedSnap.size;

    int resolved = 0;
    int totalResponseMinutes = 0;

    for (final d in acceptedSnap.docs) {
      final data = d.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'resolved') {
        resolved++;
        final a = data['acceptedAt'];
        final r = data['resolvedAt'];
        if (a is Timestamp && r is Timestamp) {
          totalResponseMinutes += r.toDate().difference(a.toDate()).inMinutes;
        }
      }
    }

    final avg = resolved > 0 ? (totalResponseMinutes / resolved) : 0.0;

    // profile fields
    double rating = 0;
    int ratingCount = 0;
    double hourlyRate = 0;

    final profile = await _db.collection('patrol_agents').doc(uid).get();
    if (profile.exists) {
      final data = profile.data() as Map<String, dynamic>;
      if (data['rating'] != null) rating = (data['rating'] as num).toDouble();
      if (data['ratingCount'] != null) ratingCount = (data['ratingCount'] as num).toInt();
      if (data['hourlyRate'] != null) hourlyRate = (data['hourlyRate'] as num).toDouble();
    }

    return {
      'accepted': accepted,
      'resolved': resolved,
      'avgResponseMins': avg,
      'rating': rating,
      'ratingCount': ratingCount,
      'hourlyRate': hourlyRate,
    };
  }

  // ---------- UI helpers ----------
  List<DropdownMenuItem<_RangePreset>> _rangeItems() {
    return const [
      DropdownMenuItem(value: _RangePreset.d7, child: Text('7d')),
      DropdownMenuItem(value: _RangePreset.d30, child: Text('30d')),
      DropdownMenuItem(value: _RangePreset.d90, child: Text('90d')),
      DropdownMenuItem(value: _RangePreset.all, child: Text('All')),
    ];
  }

  Widget _metricTile(String title, Stream<int> stream, {IconData icon = Icons.analytics}) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (c, s) {
        final n = s.data ?? 0;
        return Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text('Area: $_areaId • $_rangeLabel'),
          ),
        );
      },
    );
  }

  Widget _miniBarChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No data for this range.'),
      );
    }

    final values = data.values.toList();
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final keys = data.keys.toList();

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final k in keys)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
                        height: maxV == 0 ? 2 : (90 * (data[k]! / maxV)).clamp(2, 90).toDouble(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      k.substring(5), // mm-dd
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trendCard(String title, Stream<Map<String, int>> stream) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<Map<String, int>>(
          stream: stream,
          builder: (c, s) {
            final data = s.data ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _miniBarChart(data),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filtersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // ✅ overflow fix: Row -> Expanded dropdown + small labels
            Row(
              children: [
                const Text('Range:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<_RangePreset>(
                    value: _range,
                    isExpanded: true, // ✅ important
                    items: _rangeItems(),
                    onChanged: (v) => setState(() => _range = v ?? _range),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Area input (small)
            TextFormField(
              initialValue: _areaId,
              onChanged: (v) => _areaId = v.trim().isEmpty ? 'Default' : v.trim(),
              decoration: const InputDecoration(
                labelText: 'Area ID',
                hintText: 'Default',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Apply'),
                  onPressed: () => setState(() {}),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Reset (Admin)'),
                  onPressed: () => Navigator.pushNamed(context, '/admin/stats_reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _myPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadMyPerformance(),
          builder: (c, s) {
            if (!s.hasData) {
              return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
            }
            final data = s.data!;
            if (data['note'] != null) {
              return Text(data['note'].toString(), style: const TextStyle(color: Colors.orange));
            }

            final accepted = (data['accepted'] as int?) ?? 0;
            final resolved = (data['resolved'] as int?) ?? 0;
            final avg = ((data['avgResponseMins'] as num?) ?? 0).toDouble();
            final rating = ((data['rating'] as num?) ?? 0).toDouble();
            final ratingCount = (data['ratingCount'] as int?) ?? 0;
            final rate = ((data['hourlyRate'] as num?) ?? 0).toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _chip('Accepted', '$accepted'),
                    _chip('Resolved', '$resolved'),
                    _chip('Avg mins', avg.toStringAsFixed(1)),
                    _chip('Rating', '⭐ ${rating.toStringAsFixed(1)} ($ratingCount)'),
                    _chip('Rate', rate <= 0 ? 'Volunteer' : 'R ${rate.toStringAsFixed(0)}/hr'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Range: $_rangeLabel • Area: $_areaId', style: const TextStyle(color: Colors.grey)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsQ = _baseQuery('alerts');
    final escortsQ = _baseQuery('escort_requests');
    final breakdownQ = _baseQuery('breakdown_requests');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Stats'),
        actions: [
          IconButton(
            tooltip: 'Reset (Admin)',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => Navigator.pushNamed(context, '/admin/stats_reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filtersCard(),
          const SizedBox(height: 12),

          _metricTile('Alerts', _countStream(alertsQ), icon: Icons.warning_amber),
          const SizedBox(height: 10),
          _metricTile('Escort Requests', _countStream(escortsQ), icon: Icons.security),
          const SizedBox(height: 10),
          _metricTile('Breakdown Requests', _countStream(breakdownQ), icon: Icons.car_repair),

          const SizedBox(height: 14),
          const Text('Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _trendCard('Alerts per day', _dailyTrendStream(alertsQ)),
          const SizedBox(height: 10),
          _trendCard('Escort requests per day', _dailyTrendStream(escortsQ)),
          const SizedBox(height: 10),
          _trendCard('Breakdown requests per day', _dailyTrendStream(breakdownQ)),

          const SizedBox(height: 14),
          _myPerformanceCard(),

          const SizedBox(height: 10),
          const Text(
            'Note: Trend uses latest ~400 docs for speed. For large databases we can upgrade to Cloud Functions aggregation later.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

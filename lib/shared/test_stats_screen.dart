import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

enum StatsRange { last7, last30, last90, all, sinceReset }

class _StatsScreenState extends State<StatsScreen> {
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;

  // Filters
  StatsRange _range = StatsRange.last30;
  String _area = 'Default'; // Default or 'ALL'

  // Soft reset timestamp (from users/{uid}.statsResetAt)
  DateTime? _resetAt;

  // Counts (health)
  Map<String, int> _counts = {};

  // Performance
  Map<String, dynamic> _perf = {};

  // Charts data
  Map<DateTime, int> _alertsCreatedByDay = {};
  int _acceptedByMe = 0;
  int _resolvedByMe = 0;
  Map<String, int> _statusDist = {};

  // ---- Toggle: delete feature (set false if you don’t want it visible)
  final bool _enableDeleteMyData = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // -------------------------
  // Helpers
  // -------------------------

  String _rangeLabel(StatsRange r) {
    switch (r) {
      case StatsRange.last7:
        return 'Last 7 days';
      case StatsRange.last30:
        return 'Last 30 days';
      case StatsRange.last90:
        return 'Last 90 days';
      case StatsRange.all:
        return 'All time';
      case StatsRange.sinceReset:
        return 'Since reset';
    }
  }

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime? _computeStartAt() {
    final now = DateTime.now();
    switch (_range) {
      case StatsRange.last7:
        return _startOfDay(now.subtract(const Duration(days: 6)));
      case StatsRange.last30:
        return _startOfDay(now.subtract(const Duration(days: 29)));
      case StatsRange.last90:
        return _startOfDay(now.subtract(const Duration(days: 89)));
      case StatsRange.all:
        return null;
      case StatsRange.sinceReset:
        return _resetAt == null ? null : _startOfDay(_resetAt!);
    }
  }

  Future<int> _countColl(String name) async {
    // Simple safe count: limit 500
    // If rules block, this throws; we catch it in caller.
    final snap = await _db.collection(name).limit(500).get();
    return snap.size;
  }

  Future<DateTime?> _loadResetAt() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    final ts = data['statsResetAt'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  Future<void> _resetMyStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to reset stats.')),
      );
      return;
    }

    await _db.collection('users').doc(uid).set({
      'statsResetAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Stats reset. Now showing “Since reset” data.')),
    );

    setState(() {
      _range = StatsRange.sinceReset;
    });

    await _load();
  }

  // -------------------------
  // Optional: Delete my data (safe/user-owned only)
  // -------------------------

  Future<void> _deleteMyData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete my data?'),
        content: const Text(
          'This deletes ONLY your documents (where owner field matches your UID).\n\n'
          'It does not delete other people’s reports or alerts.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    // Collections + owner field
    final targets = <_DeleteTarget>[
      _DeleteTarget('alerts', 'userId'),
      _DeleteTarget('community_reports', 'userId'),
      _DeleteTarget('patrol_shifts', 'agentId'), // shift uses agentId
      _DeleteTarget('patrol_shift_plans', 'agentId'),
      _DeleteTarget('escort_requests', 'requesterId'),
      _DeleteTarget('breakdown_requests', 'requesterId'),
    ];

    int deleted = 0;
    for (final t in targets) {
      try {
        deleted += await _deleteWhereEquals(
          collection: t.collection,
          field: t.ownerField,
          value: uid,
          limit: 250,
        );
      } catch (e) {
        // Don’t fail whole operation; show note
        debugPrint('Delete failed for ${t.collection}: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Deleted $deleted documents (where allowed).')),
    );

    await _load();
  }

  Future<int> _deleteWhereEquals({
    required String collection,
    required String field,
    required String value,
    int limit = 200,
  }) async {
    // NOTE: Firestore rules must allow user deletes for these docs.
    // If rules block, this throws and caller catches.
    final qs = await _db.collection(collection).where(field, isEqualTo: value).limit(limit).get();
    if (qs.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final d in qs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    return qs.size;
  }

  // -------------------------
  // Main load
  // -------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load resetAt first
      _resetAt = await _loadResetAt();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final startAt = _computeStartAt();

      // ---- BASIC COUNTS (health) ----
      final collections = <String>[
        'alerts',
        'community_reports',
        'community_alerts',
        'patrol_requests',
        'patrol_shifts',
        'patrol_shift_plans',
        'patrol_agents',
        'patrol_teams',
        'police_stations',
        'teams',
        'cctv_cameras',
      ];

      final counts = <String, int>{};
      for (final c in collections) {
        try {
          counts[c] = await _countColl(c);
        } catch (e) {
          counts[c] = -1;
          debugPrint('Count failed for $c: $e');
        }
      }

      // ---- PERFORMANCE + CHART DATA ----
      // We will:
      // - load alerts created (my alerts) for line chart + status dist
      // - load alerts accepted/resolved by me for bar chart
      // Note: queries are limited for safety; adjust later with aggregates.

      final perf = <String, dynamic>{};
      _alertsCreatedByDay = {};
      _acceptedByMe = 0;
      _resolvedByMe = 0;
      _statusDist = {'open': 0, 'accepted': 0, 'resolved': 0, 'other': 0};

      if (uid != null) {
        // ---- My alerts (created by me) ----
        Query<Map<String, dynamic>> myAlertsQ = _db.collection('alerts').where('userId', isEqualTo: uid);

        if (_area != 'ALL') {
          myAlertsQ = myAlertsQ.where('areaId', isEqualTo: _area);
        }
        if (startAt != null) {
          myAlertsQ = myAlertsQ.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startAt));
        }

        // Keep it reasonable for app-side grouping
        final myAlerts = await myAlertsQ.orderBy('createdAt', descending: true).limit(500).get();

        // Line chart: created per day + status distribution
        for (final d in myAlerts.docs) {
          final m = d.data();
          final ts = m['createdAt'];
          if (ts is Timestamp) {
            final day = _startOfDay(ts.toDate().toLocal());
            _alertsCreatedByDay[day] = (_alertsCreatedByDay[day] ?? 0) + 1;
          }

          final status = (m['status'] ?? 'open').toString().toLowerCase();
          if (_statusDist.containsKey(status)) {
            _statusDist[status] = (_statusDist[status] ?? 0) + 1;
          } else {
            _statusDist['other'] = (_statusDist['other'] ?? 0) + 1;
          }
        }

        // ---- Alerts accepted by me ----
        Query<Map<String, dynamic>> acceptedQ =
            _db.collection('alerts').where('acceptedBy', isEqualTo: uid);

        if (_area != 'ALL') {
          acceptedQ = acceptedQ.where('areaId', isEqualTo: _area);
        }
        if (startAt != null) {
          // acceptedAt might not exist on all docs; but query needs field to exist.
          // So we filter on createdAt for safety instead.
          acceptedQ = acceptedQ.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startAt));
        }

        final acceptedSnap = await acceptedQ.limit(500).get();
        _acceptedByMe = acceptedSnap.size;

        // ---- Alerts resolved by me ----
        Query<Map<String, dynamic>> resolvedQ =
            _db.collection('alerts').where('resolvedBy', isEqualTo: uid);

        if (_area != 'ALL') {
          resolvedQ = resolvedQ.where('areaId', isEqualTo: _area);
        }
        if (startAt != null) {
          resolvedQ = resolvedQ.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startAt));
        }

        final resolvedSnap = await resolvedQ.limit(500).get();
        _resolvedByMe = resolvedSnap.size;

        // ---- My reports ----
        Query<Map<String, dynamic>> myReportsQ =
            _db.collection('community_reports').where('userId', isEqualTo: uid);

        if (_area != 'ALL') {
          myReportsQ = myReportsQ.where('areaId', isEqualTo: _area);
        }
        if (startAt != null) {
          myReportsQ = myReportsQ.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startAt));
        }

        final myReports = await myReportsQ.orderBy('createdAt', descending: true).limit(500).get();

        // ---- My shifts ----
        Query<Map<String, dynamic>> myShiftsQ =
            _db.collection('patrol_shifts').where('agentId', isEqualTo: uid);

        if (_area != 'ALL') {
          myShiftsQ = myShiftsQ.where('areaId', isEqualTo: _area);
        }
        if (startAt != null) {
          // shifts use startAt
          myShiftsQ = myShiftsQ.where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startAt));
        }

        // Ordering by startAt may need an index if combined with other where
        QuerySnapshot<Map<String, dynamic>> myShifts;
        try {
          myShifts = await myShiftsQ.orderBy('startAt', descending: true).limit(200).get();
        } catch (_) {
          myShifts = await myShiftsQ.limit(200).get();
        }

        // Avg response time (acceptedAt -> resolvedAt) from alerts I resolved
        int totalMins = 0;
        int counted = 0;
        for (final d in resolvedSnap.docs) {
          final m = d.data();
          final a = m['acceptedAt'];
          final r = m['resolvedAt'];
          if (a is Timestamp && r is Timestamp) {
            totalMins += max(0, r.toDate().difference(a.toDate()).inMinutes);
            counted++;
          }
        }
        final avgResponse = counted == 0 ? 0.0 : (totalMins / counted);

        // Rating/hourlyRate from patrol_agents profile (optional)
        double rating = 0.0;
        int ratingCount = 0;
        double hourlyRate = 0.0;
        final profileSnap = await _db.collection('patrol_agents').doc(uid).get();
        if (profileSnap.exists) {
          final data = profileSnap.data() as Map<String, dynamic>;
          if (data['rating'] != null) rating = (data['rating'] as num).toDouble();
          if (data['ratingCount'] != null) ratingCount = (data['ratingCount'] as num).toInt();
          if (data['hourlyRate'] != null) hourlyRate = (data['hourlyRate'] as num).toDouble();
        }

        perf['myAlerts'] = myAlerts.size;
        perf['myReports'] = myReports.size;
        perf['myShifts'] = myShifts.size;
        perf['acceptedByMe'] = _acceptedByMe;
        perf['resolvedByMe'] = _resolvedByMe;
        perf['avgResponseMins'] = avgResponse;
        perf['rating'] = rating;
        perf['ratingCount'] = ratingCount;
        perf['hourlyRate'] = hourlyRate;
      } else {
        perf['note'] = 'Not signed in. Sign in to view per-user performance.';
      }

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _perf = perf;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // -------------------------
  // UI Widgets
  // -------------------------

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('❌ Stats failed: $_error', textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _filtersCard(uid: uid),
                    const SizedBox(height: 12),
                    _healthCard(),
                    const SizedBox(height: 12),
                    _performanceCard(uid: uid),
                    const SizedBox(height: 12),
                    _chartsCard(uid: uid),
                    const SizedBox(height: 12),
                    const Text(
                      'If any collection shows “Error reading”, it is either:\n'
                      '• Firestore rules blocking list/read\n'
                      '• collection name mismatch\n'
                      '• missing index (Firestore will show a link)\n',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
    );
  }

  Widget _filtersCard({required String? uid}) {
    final resetText = _resetAt == null ? '—' : _resetAt!.toLocal().toString().split('.').first;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StatsRange>(
                    value: _range,
                    decoration: const InputDecoration(
                      labelText: 'Range',
                      border: OutlineInputBorder(),
                    ),
                    items: StatsRange.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(_rangeLabel(r))))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _range = v);
                      await _load();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _area,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Default', child: Text('Default')),
                      DropdownMenuItem(value: 'ALL', child: Text('All areas')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _area = v);
                      await _load();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('Reset at: $resetText', style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: uid == null ? null : _resetMyStats,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset stats'),
                ),
                if (_enableDeleteMyData)
                  OutlinedButton.icon(
                    onPressed: uid == null ? null : _deleteMyData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete my data'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: _counts.entries.map((e) => _countTile(e.key, e.value)).toList(),
        ),
      ),
    );
  }

  Widget _countTile(String name, int v) {
    if (v == -1) {
      return ListTile(
        title: Text(name),
        subtitle: const Text('❌ Error reading (rules/collection/field issue)'),
      );
    }
    return ListTile(
      title: Text(name),
      trailing: Text(v.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _performanceCard({required String? uid}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: uid == null
            ? const Text('Sign in to see your performance.', style: TextStyle(color: Colors.orange))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _perfChip('My alerts', '${_perf['myAlerts'] ?? 0}'),
                      _perfChip('My reports', '${_perf['myReports'] ?? 0}'),
                      _perfChip('My shifts', '${_perf['myShifts'] ?? 0}'),
                      _perfChip('Accepted', '${_perf['acceptedByMe'] ?? 0}'),
                      _perfChip('Resolved', '${_perf['resolvedByMe'] ?? 0}'),
                      _perfChip('Avg response (min)',
                          ( (_perf['avgResponseMins'] as num?)?.toDouble() ?? 0.0 ).toStringAsFixed(1)),
                      _perfChip(
                        'Rating',
                        '⭐ ${( (_perf['rating'] as num?)?.toDouble() ?? 0.0 ).toStringAsFixed(1)}'
                        ' (${_perf['ratingCount'] ?? 0})',
                      ),
                      _perfChip(
                        'Rate',
                        (() {
                          final hr = ( (_perf['hourlyRate'] as num?)?.toDouble() ?? 0.0 );
                          return hr <= 0 ? 'Volunteer' : 'R ${hr.toStringAsFixed(0)}/hr';
                        })(),
                      ),
                    ],
                  ),
                  if (_perf['note'] != null) ...[
                    const SizedBox(height: 10),
                    Text(_perf['note'].toString(), style: const TextStyle(color: Colors.orange)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _perfChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _chartsCard({required String? uid}) {
    if (uid == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Sign in to see charts.', style: TextStyle(color: Colors.orange)),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Charts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Line chart: created per day
            const Text('Alerts created per day', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(height: 220, child: _lineChartAlertsCreated()),

            const SizedBox(height: 18),

            // Bar chart: accepted vs resolved by me
            const Text('Handled alerts', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: _barChartHandled()),

            const SizedBox(height: 18),

            // Pie chart: status distribution (my created alerts)
            const Text('My alert status distribution', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(height: 220, child: _pieChartStatus()),
          ],
        ),
      ),
    );
  }

  Widget _lineChartAlertsCreated() {
    final startAt = _computeStartAt();
    final now = DateTime.now();

    // Build day list for range charts; for "all time" or no start, we compress to last 30 days display.
    DateTime displayStart;
    int days;
    if (startAt == null) {
      displayStart = _startOfDay(now.subtract(const Duration(days: 29)));
      days = 30;
    } else {
      displayStart = _startOfDay(startAt);
      final diff = _startOfDay(now).difference(displayStart).inDays;
      days = min(90, max(7, diff + 1)); // keep chart readable
      displayStart = _startOfDay(_startOfDay(now).subtract(Duration(days: days - 1)));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < days; i++) {
      final day = displayStart.add(Duration(days: i));
      final v = (_alertsCreatedByDay[_startOfDay(day)] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), v));
    }

    if (spots.every((s) => s.y == 0)) {
      return const Center(child: Text('No alert data for this range.'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: max(1, (days / 6).floor()).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days) return const SizedBox.shrink();
                final d = displayStart.add(Duration(days: i));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true),
          ),
        ],
        minY: 0,
      ),
    );
  }

  Widget _barChartHandled() {
    final accepted = _acceptedByMe.toDouble();
    final resolved = _resolvedByMe.toDouble();

    if (accepted == 0 && resolved == 0) {
      return const Center(child: Text('No handled alerts for this range.'));
    }

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i == 0) return const Padding(padding: EdgeInsets.only(top: 6), child: Text('Accepted'));
                if (i == 1) return const Padding(padding: EdgeInsets.only(top: 6), child: Text('Resolved'));
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: accepted)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: resolved)]),
        ],
        minY: 0,
      ),
    );
  }

  Widget _pieChartStatus() {
    final data = Map<String, int>.from(_statusDist);
    data.removeWhere((k, v) => v <= 0);

    if (data.isEmpty) {
      return const Center(child: Text('No status data for this range.'));
    }

    final total = data.values.fold<int>(0, (a, b) => a + b);
    final keys = data.keys.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: List.generate(keys.length, (i) {
                final k = keys[i];
                final v = data[k]!;
                final pct = total == 0 ? 0.0 : (v / total) * 100.0;
                return PieChartSectionData(
                  value: v.toDouble(),
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 70,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: keys
                .map((k) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('$k: ${data[k]}'),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// Helper model for delete list
class _DeleteTarget {
  final String collection;
  final String ownerField;
  const _DeleteTarget(this.collection, this.ownerField);
}

// lib/police/police_dashboard_screen.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});

  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  final _db = FirebaseFirestore.instance;

  bool _busyNotify = false;
  bool _busyBroadcast = false;
  bool _busyDuty = false;

  String _area = 'Default';

  @override
  void initState() {
    super.initState();
    _loadMyArea();
  }

  Future<void> _loadMyArea() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final area = (data['areaId'] ?? data['area'] ?? 'Default').toString();
      if (mounted) setState(() => _area = area.isEmpty ? 'Default' : area);
    } catch (_) {
      // keep default
    }
  }

  // ---------------------------
  // QUICK: create an alert
  // ---------------------------
  Future<void> _notifyPolice() async {
    setState(() => _busyNotify = true);
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) throw Exception('Not signed in');

      await _db.collection('alerts').add({
        'userId': u.uid,
        'message': 'Police assistance requested 🚓',
        'areaId': _area,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'source': 'police_console',
      });

      // best-effort ping via function
      try {
        await http.post(
          Uri.parse('https://panicfanout-wezpkvn2eq-uc.a.run.app'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': 'Police assistance requested 🚓',
            'areaId': _area,
          }),
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Police alert created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyNotify = false);
    }
  }

  // ---------------------------
  // AVAILABILITY: on duty toggle
  // ---------------------------
  Stream<DocumentSnapshot<Map<String, dynamic>>> _myAvailabilityStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db.collection('availability').doc(uid).snapshots();
  }

  Future<void> _setOnDuty(bool onDuty) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    setState(() => _busyDuty = true);
    try {
      await _db.collection('availability').doc(u.uid).set({
        'uid': u.uid,
        'name': u.displayName ?? u.email ?? u.phoneNumber ?? 'Police',
        'role': 'police',
        'areaId': _area,
        'onDuty': onDuty,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(onDuty ? '✅ You are ON duty' : '✅ You are OFF duty'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update duty: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyDuty = false);
    }
  }

  // ---------------------------
  // BROADCAST: police -> community
  // ---------------------------
  Future<void> _composeBroadcast() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast to community'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Type message… e.g. Suspicious activity in Block F',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );

    if (ok != true) return;

    final msg = ctrl.text.trim();
    if (msg.isEmpty) return;

    setState(() => _busyBroadcast = true);
    try {
      await _db.collection('broadcasts').add({
        'source': 'police',
        'areaId': _area,
        'message': msg,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': u.uid,
        'createdByName': u.displayName ?? u.email ?? 'Police',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Broadcast sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Broadcast failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyBroadcast = false);
    }
  }

  // ---------------------------
  // UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final alertsInArea = _db
        .collection('alerts')
        .where('areaId', isEqualTo: _area)
        .orderBy('createdAt', descending: true)
        .limit(50);

    final broadcasts = _db
        .collection('broadcasts')
        .where('areaId', isEqualTo: _area)
        .orderBy('createdAt', descending: true)
        .limit(50);

    final onDutyPolice = _db
        .collection('availability')
        .where('role', isEqualTo: 'police')
        .where('areaId', isEqualTo: _area)
        .where('onDuty', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(
        title: Text('Police • $_area'),
        actions: [
          IconButton(
            tooltip: 'Add police/patrol/security',
            icon: const Icon(Icons.add_business),
            onPressed: () => Navigator.pushNamed(context, '/admin/directory'),
          ),
          IconButton(
            tooltip: 'Broadcast',
            icon: const Icon(Icons.campaign),
            onPressed: _busyBroadcast ? null : _composeBroadcast,
          ),
          IconButton(
            tooltip: 'Refresh area',
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyArea,
          ),
        ],
      ),
      body: Column(
        children: [
          _topActions(),
          _dutyCard(),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
                      Tab(icon: Icon(Icons.campaign), text: 'Broadcasts'),
                      Tab(icon: Icon(Icons.groups), text: 'On Duty'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _alertsTab(alertsInArea),
                        _broadcastsTab(broadcasts),
                        _onDutyTab(onDutyPolice),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busyNotify ? null : _notifyPolice,
              icon: _busyNotify
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.emergency_share),
              label: Text(_busyNotify ? 'Notifying…' : 'Create Police Alert'),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _busyBroadcast ? null : _composeBroadcast,
            icon: const Icon(Icons.campaign),
            label: Text(_busyBroadcast ? 'Sending…' : 'Broadcast to Community'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/nearby'),
            icon: const Icon(Icons.location_searching),
            label: const Text('Nearby Help'),
          ),
        ],
      ),
    );
  }

  Widget _dutyCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _myAvailabilityStream(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final onDuty = data['onDuty'] == true;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            child: ListTile(
              leading: Icon(
                onDuty ? Icons.check_circle : Icons.pause_circle,
                color: onDuty ? Colors.green : Colors.grey,
              ),
              title: Text(onDuty ? 'You are ON duty' : 'You are OFF duty'),
              subtitle: Text('Area: $_area'),
              trailing: _busyDuty
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Switch(
                      value: onDuty,
                      onChanged: (v) => _setOnDuty(v),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _alertsTab(Query<Map<String, dynamic>> query) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final docs = s.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No alerts in this area.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final m = d.data();
            final msg = (m['message'] ?? '').toString();
            final status = (m['status'] ?? 'open').toString();
            final ts = (m['createdAt'] as Timestamp?)?.toDate();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.notification_important),
                title: Text(msg.isEmpty ? '(no message)' : msg),
                subtitle: Text(
                  '${status.toUpperCase()} • ${ts == null ? '—' : '${ts.toLocal()}'.split('.').first}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _broadcastsTab(Query<Map<String, dynamic>> query) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final docs = s.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No broadcasts yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final m = d.data();
            final msg = (m['message'] ?? '').toString();
            final by = (m['createdByName'] ?? '').toString();
            final ts = (m['createdAt'] as Timestamp?)?.toDate();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.campaign),
                title: Text(msg),
                subtitle: Text(
                  '${by.isEmpty ? 'Police' : by} • ${ts == null ? '—' : '${ts.toLocal()}'.split('.').first}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _onDutyTab(Query<Map<String, dynamic>> query) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final docs = s.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No police marked ON duty.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final m = docs[i].data();
            final name = (m['name'] ?? 'Police').toString();
            final ts = (m['updatedAt'] as Timestamp?)?.toDate();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(name),
                subtitle: Text(ts == null ? '' : 'Updated: ${ts.toLocal()}'.split('.').first),
              ),
            );
          },
        );
      },
    );
  }
}

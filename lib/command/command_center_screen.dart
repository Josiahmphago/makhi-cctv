import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import '../services/dispatch_service.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() =>
      _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  String? _selectedAlertId;

  /// ==============================
  /// 📏 DISTANCE + ETA
  /// ==============================
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;

    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String _calculateETA(double km) {
    const speed = 40.0;
    final minutes = ((km / speed) * 60).round();
    return "${minutes == 0 ? 1 : minutes} mins";
  }

  /// ==============================
  /// 🗺️ MARKERS
  /// ==============================
  Set<Marker> _buildMarkers(
    List<QueryDocumentSnapshot> alerts,
    List<QueryDocumentSnapshot> patrols,
  ) {
    final markers = <Marker>{};
    final user = FirebaseAuth.instance.currentUser;

    Map<String, dynamic>? selectedAlertData;

    if (_selectedAlertId != null) {
      try {
        final selected =
            alerts.firstWhere((a) => a.id == _selectedAlertId);
        selectedAlertData =
            selected.data() as Map<String, dynamic>;
      } catch (_) {}
    }

    /// 🚨 ALERT
    for (var doc in alerts) {
      final data = doc.data() as Map<String, dynamic>;
      final loc = data['location'];
      if (loc == null) continue;

      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();

      markers.add(
        Marker(
          markerId: MarkerId("alert_${doc.id}"),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: "🚨 Emergency",
            onTap: () {
              setState(() {
                _selectedAlertId = doc.id;
              });
            },
          ),
        ),
      );
    }

    /// 🚓 PATROLS
    for (var doc in patrols) {
      final data = doc.data() as Map<String, dynamic>;
      final loc = data['location'];
      if (loc == null) continue;

      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();

      double hue = BitmapDescriptor.hueBlue;

      if (selectedAlertData != null) {
        final backups =
            List.from(selectedAlertData['backupPatrols'] ?? []);

        if (doc.id == selectedAlertData['assignedTo']) {
          hue = BitmapDescriptor.hueBlue;
        } else if (backups.contains(doc.id)) {
          hue = BitmapDescriptor.hueYellow;
        }

        final isSender =
            selectedAlertData['senderId'] == user?.uid;

        if (isSender &&
            doc.id != selectedAlertData['assignedTo'] &&
            !backups.contains(doc.id)) {
          continue;
        }
      }

      markers.add(
        Marker(
          markerId: MarkerId("patrol_${doc.id}"),
          position: LatLng(lat, lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    }

    return markers;
  }

  /// ==============================
  /// 🎯 ACTION PANEL
  /// ==============================
  Widget _actionPanel() {
    if (_selectedAlertId == null) return const SizedBox();

    return Positioned(
      bottom: 20,
      left: 10,
      right: 10,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('central_alarms')
            .doc(_selectedAlertId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final data =
              snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) return const SizedBox();

          final user = FirebaseAuth.instance.currentUser;

          final isSender = data['senderId'] == user?.uid;
          final isAssigned = data['assignedTo'] == user?.uid;

          final backups = List.from(data['backupPatrols'] ?? []);
          final isBackup = backups.contains(user?.uid);

          if (isSender) return _senderView(data);
          if (isAssigned) return _assignedView(data);
          if (isBackup) return _backupView(data);

          return _availablePatrolView(data);
        },
      ),
    );
  }

  /// ==============================
  /// 👤 SENDER (LIVE ETA)
  /// ==============================
  Widget _senderView(Map<String, dynamic> data) {
    final assignedTo = data['assignedTo'];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patrol_live')
          .doc(assignedTo)
          .snapshots(),
      builder: (context, patrolSnap) {
        String eta = "Calculating...";
        String distanceText = "";

        if (patrolSnap.hasData && patrolSnap.data!.exists) {
          final patrol =
              patrolSnap.data!.data() as Map<String, dynamic>;

          final pLoc = patrol['location'];
          final aLoc = data['location'];

          if (pLoc != null && aLoc != null) {
            final pLat = (pLoc['lat'] as num).toDouble();
            final pLng = (pLoc['lng'] as num).toDouble();

            final aLat = (aLoc['lat'] as num).toDouble();
            final aLng = (aLoc['lng'] as num).toDouble();

            final dist = _distanceKm(pLat, pLng, aLat, aLng);

            eta = _calculateETA(dist);
            distanceText = "${dist.toStringAsFixed(2)} km away";
          }
        }

        return Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🚨 Help is on the way"),
                Text("ETA: $eta"),
                Text(distanceText),
                Text("Status: ${data['status']}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _assignedView(Map<String, dynamic> data) {
    final alertId = _selectedAlertId!;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🚓 You are responding"),
          ElevatedButton(
            onPressed: () =>
                DispatchService.markArrived(alertId),
            child: const Text("ARRIVED"),
          ),
          ElevatedButton(
            onPressed: () =>
                DispatchService.completeAlert(alertId),
            child: const Text("COMPLETE"),
          ),
          ElevatedButton(
            onPressed: () =>
                DispatchService.addBackupPatrol(alertId: alertId),
            child: const Text("REQUEST BACKUP"),
          ),
        ],
      ),
    );
  }

  Widget _backupView(Map<String, dynamic> data) {
    final alertId = _selectedAlertId!;

    return Card(
      color: Colors.yellow.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🟡 Backup"),
          ElevatedButton(
            onPressed: () =>
                DispatchService.markArrived(alertId),
            child: const Text("ARRIVED"),
          ),
        ],
      ),
    );
  }

  Widget _availablePatrolView(Map<String, dynamic> data) {
    final alertId = _selectedAlertId!;
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🚨 Emergency nearby"),
          ElevatedButton(
            onPressed: () => DispatchService.acceptAlert(
              alertId: alertId,
              patrolId: user!.uid,
            ),
            child: const Text("ACCEPT"),
          ),
        ],
      ),
    );
  }

  Widget _panicButton() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          await FirebaseFirestore.instance
              .collection('central_alarms')
              .add({
            'senderId': user.uid,
            'status': 'active',
            'location': {
              'lat': -25.5089,
              'lng': 28.0508,
            },
            'triggeredAt': FieldValue.serverTimestamp(),
          });
        },
        child: const Icon(Icons.warning),
      ),
    );
  }

  /// ==============================
  /// 🔥 BUILD
  /// ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Command Center")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('central_alarms')
            .snapshots(),
        builder: (context, alertSnap) {
          if (!alertSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patrol_live')
                .snapshots(),
            builder: (context, patrolSnap) {
              if (!patrolSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = alertSnap.data!.docs;
              final patrols = patrolSnap.data!.docs;

              _markers = _buildMarkers(alerts, patrols);

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-25.5088, 28.0508),
                      zoom: 14,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),

                  _actionPanel(),
                  _panicButton(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
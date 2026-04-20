import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class DispatchService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🚓 ACCEPT ALERT
  static Future<void> acceptAlert({
    required String alertId,
    required String patrolId,
  }) async {
    final alertRef = _db.collection('central_alarms').doc(alertId);
    final patrolRef = _db.collection('patrol_live').doc(patrolId);

    final user = FirebaseAuth.instance.currentUser;

    await _db.runTransaction((tx) async {
      final alertSnap = await tx.get(alertRef);
      if (!alertSnap.exists) return;

      final data = alertSnap.data()!;
      final assignedTo = data['assignedTo'];

      if (assignedTo != null && assignedTo != patrolId) return;

      final userDoc =
          await _db.collection('users').doc(user?.uid).get();

      final userData = userDoc.data() ?? {};

      final name = userData['name'] ?? 'Patrol Unit';
      final phone = userData['phone'] ?? '';

      tx.update(alertRef, {
        'assignedTo': patrolId,
        'assignedName': name,
        'assignedPhone': phone,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'eta': '5 mins',
        'responders': FieldValue.arrayUnion([patrolId]),
      });

      tx.set(patrolRef, {
        'status': 'busy',
        'respondingTo': alertId,
        'responseRole': 'primary',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// 🟡 BACKUP FIXED
  static Future<void> addBackupPatrol({
    required String alertId,
  }) async {
    final alertRef = _db.collection('central_alarms').doc(alertId);

    final alertSnap = await alertRef.get();
    if (!alertSnap.exists) return;

    final alertData = alertSnap.data()!;
    final areaId = alertData['areaId'];
    final assignedTo = alertData['assignedTo'];

    final patrols = await _db
        .collection('patrol_live')
        .where('onDuty', isEqualTo: true)
        .where('areaId', isEqualTo: areaId)
        .get();

    for (final patrol in patrols.docs) {
      final patrolId = patrol.id;

      /// ❌ Skip primary patrol
      if (patrolId == assignedTo) continue;

      await _db.runTransaction((tx) async {
        final alertSnap = await tx.get(alertRef);
        if (!alertSnap.exists) return;

        final data = alertSnap.data()!;
        final List backups = List.from(data['backupPatrols'] ?? []);

        if (backups.contains(patrolId)) return;

        tx.update(alertRef, {
          'backupPatrols': FieldValue.arrayUnion([patrolId]),
          'responders': FieldValue.arrayUnion([patrolId]),
        });

        tx.set(
          _db.collection('patrol_live').doc(patrolId),
          {
            'status': 'busy',
            'respondingTo': alertId,
            'responseRole': 'backup',
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      break; // only 1 backup
    }
  }

  static Future<void> markArrived(String alertId) async {
    await _db.collection('central_alarms').doc(alertId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> completeAlert(String alertId) async {
    await _db.collection('central_alarms').doc(alertId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    await releaseAllResponders(alertId);
  }

  static Future<void> releaseAllResponders(String alertId) async {
    final alertSnap =
        await _db.collection('central_alarms').doc(alertId).get();

    if (!alertSnap.exists) return;

    final data = alertSnap.data()!;
    final primary = data['assignedTo'];
    final backups = List.from(data['backupPatrols'] ?? []);

    final ids = [
      if (primary != null) primary,
      ...backups,
    ];

    final batch = _db.batch();

    for (final id in ids) {
      final ref = _db.collection('patrol_live').doc(id);

      batch.set(ref, {
        'status': 'available',
        'respondingTo': null,
        'responseRole': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
  static Future<void> rejectAlert({
  required String alertId,
  required String patrolId,
}) async {
  final alertRef =
      FirebaseFirestore.instance.collection('central_alarms').doc(alertId);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(alertRef);
    if (!snap.exists) return;

    final data = snap.data()!;

    final List rejected =
        List.from(data['rejectedBy'] ?? []);

    /// 🚫 already rejected
    if (rejected.contains(patrolId)) return;

    tx.update(alertRef, {
      'rejectedBy': FieldValue.arrayUnion([patrolId]),
    });
  });

  /// 🔄 FREE patrol
  await FirebaseFirestore.instance
      .collection('patrol_live')
      .doc(patrolId)
      .set({
    'status': 'available',
    'respondingTo': null,
    'responseRole': null,
  }, SetOptions(merge: true));
}
static Future<void> smartAssignNearestPatrol({
  required String alertId,
}) async {
  final db = FirebaseFirestore.instance;

  final alertRef = db.collection('central_alarms').doc(alertId);
  final alertSnap = await alertRef.get();

  if (!alertSnap.exists) return;

  final data = alertSnap.data()!;

  /// already assigned
  if (data['assignedTo'] != null) return;

  final loc = data['location'];
  if (loc is! Map) return;

  final alertLat = (loc['lat'] as num?)?.toDouble();
  final alertLng = (loc['lng'] as num?)?.toDouble();

  if (alertLat == null || alertLng == null) return;

  final patrolSnap = await db
      .collection('patrol_live')
      .where('onDuty', isEqualTo: true)
      .get();

  double? bestDistance;
  String? bestPatrolId;

  for (final doc in patrolSnap.docs) {
    final patrol = doc.data();

    if ((patrol['status'] ?? '') == 'busy') continue;

    final pLoc = patrol['location'];
    if (pLoc is! Map) continue;

    final lat = (pLoc['lat'] as num?)?.toDouble();
    final lng = (pLoc['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) continue;

    final distance = _calculateDistance(
      alertLat,
      alertLng,
      lat,
      lng,
    );

    if (bestDistance == null || distance < bestDistance) {
      bestDistance = distance;
      bestPatrolId = doc.id;
    }
  }

  if (bestPatrolId == null) return;

  await acceptAlert(
    alertId: alertId,
    patrolId: bestPatrolId,
  );
}
static double _calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const R = 6371; // km

  final dLat = (lat2 - lat1) * (3.1415926535 / 180);
  final dLon = (lon2 - lon1) * (3.1415926535 / 180);

  final a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(lat1 * (3.1415926535 / 180)) *
          cos(lat2 * (3.1415926535 / 180)) *
          (sin(dLon / 2) * sin(dLon / 2));

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}
}
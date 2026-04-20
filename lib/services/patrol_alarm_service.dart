import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatrolAlarmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream alarms that patrol must respond to
  Stream<QuerySnapshot<Map<String, dynamic>>> streamActiveAlarms(String areaId) {
    return _db
        .collection('alarms')
        .where('areaId', isEqualTo: areaId)
        .where('status', whereIn: ['new', 'ack', 'responding'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ACK + LOCK alarm to current patrol member
  Future<void> acknowledgeAlarm({
    required String alarmId,
    required String patrolName,
  }) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('alarms').doc(alarmId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Alarm not found');

      final data = snap.data()!;
      if (data['lockedBy'] != null) {
        throw Exception('Alarm already locked');
      }

      tx.update(ref, {
        'status': 'ack',
        'lockedBy': uid,
        'lockedByName': patrolName,
        'lockedAt': FieldValue.serverTimestamp(),
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'acknowledgedByTeam': patrolName,
      });
    });
  }

  /// Patrol is on the way
  Future<void> respond(String alarmId) {
    return _db.collection('alarms').doc(alarmId).update({
      'status': 'responding',
    });
  }

  /// Close alarm
  Future<void> close(String alarmId) {
    return _db.collection('alarms').doc(alarmId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔁 Release alarms stuck in ACK for too long (5 min)
  Future<void> releaseExpiredLocks() async {
    final now = Timestamp.now();

    final snap = await _db
        .collection('alarms')
        .where('status', isEqualTo: 'ack')
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final lockedAt = data['lockedAt'];

      if (lockedAt is Timestamp) {
        final diff = now.seconds - lockedAt.seconds;

        if (diff >= 300) {
          await doc.reference.update({
            'status': 'new',
            'lockedBy': null,
            'lockedByName': null,
            'lockedAt': null,
          });
        }
      }
    }
  }
}

// lib/services/patrol_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatrolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ===============================
  // ON DUTY
  // ===============================

  Future<void> setMyOnDuty({
    required bool onDuty,
    String? area,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection('patrol_agents').doc(uid).set({
      'onDuty': onDuty,
      'areaId': area,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<int> streamOnDutyCount({String? area}) {
    Query query = _db
        .collection('patrol_agents')
        .where('onDuty', isEqualTo: true);

    if (area != null) {
      query = query.where('areaId', isEqualTo: area);
    }

    return query.snapshots().map((s) => s.size);
  }

  // ===============================
  // SHIFT PLANS
  // ===============================

  Future<void> createShiftPlan({
    required String areaId,
    required DateTime plannedStart,
    required DateTime plannedEnd,
    required int reminderMinutes,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection('patrol_shift_plans').add({
      'agentId': uid,
      'areaId': areaId,
      'plannedStartAt': Timestamp.fromDate(plannedStart),
      'plannedEndAt': Timestamp.fromDate(plannedEnd),
      'reminderMinutes': reminderMinutes,
      'status': 'planned',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyNextPlan({
    String? areaId,
  }) {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }

    Query<Map<String, dynamic>> query = _db
        .collection('patrol_shift_plans')
        .where('agentId', isEqualTo: uid)
        .where('status', isEqualTo: 'planned')
        .orderBy('plannedStartAt')
        .limit(1);

    if (areaId != null) {
      query = query.where('areaId', isEqualTo: areaId);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAreaPlans({
    required String areaId,
    required int withinHours,
  }) {
    final now = DateTime.now();
    final until = now.add(Duration(hours: withinHours));

    return _db
        .collection('patrol_shift_plans')
        .where('areaId', isEqualTo: areaId)
        .where(
          'plannedStartAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(now),
        )
        .where(
          'plannedStartAt',
          isLessThanOrEqualTo: Timestamp.fromDate(until),
        )
        .orderBy('plannedStartAt')
        .snapshots();
  }

  Future<void> cancelShiftPlan(String planId) async {
    await _db.collection('patrol_shift_plans').doc(planId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }
}

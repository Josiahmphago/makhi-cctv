import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dispatch_service.dart';

class ResponseService {
  static final _db = FirebaseFirestore.instance;

  /// ==========================================================
  /// 📍 MARK ARRIVED
  /// ==========================================================
  static Future<void> markArrived(String alertId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('central_alarms').doc(alertId).update({
        'status': 'arrived',
        'arrivedAt': FieldValue.serverTimestamp(),
      });

      print('📍 Patrol ARRIVED');
    } catch (e) {
      print('❌ markArrived error: $e');
    }
  }

  /// ==========================================================
  /// ✅ COMPLETE RESPONSE
  /// ==========================================================
 static Future<void> completeResponse(String alertId) async {
  final db = FirebaseFirestore.instance;

  try {
    print("🔥 COMPLETING ALERT: $alertId");

    /// ✅ COMPLETE ALERT
    await db.collection('central_alarms').doc(alertId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    print("✅ ALERT MARKED COMPLETED");

    /// 🔥 FORCE RESET ALL PATROLS (NO MATCHING)
    final patrols = await db.collection('patrol_live').get();

    for (final doc in patrols.docs) {
      final data = doc.data();

      /// ONLY reset patrols that are busy
      if (data['status'] == 'busy') {
        print("🔓 Resetting patrol ${doc.id}");

        await doc.reference.update({
          'status': 'available',
          'respondingTo': FieldValue.delete(),
          'responseRole': FieldValue.delete(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }

    print("✅ ALL PATROLS RESET");
  } catch (e) {
    print("❌ COMPLETE ERROR: $e");
  }
}
  /// ==========================================================
  /// 🔓 RELEASE ALL RESPONDERS
  /// ==========================================================
 static Future<void> forceReleaseAllPatrols(String alertId) async {
  final db = FirebaseFirestore.instance;

  final snapshot = await db.collection('patrol_live').get();

  for (final doc in snapshot.docs) {
    await doc.reference.update({
      'status': 'available',
      'onDuty': true,
      'respondingTo': null,
      'responseRole': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  print("🔥 ALL PATROLS FORCE RESET");
}
}
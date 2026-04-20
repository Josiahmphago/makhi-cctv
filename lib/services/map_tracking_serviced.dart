import 'package:cloud_firestore/cloud_firestore.dart';

class MapTrackingService {
  static final _db = FirebaseFirestore.instance;

  /// 🚨 ACTIVE ALERTS WITH PATROLS
  static Stream<List<Map<String, dynamic>>> getActiveDispatches() {
    return _db
        .collection('central_alarms')
        .where('status', isEqualTo: 'assigned')
        .snapshots()
        .asyncMap((alertSnapshot) async {
      List<Map<String, dynamic>> result = [];

      for (final alert in alertSnapshot.docs) {
        final data = alert.data();

        final assignedTo = data['assignedTo'];
        if (assignedTo == null) continue;

        final patrolDoc =
            await _db.collection('patrol_live').doc(assignedTo).get();

        if (!patrolDoc.exists) continue;

        final patrolData = patrolDoc.data();

        result.add({
          'alertId': alert.id,
          'alertLocation': data['location'],
          'patrolLocation': patrolData?['location'],
          'patrolId': assignedTo,
        });
      }

      return result;
    });
  }
}
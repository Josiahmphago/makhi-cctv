import 'package:cloud_firestore/cloud_firestore.dart';

/// Finds phone numbers for responders currently ON DUTY.
///
/// IMPORTANT:
/// - Your patrol shifts use: startAt, endAt, status='open'/'closed'
/// - Your police shifts should follow same pattern (recommended)
///
/// This function is "phase 1": just returns phone numbers.
/// Phase 2 can filter by area/geohash distance, team, etc.
class ShiftAssignmentService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<String>> getOnDutyResponders({
    required String responderType, // 'police' or 'patrol'
    String? areaId, // optional filter
  }) async {
    final responders = <String>[];

    final collection = responderType == 'police' ? 'police_shifts' : 'patrol_shifts';

    // ✅ Prefer status='open' — matches your PatrolDashboard shift logic
    Query<Map<String, dynamic>> q = _db
        .collection(collection)
        .where('status', isEqualTo: 'open');

    // Optional filter if you store areaId on police_shifts too
    if (areaId != null && areaId.trim().isNotEmpty) {
      q = q.where('areaId', isEqualTo: areaId.trim());
    }

    final snap = await q.orderBy('startAt', descending: true).limit(50).get();

    for (final doc in snap.docs) {
      final data = doc.data();

      // Accept any of these names (so you don't get stuck with one schema)
      final phone = (data['contactPhone'] ??
              data['phoneNumber'] ??
              data['phone'] ??
              data['whatsapp'])
          ?.toString()
          .trim();

      if (phone != null && phone.isNotEmpty) responders.add(phone);
    }

    // de-dupe
    return responders.toSet().toList();
  }
}

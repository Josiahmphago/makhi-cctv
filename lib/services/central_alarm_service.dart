import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CentralAlarmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> triggerAlarm({
    required String areaId,
    required double lat,
    required double lng,
    required String address,
    String source = "phone_panic",
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    /// 🔥 GET USER DATA
    final userDoc =
        await _db.collection('users').doc(user.uid).get();

    final userData = userDoc.data() ?? {};

    final userName = userData['name'] ?? 'Unknown';
    final userRole = userData['role'] ?? 'citizen';

    /// 🔥 SINGLE CLEAN ALERT (NO DUPLICATE)
    await _db.collection('central_alarms').add({
      'areaId': areaId,
      'source': source,

      /// ✅ WHO SENT ALERT
      'createdBy': user.uid,
      'createdByName': userName,
      'createdByRole': userRole,

      /// ✅ LOCATION
      'location': {
        'lat': lat,
        'lng': lng,
      },

      'address': address,

      /// ✅ STATUS FLOW
      'status': 'pending',
      'assignedTo': null,
      'backupPatrols': [],

      /// ✅ TIMESTAMP
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("🚨 Alarm triggered by $userName");
  }
}
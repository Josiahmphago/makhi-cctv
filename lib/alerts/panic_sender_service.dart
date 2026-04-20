import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../location/location_service.dart';

class PanicService {
  static Future<void> triggerPanic({
    required String message,
    required String areaId,
    required String source,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final pos = await LocationService.current();

    final lat = pos?.latitude;
    final lng = pos?.longitude;

    await FirebaseFirestore.instance.collection('central_alarms').add({
      'areaId': areaId,
      'type': 'panic',
      'status': 'new', // 🔥 IMPORTANT
      'alarmActive': true,
      'source': source,
      'message': message,
      'senderId': user.uid,
      'senderName': (user.displayName ?? '').isNotEmpty
          ? user.displayName
          : user.email ?? 'Community Member',
      'triggeredAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'location': {
        'lat': lat,
        'lng': lng,
      },
    });
  }
}
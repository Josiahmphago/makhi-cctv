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

    double? lat, lng;
    final pos = await LocationService.current();
    if (pos != null) {
      lat = pos.latitude;
      lng = pos.longitude;
    }

    await FirebaseFirestore.instance.collection('central_alarms').add({
      'areaId': areaId,
      'type': 'panic',
      'status': 'new',
      'source': source,
      'message': message,
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Community Member',
      'createdAt': FieldValue.serverTimestamp(),
      if (lat != null && lng != null)
        'location': {
          'lat': lat,
          'lng': lng,
        },
    });

    print("🚨 Panic written to central_alarms");
  }
}
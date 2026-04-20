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

    // Make sure senderName is NEVER empty
    final rawName = (user.displayName ?? '').trim();
    final senderName = rawName.isNotEmpty ? rawName : 'Community Member';

    double? lat, lng;
    final pos = await LocationService.current();
    if (pos != null) {
      lat = pos.latitude;
      lng = pos.longitude;
    }

    final payload = <String, dynamic>{
      'areaId': areaId,
      'type': 'panic',
      'status': 'new', // IMPORTANT: matches UI buttons
      'source': source,
      'message': message,
      'senderId': user.uid,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
      'triggeredAt': FieldValue.serverTimestamp(), // keep both for compatibility
    };

    // Store location in ONE consistent place
    if (lat != null && lng != null) {
      payload['location'] = {'lat': lat, 'lng': lng};
      payload['lat'] = lat; // optional: keep old compatibility
      payload['lng'] = lng; // optional: keep old compatibility
    }

    final docRef =
        await FirebaseFirestore.instance.collection('central_alarms').add(payload);

    print("🚨 Panic written to central_alarms: ${docRef.id}");
  }
}
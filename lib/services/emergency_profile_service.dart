import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyProfileService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> saveEmergencyProfile({
    required List<String> contactNumbers,
    required List<String> groupIds,
    required bool sendLocation,
    required bool sendImage,
    required String mode, // 'text', 'picture', 'silent'
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('emergency_profiles').doc(uid).set({
      'contacts': contactNumbers,
      'groups': groupIds,
      'sendLocation': sendLocation,
      'sendImage': sendImage,
      'mode': mode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getEmergencyProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('emergency_profiles').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}

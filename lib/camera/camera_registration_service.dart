import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CameraRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> registerCamera({
    required String cameraId,
    required String location,
    required bool isMobile,
    required String currentIP,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore.collection('cameras').doc(cameraId).set({
      'cameraId': cameraId,
      'ownerUid': user.uid,
      'location': location,
      'isMobile': isMobile,
      'lastKnownIP': currentIP,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EscortService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  EscortService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ==========================================================
  // CREATE ESCORT REQUEST
  // ==========================================================

  Future<String> createEscortRequest({
    required int etaMinutes,
    required String destinationText,
    required GeoPoint userLocation,
    String? message,
    GeoPoint? destinationPin,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Not signed in');
    }

    final doc = _db.collection('escort_requests').doc();

    /// ✅ CREATE ESCORT REQUEST
    await doc.set({
      'userId': user.uid,
      'status': 'open', // open -> ack -> closed

      'etaMinutes': etaMinutes,
      'destinationText': destinationText.trim(),
      'destination': destinationPin,

      'message': (message == null || message.trim().isEmpty)
          ? null
          : message.trim(),

      'location': userLocation,

      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.fromDate(DateTime.now()),

      // acknowledgment
      'ackBy': null,
      'ackAt': null,
      'ackRole': null,

      // closing
      'closedAt': null,
    });

    /// 🔴 CREATE CENTRAL ALARM (STANDARDIZED)
    await _db.collection('central_alarms').doc(doc.id).set({
      'type': 'request',
      'source': 'escort',

      'status': 'active',

      'title': '🟦 Escort Request',
      'description': destinationText,

      'senderId': user.uid,
      'senderName': user.email ?? 'Unknown',

      'triggeredAt': FieldValue.serverTimestamp(),

      'location': {
        'lat': userLocation.latitude,
        'lng': userLocation.longitude,
      },

      'requestId': doc.id, // 🔥 important for linking
    });

    return doc.id;
  }

  // ==========================================================
  // MY REQUESTS
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> myRequests() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return const Stream.empty();

    return _db
        .collection('escort_requests')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAtClient', descending: true)
        .snapshots();
  }

  // ==========================================================
  // WATCH SINGLE REQUEST
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRequest(
      String requestId) {
    return _db.collection('escort_requests').doc(requestId).snapshots();
  }

  // ==========================================================
  // WATCH RESPONDERS
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchResponders(
      String requestId) {
    return _db
        .collection('escort_requests')
        .doc(requestId)
        .collection('responders')
        .orderBy('respondedAt', descending: false)
        .snapshots();
  }

  // ==========================================================
  // CLOSE REQUEST
  // ==========================================================

  Future<void> closeRequest(String requestId) async {
    /// ✅ CLOSE ESCORT REQUEST
    await _db.collection('escort_requests').doc(requestId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });

    /// ✅ UPDATE CENTRAL ALARM (DO NOT RECREATE)
    await _db.collection('central_alarms').doc(requestId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
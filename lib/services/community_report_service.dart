// lib/services/community_report_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../location/geohash.dart';
import '../location/location_service.dart';

class CommunityReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadReportPhoto({
    required File file,
    required String reportId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final ref = _storage
        .ref()
        .child('community_reports')
        .child(uid)
        .child(reportId)
        .child('photo.jpg');

    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> createReport({
    required String type,
    required String description,
    required String areaId,
    String? addressText,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final pos = await LocationService.current();
    if (pos == null) throw Exception('Location unavailable');

    final lat = pos.latitude;
    final lng = pos.longitude;

    final doc = _db.collection('community_reports').doc();

    await doc.set({
      'type': type,
      'description': description,
      'areaId': areaId,

      'lat': lat,
      'lng': lng,
      'geohash': GeoHash.encode(lat, lng, precision: 7),

      'addressText': addressText,
      'photoUrl': photoUrl,

      'status': 'new',
      'userId': user.uid,

      // 🔥 AUTO ROUTING
      'autoRouted': true,
      'recipientTargets': ['patrol', 'police'],

      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.now(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyReports({
    String? areaId,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    Query<Map<String, dynamic>> q =
        _db.collection('community_reports').where('userId', isEqualTo: uid);

    if (areaId != null && areaId.isNotEmpty) {
      q = q.where('areaId', isEqualTo: areaId);
    }

    return q
        .orderBy('createdAtClient', descending: true)
        .snapshots();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cctv_camera.dart';

class CCTVService {
  final _cameras = FirebaseFirestore.instance.collection('cctv_cameras');
  final _users = FirebaseFirestore.instance.collection('users');
  final _panicSettings =
      FirebaseFirestore.instance.collection('panic_settings');

  Future<void> addCamera(CCTVCamera cam) async {
    await _cameras.add(cam.toMap());
  }

  Stream<List<CCTVCamera>> streamAllCameras() {
    return _cameras.snapshots().map((snap) => snap.docs
        .map((doc) => CCTVCamera.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Stream<List<CCTVCamera>> streamCamerasByArea(String area) {
    return _cameras.where('area', isEqualTo: area).snapshots().map((snap) =>
        snap.docs
            .map((doc) =>
                CCTVCamera.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateCamera(CCTVCamera cam) async {
    await _cameras.doc(cam.id).update(cam.toMap());
  }

  Future<void> deleteCamera(String id) async {
    await _cameras.doc(id).delete();
  }

  /// ✅ NEW: fetch the user's assigned area from panic_settings
  Future<String?> getUserArea([String? userId]) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _panicSettings.doc(uid).get();
    if (doc.exists) {
      return doc.data()?['areaAssigned'] as String?;
    }
    return null;
  }
}

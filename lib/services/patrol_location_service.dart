import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PatrolLocationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static StreamSubscription<Position>? _positionStream;

  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static Future<void> startTracking() async {
    if (_uid.isEmpty) return;

    await _positionStream?.cancel();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) async {
      try {
        await _db.collection('patrol_live').doc(_uid).set({
          'userId': _uid,
          'isOnline': true,
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  static Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    if (_uid.isEmpty) return;

    await _db.collection('patrol_live').doc(_uid).set({
      'isOnline': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setBusy({required String areaId}) async {
    if (_uid.isEmpty) return;

    await _db.collection('patrol_live').doc(_uid).set({
      'userId': _uid,
      'areaId': areaId,
      'isOnline': true,
      'isAvailable': false,
      'status': 'busy',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setAvailable({required String areaId}) async {
    if (_uid.isEmpty) return;

    await _db.collection('patrol_live').doc(_uid).set({
      'userId': _uid,
      'areaId': areaId,
      'isOnline': true,
      'isAvailable': true,
      'status': 'available',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
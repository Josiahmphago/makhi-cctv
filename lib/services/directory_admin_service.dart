// lib/services/directory_admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

class DirectoryAdminService {
  final _db = FirebaseFirestore.instance;

  String _makeGeohash(double lat, double lng) {
    // dart_geohash expects (lon, lat)
    return GeoHasher().encode(lng, lat, precision: 9);
  }

  Future<String> upsert({
    required String collection,
    String? docId,

    required String name,
    required String phoneNumber,
    required String whatsapp,
    required String addressText,
    required bool enabled,
    required String serviceType,

    double? lat,
    double? lng,
  }) async {
    final ref = (docId == null || docId.isEmpty)
        ? _db.collection(collection).doc()
        : _db.collection(collection).doc(docId);

    final data = <String, dynamic>{
      'name': name,
      'phoneNumber': phoneNumber,
      'whatsapp': whatsapp,
      'addressText': addressText,
      'enabled': enabled,
      'serviceType': serviceType,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (lat != null && lng != null) {
      data['location'] = {
        'lat': lat,
        'lng': lng,
        'geohash': _makeGeohash(lat, lng),
      };
    }

    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> delete({
    required String collection,
    required String docId,
  }) async {
    await _db.collection(collection).doc(docId).delete();
  }

  Future<void> setEnabled({
    required String collection,
    required String docId,
    required bool enabled,
  }) async {
    await _db.collection(collection).doc(docId).set(
      {'enabled': enabled, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Seeds sample docs near a base coordinate (lat/lng).
  Future<void> seedNear({
    required double lat,
    required double lng,
  }) async {
    // 2 police + 2 patrol (offset slightly)
    await upsert(
      collection: 'police_stations',
      name: 'SAPS - Demo Station A',
      phoneNumber: '+27000000001',
      whatsapp: '',
      addressText: 'Demo Police Station A',
      enabled: true,
      serviceType: 'police',
      lat: lat + 0.002,
      lng: lng + 0.002,
    );

    await upsert(
      collection: 'police_stations',
      name: 'SAPS - Demo Station B',
      phoneNumber: '+27000000002',
      whatsapp: '',
      addressText: 'Demo Police Station B',
      enabled: true,
      serviceType: 'police',
      lat: lat - 0.002,
      lng: lng - 0.002,
    );

    await upsert(
      collection: 'patrol_teams',
      name: 'Patrol Team - Demo A',
      phoneNumber: '+27000000011',
      whatsapp: '',
      addressText: 'Demo Patrol Team A',
      enabled: true,
      serviceType: 'patrol',
      lat: lat + 0.001,
      lng: lng - 0.001,
    );

    await upsert(
      collection: 'patrol_teams',
      name: 'Patrol Team - Demo B',
      phoneNumber: '+27000000012',
      whatsapp: '',
      addressText: 'Demo Patrol Team B',
      enabled: true,
      serviceType: 'patrol',
      lat: lat - 0.001,
      lng: lng + 0.001,
    );

    // optional: one alert group (no location required, but we can include)
    await upsert(
      collection: 'alert_groups',
      name: 'Community Group - Demo',
      phoneNumber: '+27000000021',
      whatsapp: '',
      addressText: 'Demo Alert Group',
      enabled: true,
      serviceType: 'group',
      lat: null,
      lng: null,
    );
  }
}

// lib/services/patrol_alert_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PatrolAlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAlertsForArea(String areaId) {
    return _db
        .collection('alerts')
        .where('areaId', isEqualTo: areaId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

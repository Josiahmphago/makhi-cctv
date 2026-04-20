import 'package:cloud_firestore/cloud_firestore.dart';

class EscortResponder {
  final String id;
  final String userId;
  final String name;
  final bool isVerified;
  final double distanceKm;
  final DateTime respondedAt;
  final String status; // available, accepted, rejected

  EscortResponder({
    required this.id,
    required this.userId,
    required this.name,
    required this.isVerified,
    required this.distanceKm,
    required this.respondedAt,
    required this.status,
  });

  static EscortResponder fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EscortResponder(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      name: (data['name'] ?? 'Responder') as String,
      isVerified: (data['isVerified'] ?? false) as bool,
      distanceKm: ((data['distanceKm'] ?? 0) as num).toDouble(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (data['status'] ?? 'available') as String,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class EscortRequest {
  final String id;
  final String userId;
  final String status; // open, assigned, closed, cancelled
  final int etaMinutes;
  final String destinationText;
  final GeoPoint? destination; // optional pin
  final String? message;
  final GeoPoint userLocation;
  final DateTime createdAt;

  EscortRequest({
    required this.id,
    required this.userId,
    required this.status,
    required this.etaMinutes,
    required this.destinationText,
    required this.userLocation,
    required this.createdAt,
    this.destination,
    this.message,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'status': status,
        'etaMinutes': etaMinutes,
        'destinationText': destinationText,
        'destination': destination,
        'message': message,
        'userLocation': userLocation,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static EscortRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EscortRequest(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      status: (data['status'] ?? 'open') as String,
      etaMinutes: (data['etaMinutes'] ?? 15) as int,
      destinationText: (data['destinationText'] ?? '') as String,
      destination: data['destination'] as GeoPoint?,
      message: data['message'] as String?,
      userLocation: (data['userLocation'] ?? const GeoPoint(0, 0)) as GeoPoint,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

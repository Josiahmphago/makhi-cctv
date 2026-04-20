import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  // --- Existing fields (unchanged) ---
  final String id;
  final String senderId;
  final String message;
  final GeoPoint location;
  final String? imageUrl;
  final bool isSilent;
  final Timestamp timestamp;
  final List<String> recipients;
  final bool confirmed;

  // --- New optional fields (for groups & delivery meta) ---
  final String? alertType;           // e.g., "Emergency", "Escort", "Car Breakdown"
  final String? method;              // e.g., "SMS", "WhatsApp", "Telegram", "All"
  final List<String> groupIds;       // e.g., ["police", "patrol"]
  final List<String> groupNames;     // e.g., ["Police", "Patrol"]
  final int? sentCount;              // how many destinations actually sent
  final int? skippedCount;           // e.g., unverified in Twilio trial

  const AlertModel({
    // required (existing)
    required this.id,
    required this.senderId,
    required this.message,
    required this.location,
    required this.recipients,
    this.imageUrl,
    required this.isSilent,
    required this.timestamp,
    required this.confirmed,

    // optional (new)
    this.alertType,
    this.method,
    this.groupIds = const [],
    this.groupNames = const [],
    this.sentCount,
    this.skippedCount,
  });

  // Safer map -> model
  factory AlertModel.fromMap(Map<String, dynamic> map) {
    // Defensive parsing
    final recipientsRaw = map['recipients'];
    final List<String> recipients = recipientsRaw is Iterable
        ? recipientsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final groupIdsRaw = map['groupIds'];
    final List<String> groupIds = groupIdsRaw is Iterable
        ? groupIdsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final groupNamesRaw = map['groupNames'];
    final List<String> groupNames = groupNamesRaw is Iterable
        ? groupNamesRaw.map((e) => e.toString()).toList()
        : <String>[];

    // location & timestamp guard
    final loc = map['location'];
    final GeoPoint location =
        loc is GeoPoint ? loc : GeoPoint(0, 0);

    final ts = map['timestamp'];
    final Timestamp timestamp =
        ts is Timestamp ? ts : Timestamp.now();

    return AlertModel(
      id: (map['id'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      location: location,
      imageUrl: map['imageUrl']?.toString(),
      isSilent: (map['isSilent'] is bool) ? map['isSilent'] as bool : false,
      timestamp: timestamp,
      recipients: recipients,
      confirmed: (map['confirmed'] is bool) ? map['confirmed'] as bool : false,

      alertType: map['alertType']?.toString(),
      method: map['method']?.toString(),
      groupIds: groupIds,
      groupNames: groupNames,
      sentCount: map['sentCount'] is num ? (map['sentCount'] as num).toInt() : null,
      skippedCount: map['skippedCount'] is num ? (map['skippedCount'] as num).toInt() : null,
    );
  }

  // Firestore doc -> model
  factory AlertModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    // Prefer explicit id field if present, else doc.id
    data.putIfAbsent('id', () => doc.id);
    return AlertModel.fromMap(data);
  }

  // Model -> map (only write meaningful fields)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'senderId': senderId,
      'message': message,
      'location': location,
      'isSilent': isSilent,
      'timestamp': timestamp,
      'recipients': recipients,
      'confirmed': confirmed,
    };

    if (imageUrl != null && imageUrl!.isNotEmpty) map['imageUrl'] = imageUrl;
    if (alertType != null && alertType!.isNotEmpty) map['alertType'] = alertType;
    if (method != null && method!.isNotEmpty) map['method'] = method;
    if (groupIds.isNotEmpty) map['groupIds'] = groupIds;
    if (groupNames.isNotEmpty) map['groupNames'] = groupNames;
    if (sentCount != null) map['sentCount'] = sentCount;
    if (skippedCount != null) map['skippedCount'] = skippedCount;

    return map;
  }

  // Handy updater
  AlertModel copyWith({
    String? id,
    String? senderId,
    String? message,
    GeoPoint? location,
    String? imageUrl,
    bool? isSilent,
    Timestamp? timestamp,
    List<String>? recipients,
    bool? confirmed,
    String? alertType,
    String? method,
    List<String>? groupIds,
    List<String>? groupNames,
    int? sentCount,
    int? skippedCount,
  }) {
    return AlertModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isSilent: isSilent ?? this.isSilent,
      timestamp: timestamp ?? this.timestamp,
      recipients: recipients ?? this.recipients,
      confirmed: confirmed ?? this.confirmed,
      alertType: alertType ?? this.alertType,
      method: method ?? this.method,
      groupIds: groupIds ?? this.groupIds,
      groupNames: groupNames ?? this.groupNames,
      sentCount: sentCount ?? this.sentCount,
      skippedCount: skippedCount ?? this.skippedCount,
    );
  }
}

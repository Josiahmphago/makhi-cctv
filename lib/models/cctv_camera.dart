class CCTVCamera {
  final String id;
  final String name;
  final String location;
  final String type;
  final bool isActive;
  final String patrolTeamId;
  final String ownerName;
  final String ownerContact;
  final String area;
  final String ipAddress; // ✅ NEW

  CCTVCamera({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.isActive,
    required this.patrolTeamId,
    required this.ownerName,
    required this.ownerContact,
    required this.area,
    required this.ipAddress,
  });

  /// Convert object → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'type': type,
      'isActive': isActive,
      'patrolTeamId': patrolTeamId,
      'ownerName': ownerName,
      'ownerContact': ownerContact,
      'area': area,
      'ipAddress': ipAddress,
    };
  }

  /// Convert Firestore map → object
  factory CCTVCamera.fromMap(Map<String, dynamic> map, String docId) {
    return CCTVCamera(
      id: docId,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? 'street',
      isActive: map['isActive'] ?? true,
      patrolTeamId: map['patrolTeamId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerContact: map['ownerContact'] ?? '',
      area: map['area'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
    );
  }
}

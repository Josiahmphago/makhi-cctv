class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? note;
  final String? priority;
  final String? relationshipType;
  final String? group;
  final String ownerId;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.note,
    this.priority,
    this.relationshipType,
    this.group,
    required this.ownerId,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> data, String id) {
    return EmergencyContact(
      id: id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      note: data['note'],
      priority: data['priority'],
      relationshipType: data['relationshipType'],
      group: data['group'],
      ownerId: data['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'note': note,
      'priority': priority,
      'relationshipType': relationshipType,
      'group': group,
      'ownerId': ownerId,
    };
  }
}

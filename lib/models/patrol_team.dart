class PatrolTeam {
  final String id;
  final String name;
  final String areaCovered;
  final String shiftType;
  final bool isActive;
  final List<Patroller> members;

  PatrolTeam({
    required this.id,
    required this.name,
    required this.areaCovered,
    required this.shiftType,
    required this.isActive,
    required this.members,
  });

  factory PatrolTeam.fromMap(String id, Map<String, dynamic> data) {
    final membersList = (data['members'] as List<dynamic>? ?? []).map((m) {
      return Patroller(
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        role: m['role'] ?? '',
      );
    }).toList();

    return PatrolTeam(
      id: id,
      name: data['name'],
      areaCovered: data['areaCovered'],
      shiftType: data['shiftType'],
      isActive: data['isActive'],
      members: membersList,
    );
  }
}

class Patroller {
  final String name;
  final String phone;
  final String role;

  Patroller({required this.name, required this.phone, required this.role});
}

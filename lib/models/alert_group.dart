import 'package:cloud_firestore/cloud_firestore.dart';

class AlertGroup {
  final String id;               // e.g. "police"
  final String name;             // e.g. "Police"
  final List<String> numbers;    // default recipients if no team is chosen
  final String? emoji;           // optional: "🚔"
  final int? priority;           // optional sort (1 = top)

  // NEW: teams/shifts under this group
  final List<GroupTeam> teams;

  AlertGroup({
    required this.id,
    required this.name,
    required this.numbers,
    this.emoji,
    this.priority,
    this.teams = const [],
  });

  factory AlertGroup.fromMap(String id, Map<String, dynamic> data) {
    final teamsRaw = (data['teams'] as List<dynamic>? ?? []);
    return AlertGroup(
      id: id,
      name: (data['name'] ?? id).toString(),
      numbers: (data['numbers'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      emoji: data['emoji']?.toString(),
      priority: (data['priority'] is num) ? (data['priority'] as num).toInt() : null,
      teams: teamsRaw.map((t) => GroupTeam.fromMap((t as Map).cast<String, dynamic>())).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'numbers': numbers,
      if (emoji != null) 'emoji': emoji,
      if (priority != null) 'priority': priority,
      if (teams.isNotEmpty) 'teams': teams.map((t) => t.toMap()).toList(),
    };
  }

  AlertGroup copyWith({
    String? id,
    String? name,
    List<String>? numbers,
    String? emoji,
    int? priority,
    List<GroupTeam>? teams,
  }) {
    return AlertGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      numbers: numbers ?? this.numbers,
      emoji: emoji ?? this.emoji,
      priority: priority ?? this.priority,
      teams: teams ?? this.teams,
    );
  }
}

class GroupTeam {
  final String name;            // e.g. "Day Shift", "Sector 2", "Alpha"
  final List<String> numbers;   // E.164 numbers

  GroupTeam({required this.name, required this.numbers});

  factory GroupTeam.fromMap(Map<String, dynamic> map) => GroupTeam(
    name: (map['name'] ?? '').toString(),
    numbers: (map['numbers'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'numbers': numbers,
  };
}

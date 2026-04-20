// lib/models/patrol_agent.dart
class PatrolAgent {
  final String id;
  final String name;
  final bool onDuty;
  final String? phone;
  final String? teamId;
  final String? zone;
  final List<String> areas;

  // Optional: monetization & performance
  final double? hourlyRate;
  final double? rating;
  final int? ratingCount;

  // Optional: availability (weekly + exceptions)
  // weekly example: { "mon": ["06:00-10:00","18:00-22:00"], ... }
  final Map<String, List<String>> availabilityWeekly;

  // exceptions example:
  // [{startAt: Timestamp, endAt: Timestamp, status:"unavailable", note:"Out of town"}]
  // We keep it dynamic because it’s Firestore-friendly and optional.
  final List<Map<String, dynamic>> availabilityExceptions;

  PatrolAgent({
    required this.id,
    required this.name,
    required this.onDuty,
    this.phone,
    this.teamId,
    this.zone,
    required this.areas,
    this.hourlyRate,
    this.rating,
    this.ratingCount,
    Map<String, List<String>>? availabilityWeekly,
    List<Map<String, dynamic>>? availabilityExceptions,
  })  : availabilityWeekly = availabilityWeekly ?? const {},
        availabilityExceptions = availabilityExceptions ?? const [];

  factory PatrolAgent.fromMap(String id, Map<String, dynamic> data) {
    final weeklyRaw = (data['availability'] is Map)
        ? ((data['availability'] as Map)['weekly'])
        : null;

    final Map<String, List<String>> weekly = {};
    if (weeklyRaw is Map) {
      for (final entry in weeklyRaw.entries) {
        final k = entry.key.toString();
        final v = entry.value;
        if (v is List) {
          weekly[k] = List<String>.from(v.map((e) => e.toString()));
        }
      }
    }

    final exceptionsRaw = (data['availability'] is Map)
        ? ((data['availability'] as Map)['exceptions'])
        : null;

    final List<Map<String, dynamic>> exceptions = [];
    if (exceptionsRaw is List) {
      for (final e in exceptionsRaw) {
        if (e is Map) exceptions.add(Map<String, dynamic>.from(e));
      }
    }

    return PatrolAgent(
      id: id,
      name: (data['name'] ?? 'Unknown').toString(),
      onDuty: (data['onDuty'] ?? false) == true,
      phone: data['phone']?.toString(),
      teamId: data['teamId']?.toString(),
      zone: data['zone']?.toString(),
      areas: (data['area'] is List) ? List<String>.from(data['area']) : <String>[],
      hourlyRate: (data['hourlyRate'] is num) ? (data['hourlyRate'] as num).toDouble() : null,
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : null,
      ratingCount: (data['ratingCount'] is num) ? (data['ratingCount'] as num).toInt() : null,
      availabilityWeekly: weekly,
      availabilityExceptions: exceptions,
    );
  }
}

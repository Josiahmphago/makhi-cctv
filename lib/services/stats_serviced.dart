import 'package:cloud_firestore/cloud_firestore.dart';

class StatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📊 GET ALL ALERTS
  Future<List<Map<String, dynamic>>> getAlerts() async {
    final snap = await _db.collection('central_alarms').get();

    return snap.docs.map((e) => e.data()).toList();
  }

  /// ⏱ RESPONSE TIME (in minutes)
  double calculateResponseTime(Map<String, dynamic> data) {
    final triggered = data['triggeredAt'];
    final accepted = data['ackAt'];

    if (triggered is! Timestamp || accepted is! Timestamp) return 0;

    final diff = accepted.toDate().difference(triggered.toDate());

    return diff.inMinutes.toDouble();
  }

  /// 📅 GROUP BY DAY
  Map<String, int> groupByDay(List<Map<String, dynamic>> alerts) {
    final result = <String, int>{};

    for (final a in alerts) {
      final t = a['triggeredAt'];
      if (t is! Timestamp) continue;

      final d = t.toDate();
      final key = "${d.year}-${d.month}-${d.day}";

      result[key] = (result[key] ?? 0) + 1;
    }

    return result;
  }

  /// ⏰ GROUP BY HOUR
  Map<int, int> groupByHour(List<Map<String, dynamic>> alerts) {
    final result = <int, int>{};

    for (final a in alerts) {
      final t = a['triggeredAt'];
      if (t is! Timestamp) continue;

      final hour = t.toDate().hour;

      result[hour] = (result[hour] ?? 0) + 1;
    }

    return result;
  }

  /// 🧠 BEST PATROL HOURS
  List<int> getBestHours(Map<int, int> data) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }
}
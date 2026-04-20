import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  /// Sends a shift start notification to all team members
  static Future<void> sendShiftNotification({
    required String shiftTitle,
    required String teamId,
  }) async {
    final teamDoc = await FirebaseFirestore.instance.collection('patrol_teams').doc(teamId).get();
    if (!teamDoc.exists) return;

    final members = teamDoc.data()?['members'] ?? [];
    for (var member in members) {
      if (member['userId'] != null) {
        await FirebaseFirestore.instance.collection('messages').add({
          'toUserId': member['userId'],
          'message': '🚨 $shiftTitle',
          'type': 'shift',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    }
  }
}

// lib/services/emergency_alarm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:makhi_cctv/services/alert_sender_service.dart';
import 'package:makhi_cctv/location/location_service.dart';

class EmergencyAlarmService {
  final _db = FirebaseFirestore.instance;
  final _sender = AlertSenderService();

  /// 🚨 Trigger emergency alarm
  Future<void> triggerAlarm({
    required bool silent,
    String areaId = 'Default',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Use your EXISTING location helper
    final locationLink = await LocationService.currentLocationLink();

    final baseMessage = silent
        ? '🟡 SILENT EMERGENCY ALERT\nUser may be in danger but cannot make noise.'
        : '🔴 EMERGENCY ALARM TRIGGERED\nImmediate assistance required.';

    final composedMessage = await _sender.composeMessage(
      baseMessage: baseMessage,
      includeLocation: true,
    );

    // 1️⃣ Save alarm to Firestore
    await _db.collection('alerts').add({
      'type': 'emergency',
      'silent': silent,
      'userId': user.uid,
      'areaId': areaId,
      'message': baseMessage,
      'locationLink': locationLink,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'new',
    });

    // 2️⃣ Send out alerts
    // Telegram bot (always)
    await _sender.sendTelegramBot(composedMessage);

    // WhatsApp / SMS can be added later per contact
  }
}

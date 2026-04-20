import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../services/dispatch_service.dart';

class PanicService {
  static const String _endpoint =
      'https://panicfanout-wezpkvn2eq-uc.a.run.app';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ==========================================================
  /// 🚨 SEND PANIC + SMART DISPATCH
  /// ==========================================================
  Future<void> sendPanic({
    required String text,
    String? phoneE164,
    bool sms = true,
    bool wa = true,
    bool tg = true,
    double? lat,
    double? lng,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      /// ======================================================
      /// 1️⃣ CREATE ALERT (FULL STRUCTURE)
      /// ======================================================
      final alertRef = await _db.collection('central_alarms').add({
        'senderId': user.uid,
        'senderName': user.email ?? 'Unknown User',

        'status': 'active',
        'message': text,

        'assignedTo': null,
        'assignedName': null,
        'assignedPhone': null,

        'backupPatrols': [],
        'responders': [],
        'rejectedBy': [],

        'eta': null,
        'areaId': 'Default',

        'location': {
          'lat': lat,
          'lng': lng,
        },

        'source': 'phone_panic',
        'triggeredAt': FieldValue.serverTimestamp(),
      });

      final alertId = alertRef.id;

      /// ======================================================
      /// 2️⃣ SMART AUTO DISPATCH 🔥🔥🔥
      /// ======================================================
      if (lat != null && lng != null) {
        await DispatchService.smartAssignNearestPatrol(
          alertId: alertId,
        );
      }

      /// ======================================================
      /// 3️⃣ SEND TO EXTERNAL CHANNELS
      /// ======================================================
      final payload = <String, dynamic>{
        'message': text,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (sms && phoneE164 != null) 'toSms': phoneE164,
        if (wa && phoneE164 != null)
          'toWa': 'whatsapp:$phoneE164',
        if (tg) 'telegram': true,
      };

      await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('🚨 Panic sent + SMART dispatch triggered');
    } catch (e) {
      print('❌ PanicService error: $e');
    }
  }
}
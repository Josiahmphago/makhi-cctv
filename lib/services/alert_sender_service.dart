// lib/services/alert_sender_service.dart

import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'package:makhi_cctv/location/location_service.dart';

class AlertSenderService {
  // ============================
  // 🔐 Telegram Bot credentials
  // ============================
  static const String _botToken =
      '7419597687:AAEmD5j85t26-cMAekacceIPiV86z1SdRH4';
  static const String _chatId = '6794675225';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ======================================================
  // 📝 Message builder (used by SMS / WhatsApp / Telegram)
  // ======================================================
  Future<String> composeMessage({
    required String baseMessage,
    bool includeLocation = true,
  }) async {
    String msg = baseMessage.trim();

    if (includeLocation) {
      final link = await LocationService.currentLocationLink();

      if (link != null && link.isNotEmpty) {
        msg += "\n\n📍 Location:\n$link";
      }
    }

    return msg;
  }

  // ======================
  // 📱 SMS
  // ======================
  Future<bool> sendSms(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encoded');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ======================
  // 💬 WhatsApp
  // ======================
  Future<bool> sendWhatsApp(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);

    final scheme = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    if (await canLaunchUrl(scheme)) {
      return await launchUrl(scheme, mode: LaunchMode.externalApplication);
    }

    final web = Uri.parse('https://wa.me/$phone?text=$encoded');
    return await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  // ======================
  // 🤖 Telegram (Bot API)
  // ======================
  Future<bool> sendTelegramBot(String message) async {
    try {
      final url = Uri.parse(
        'https://api.telegram.org/bot$_botToken/sendMessage'
        '?chat_id=$_chatId&text=${Uri.encodeComponent(message)}',
      );

      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ======================
  // 📤 Telegram Share
  // ======================
  Future<bool> sendTelegramShare(String message) async {
    final encoded = Uri.encodeComponent(message);

    final tg = Uri.parse('tg://msg?text=$encoded');
    if (await canLaunchUrl(tg)) {
      return await launchUrl(tg, mode: LaunchMode.externalApplication);
    }

    final web = Uri.parse('https://t.me/share/url?url=&text=$encoded');
    return await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  // ======================================================
  // 🚨 SILENT EMERGENCY ALARM (Firestore-based)
  // ======================================================
  Future<void> sendSilentAlarm({
    required String areaId,
    required String source, // phone | street | home | esp32
    bool hasCamera = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      // location optional
    }

    await _db.collection('alerts').add({
      // 🔑 Core
      'alertType': 'silent_alarm',
      'priority': 'high',
      'silent': true,

      // 👤 Context
      'userId': user.uid,
      'areaId': areaId,
      'source': source,

      // 📍 Location
      if (pos != null)
        'location': {
          'lat': pos.latitude,
          'lng': pos.longitude,
        },

      // 📷 Camera / escalation
      'camera': {
        'hasCamera': hasCamera,
        'snapshotUrl': null,
      },
      'escalation': {
        'streetSiren': false,
        'homeAlarm': false,
      },

      // 🔄 Status
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

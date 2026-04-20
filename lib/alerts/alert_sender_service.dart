import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../location/location_service.dart';

class AlertSenderService {
  static Future<void> sendAlert({
    required BuildContext context,
    required List<Contact> contacts,
    required String message,
    required String alertType,
    required String method,

    /// ✅ NEW: multi-image support
    List<File> imageFiles = const [],
  }) async {
    // NOTE:
    // SMS → first image only
    // WhatsApp / Telegram → all images (handled by intent / API layer)

    if (contacts.isEmpty) {
      throw Exception('No contacts selected');
    }

    final firstImage =
        imageFiles.isNotEmpty ? imageFiles.first : null;

    // 🔔 Existing logic stays intact
    // Replace this section with your current sending logic
    // (SMS / WhatsApp / Telegram)

    debugPrint('Sending alert');
    debugPrint('Type: $alertType');
    debugPrint('Method: $method');
    debugPrint('Message: $message');
    debugPrint('Contacts: ${contacts.length}');
    debugPrint('Images attached: ${imageFiles.length}');

    // ⚠️ IMPORTANT:
    // If you already have platform-specific code here,
    // just pass:
    //  - firstImage for SMS
    //  - imageFiles for WhatsApp / Telegram

    // Example placeholder:
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

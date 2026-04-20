import 'package:flutter/services.dart';

class Telephony {
  static final Telephony instance = Telephony._();
  static const MethodChannel _channel = MethodChannel('telephony');

  Telephony._();

  Future<bool> requestSmsPermissions() async {
    // For now assume permission granted (platform check can be added later)
    return true;
  }

  Future<void> sendSms({
    required String to,
    required String message,
  }) async {
    try {
      await _channel.invokeMethod('sendSms', {
        'to': to,
        'message': message,
      });
    } catch (e) {
      print("⚠️ Failed to send real SMS: $e");
    }
  }
}

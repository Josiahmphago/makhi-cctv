import 'package:url_launcher/url_launcher.dart';

class LocalSmsSender {
  /// Opens the device SMS app with optional pre-filled text.
  /// Returns true if it launched, false otherwise.
  static Future<bool> sendSms(String phoneNumber, String message) async {
    final p = _normalize(phoneNumber);
    if (p.isEmpty) return false;

    final uri = (message.trim().isEmpty)
        ? Uri.parse('sms:$p')
        : Uri.parse('sms:$p?body=${Uri.encodeComponent(message)}');

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _normalize(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/quick_alert_contact_local.dart';

class AlertSenderService {
  /// Upload image to Firebase Storage and return URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('alerts/$fileName.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();
      print("✅ Uploaded image: $url");
      return url;
    } catch (e) {
      print("❌ Failed to upload image: $e");
      return null;
    }
  }

  /// Send SMS using device launcher
  static Future<void> sendSMS(String phone, String message) async {
    final url = Uri.parse("sms:$phone?body=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      print("📨 SMS launched for $phone");
    } else {
      print("❌ Could not launch SMS for $phone");
    }
  }

  /// Send WhatsApp message using web launcher
  static Future<void> sendWhatsApp(String phone, String message) async {
    final phoneFormatted = phone.replaceAll('+', '').replaceAll(' ', '');
    final url = Uri.parse("https://wa.me/$phoneFormatted?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      print("✅ WhatsApp launched for $phoneFormatted");
    } else {
      print("❌ Could not launch WhatsApp for $phoneFormatted");
    }
  }

  /// Send Telegram message using Bot API
  static Future<void> sendTelegram({
    required String botToken,
    required String chatId,
    required String message,
  }) async {
    try {
      final telegramUrl = Uri.parse(
        'https://api.telegram.org/bot$botToken/sendMessage',
      );

      final response = await http.post(
        telegramUrl,
        body: {
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Telegram message sent.");
      } else {
        print("❌ Telegram failed: \${response.statusCode} - \${response.body}");
      }
    } catch (e) {
      print("❌ Telegram send error: $e");
    }
  }
}

class AlertComposerWidget extends StatefulWidget {
  const AlertComposerWidget({super.key});

  @override
  State<AlertComposerWidget> createState() => _AlertComposerWidgetState();
}

class _AlertComposerWidgetState extends State<AlertComposerWidget> {
  late Box<QuickAlertContactLocal> quickContactBox;
  List<QuickAlertContactLocal> _quickContacts = [];
  QuickAlertContactLocal? _selectedQuickContact;
  final TextEditingController _alertMessageController = TextEditingController();
  String locationLink = "https://maps.google.com/?q=0,0"; // Replace with actual location logic

  @override
  void initState() {
    super.initState();
    quickContactBox = Hive.box<QuickAlertContactLocal>('quickAlertContacts');
    _quickContacts = quickContactBox.values.toList();
  }

  void _sendAlert() async {
    if (_selectedQuickContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select a contact.")),
      );
      return;
    }

    final phone = _selectedQuickContact!.phoneNumber;
    final name = _selectedQuickContact!.name;
    final message = "🚨 Alert from Makhi App!\n\n"
        "Name: $name\nPhone: $phone\nLocation: $locationLink\nMessage: ${_alertMessageController.text.trim()}";

    await AlertSenderService.sendSMS(phone, message);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButtonFormField<QuickAlertContactLocal>(
            value: _selectedQuickContact,
            items: _quickContacts.map((contact) {
              return DropdownMenuItem(
                value: contact,
                child: Text("${contact.name} (${contact.phoneNumber})"),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedQuickContact = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Send To Quick Contact',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _alertMessageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Custom Alert Message",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.warning),
            label: const Text("Send Alert"),
            onPressed: _sendAlert,
          ),
        ],
      ),
    );
  }
}

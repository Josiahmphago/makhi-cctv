import 'dart:convert';
import 'package:http/http.dart' as http;

class TwilioService {
  final String accountSid;
  final String authToken;
  final String fromNumber; // Twilio phone number

  TwilioService({
    required this.accountSid,
    required this.authToken,
    required this.fromNumber,
  });

  Future<void> sendSMS(String to, String message) async {
    final url = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
      body: {
        'From': fromNumber,
        'To': to,
        'Body': message,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ SMS sent to $to');
    } else {
      print('❌ Failed to send SMS to $to: ${response.body}');
    }
  }
}

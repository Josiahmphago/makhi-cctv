import 'dart:async';
import 'package:http/http.dart' as http;

class HttpX {
  static final _client = http.Client();

  static Future<http.Response> get(
    Uri url, {
    Duration timeout = const Duration(seconds: 6),
    int retries = 2,
  }) async {
    Object? lastErr;
    for (var i = 0; i <= retries; i++) {
      try {
        final res = await _client.get(url).timeout(timeout);
        return res;
      } catch (e) { lastErr = e; await Future.delayed(const Duration(milliseconds: 250)); }
    }
    throw lastErr ?? TimeoutException('timeout');
  }
}

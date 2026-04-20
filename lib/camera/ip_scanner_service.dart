// lib/camera/ip_scanner_service.dart
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';


class DiscoveredCamera {
  final String ip;
  final int port;
  final String url;
  final int latencyMs;

  DiscoveredCamera({
    required this.ip,
    required this.port,
    required this.url,
    required this.latencyMs,
  });
}

class IpScannerService {
  final NetworkInfo _net = NetworkInfo();

  Future<bool> isOnWifi() async {
    final r = await Connectivity().checkConnectivity();
    return r == ConnectivityResult.wifi;
  }

  String _prefixFromIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return '';
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  Future<String> guessSubnetPrefix() async {
    final ip = await _net.getWifiIP();
    if (ip != null && ip.isNotEmpty) {
      final p = _prefixFromIp(ip);
      if (p.isNotEmpty) return p;
    }

    return '192.168.1';
  }

  Future<int?> _probeTcp(String ip, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(ip, port,
          timeout: const Duration(milliseconds: 250));
      socket.destroy();
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<List<DiscoveredCamera>> scanSubnet({
    required String subnetPrefix,
    void Function(int done, int total)? onProgress,
  }) async {
    final results = <DiscoveredCamera>[];

    int total = 253;
    int done = 0;

    for (int i = 2; i < 255; i++) {
      final ip = '$subnetPrefix.$i';

      final ms = await _probeTcp(ip, 80);

      done++;
      onProgress?.call(done, total);

      if (ms != null) {
        results.add(
          DiscoveredCamera(
            ip: ip,
            port: 80,
            url: 'http://$ip/',
            latencyMs: ms,
          ),
        );
      }
    }

    return results;
  }
}
 
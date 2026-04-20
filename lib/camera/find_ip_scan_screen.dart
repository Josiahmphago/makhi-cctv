// lib/camera/find_ip_scan_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ip_scanner_service.dart';

class FindIpScanScreen extends StatefulWidget {
  const FindIpScanScreen({super.key});

  @override
  State<FindIpScanScreen> createState() => _FindIpScanScreenState();
}

class _FindIpScanScreenState extends State<FindIpScanScreen> {
  final IpScannerService _scanner = IpScannerService();

  List<DiscoveredCamera> _results = [];

  bool _scanning = false;
  String _status = 'Idle';

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _results.clear();
      _status = 'Preparing scan...';
    });

    final onWifi = await _scanner.isOnWifi();
    if (!onWifi) {
      setState(() {
        _scanning = false;
        _status = '❌ Connect to WiFi first';
      });
      return;
    }

    final prefix = await _scanner.guessSubnetPrefix();

    final found = await _scanner.scanSubnet(
      subnetPrefix: prefix,
      onProgress: (done, total) {
        setState(() {
          _status = 'Scanning $done / $total';
        });
      },
    );

    setState(() {
      _results = found;
      _scanning = false;
      _status = '✅ Found ${found.length} devices';
    });
  }

  Future<void> _addCamera(DiscoveredCamera d) async {
    final user = FirebaseAuth.instance.currentUser;

    final nameCtrl = TextEditingController(text: 'ESP32-CAM ${d.ip}');
    final areaCtrl = TextEditingController(text: 'Default');
    final locationCtrl = TextEditingController(text: 'Street');

    String type = 'street';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Camera'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text('Detected: ${d.url}'),
              const SizedBox(height: 10),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Camera Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'street', child: Text('Street')),
                  DropdownMenuItem(value: 'home', child: Text('Home')),
                ],
                onChanged: (v) => type = v ?? 'street',
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseFirestore.instance.collection('cctv_cameras').add({
      'name': nameCtrl.text.trim(),
      'area': areaCtrl.text.trim(),
      'locationText': locationCtrl.text.trim(),
      'type': type,

      /// ✅ FIXED FIELDS
      'ipAddress': d.ip,
      'ipAdress': d.ip, // legacy support
      'streamUrl': d.url,

      'isActive': true,

      'ownerId': user?.uid,
      'ownerName': '',
      'ownerContact': '',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Added ${d.ip}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Cameras (IP Scan)'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Text(_status),

          const SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: _scanning ? null : _startScan,
            icon: const Icon(Icons.search),
            label: Text(_scanning ? 'Scanning...' : 'Start Scan'),
          ),

          const Divider(),

          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No devices found'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final d = _results[i];

                      return ListTile(
                        leading: const Icon(Icons.videocam),
                        title: Text(d.ip),
                        subtitle: Text(d.url),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addCamera(d),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
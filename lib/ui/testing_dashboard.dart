import 'package:flutter/material.dart';
import '../alerts/alert_composer.dart';
import '../camera/esp32_cam_viewer.dart';

class TestingDashboard extends StatefulWidget {
  const TestingDashboard({super.key});

  @override
  State<TestingDashboard> createState() => _TestingDashboardState();
}

class _TestingDashboardState extends State<TestingDashboard> {
  bool _alarmEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [

            // ===============================
            // 🌸 FLOWER AREA
            // ===============================
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade50,
                      ),
                    ),
                  ),

                  // 🔴 PANIC CENTER
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlertComposer(),
                            ),
                          );
                        },
                        child: const Text(
                          "PANIC",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 📡 LIVE
                  Positioned(
                    top: 140,
                    left: MediaQuery.of(context).size.width / 2 - 40,
                    child: _circleButton(
                      icon: Icons.videocam,
                      label: "LIVE",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Esp32CamViewer(
                              url: "http://192.168.18.25/",
                              cameraId: "Street Cam",
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 📷 CAMERA
                  Positioned(
                    bottom: 160,
                    left: 40,
                    child: _circleButton(
                      icon: Icons.camera_alt,
                      label: "CAMERA",
                      onTap: () {
                        Navigator.pushNamed(context, '/camera/capture');
                      },
                    ),
                  ),

                  // ⚙ SETTINGS
                  Positioned(
                    bottom: 160,
                    right: 40,
                    child: _circleButton(
                      icon: Icons.settings,
                      label: "SETTINGS",
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ===============================
            // 🚓 QUICK ACCESS ROW
            // ===============================
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  _circleButton(
                    icon: Icons.security,
                    label: "SECURITY",
                    onTap: () {
                      Navigator.pushNamed(context, '/escort/dashboard');
                    },
                  ),

                  _circleButton(
                    icon: Icons.directions_walk,
                    label: "PATROL",
                    onTap: () {
                      Navigator.pushNamed(context, '/patrol/dashboard');
                    },
                  ),

                  _circleButton(
                    icon: Icons.local_police,
                    label: "POLICE",
                    onTap: () {
                      Navigator.pushNamed(context, '/police');
                    },
                  ),

                  _circleButton(
                    icon: _alarmEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    label: _alarmEnabled ? "ALARM ON" : "ALARM OFF",
                    color: _alarmEnabled ? Colors.red : Colors.grey,
                    onTap: () {
                      setState(() {
                        _alarmEnabled = !_alarmEnabled;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _alarmEnabled
                                ? "Alarm Activated"
                                : "Alarm Deactivated",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6,
                  color: Colors.black26,
                )
              ],
            ),
            child: Icon(icon, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
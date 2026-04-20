// lib/location/location_service.dart

import 'package:geolocator/geolocator.dart';

class LocationService {
  // =====================================================
  // 🔐 Ensure permission + service enabled
  // =====================================================
  static Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // =====================================================
  // 📍 Main Position Method (STANDARD)
  // =====================================================
  static Future<Position?> getCurrentPosition() async {
    final allowed = await _ensurePermission();
    if (!allowed) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  // =====================================================
  // 🔁 Backward Compatibility Alias
  // =====================================================
  static Future<Position?> current() async {
    return await getCurrentPosition();
  }

  // =====================================================
  // 🔗 Google Maps Link
  // =====================================================
  static Future<String?> currentLocationLink() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;

    return 'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  /// 🔑 PUT YOUR API KEY HERE
  static const String _apiKey = "AIzaSyDY_-bCKMNNhR8S1LIseWE9j1PSlCw6pSw";

  /// ==========================================================
  /// 🗺️ GET ROUTE WITH TRAFFIC
  /// ==========================================================
  static Future<Map<String, dynamic>?> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json"
      "?origin=${origin.latitude},${origin.longitude}"
      "&destination=${destination.latitude},${destination.longitude}"
      "&mode=driving"
      "&departure_time=now"
      "&traffic_model=best_guess"
      "&key=$_apiKey",
    );

    try {
      final res = await http.get(url);

      if (res.statusCode != 200) {
        print("❌ API ERROR: ${res.statusCode}");
        return null;
      }

      final data = json.decode(res.body);

      if (data['routes'] == null || data['routes'].isEmpty) {
        print("❌ No routes found");
        return null;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      final polyline = route['overview_polyline']['points'];

      return {
        'polyline': polyline,
        'points': decodePolyline(polyline), // ✅ READY FOR MAP DRAW
        'distance': leg['distance']['text'],
        'duration': leg['duration']['text'],
        'seconds': leg['duration']['value'],
      };
    } catch (e) {
      print("❌ Directions error: $e");
      return null;
    }
  }

  /// ==========================================================
  /// 📍 DECODE POLYLINE → LIST<LatLng>
  /// ==========================================================
  static List<LatLng> decodePolyline(String polyline) {
    List<LatLng> points = [];

    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;

      int b;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
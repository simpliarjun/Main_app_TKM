import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:trackmate_app/config/api_config.dart';

class LocationService {
  /// =====================================================
  /// CURRENT LOCATION
  /// =====================================================
  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// =====================================================
  /// GET ADDRESS FROM COORDINATES (With Retry & Timeout)
  /// =====================================================
  static Future<String> getAddressFromCoordinates(double lat, double lng, {int maxRetries = 3}) async {
    final url = Uri.parse(
      "${ApiConfig.geocodingBaseUrl}/json"
          "?latlng=$lat,$lng&key=${ApiConfig.googleGeocodingApiKey}",
    );

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final res = await http.get(url).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Geocoding request timed out');
          },
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          // Check API response status
          final status = data["status"] ?? "UNKNOWN";
          
          if (status == "OK" && data["results"].isNotEmpty) {
            final address = data["results"][0]["formatted_address"];
            if (address != null && address.isNotEmpty) {
              debugPrint("✅ Geocoding OK: $lat, $lng → $address");
              return address;
            }
          } else if (status == "ZERO_RESULTS") {
            debugPrint("⚠️ Geocoding: No results for $lat, $lng");
            return "Location: $lat, $lng";  // Better than "Unknown location"
          } else if (status == "OVER_QUERY_LIMIT") {
            debugPrint("⏳ Rate limited (attempt ${attempt + 1}/$maxRetries)");
            if (attempt < maxRetries - 1) {
              await Future.delayed(Duration(seconds: (attempt + 1) * 2));
              continue;
            }
            return "Location: $lat, $lng";
          } else if (status == "REQUEST_DENIED") {
            debugPrint("❌ Geocoding: API key invalid or quota exceeded");
            return "Location: $lat, $lng";
          }
        } else if (res.statusCode == 429) {
          // Rate limited - retry with exponential backoff
          debugPrint("⏳ Rate limited 429 (attempt ${attempt + 1}/$maxRetries)");
          if (attempt < maxRetries - 1) {
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
            continue;
          }
        }

        debugPrint("❌ Geocoding API error: ${res.statusCode} (attempt ${attempt + 1}/$maxRetries)");
      } on TimeoutException {
        debugPrint("⏱️ Geocoding timeout (attempt ${attempt + 1}/$maxRetries)");
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
      } catch (e) {
        debugPrint("❌ Geocoding error: $e (attempt ${attempt + 1}/$maxRetries)");
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
      }
    }

    debugPrint("❌ Geocoding failed after $maxRetries attempts");
    return "Location: $lat, $lng";  // Final fallback
  }

  /// =====================================================
  /// AUTOCOMPLETE SEARCH → returns List<Map<String,dynamic>>
  /// =====================================================
  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    final url = Uri.parse(
      "${ApiConfig.placesBaseUrl}/autocomplete/json"
          "?input=$query&key=${ApiConfig.googlePlacesApiKey}&components=country:in",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (!data.containsKey("predictions")) return [];

    return List<Map<String, dynamic>>.from(
      data["predictions"].map((p) {
        return {
          "place_id": p["place_id"],
          "name": p["description"],
        };
      }),
    );
  }


  /// ==============================================
  /// CHECK PERMISSIONS
  /// ==============================================
  static Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// ==============================================
  /// POSITION STREAM (REAL-TIME LIVE TRACKING)
  /// ==============================================
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // meters
      ),
    );
  }


  /// =====================================================
  /// PLACE DETAILS → returns {lat,lng,name}
  /// =====================================================
  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      "${ApiConfig.placesBaseUrl}/details/json"
          "?place_id=$placeId&fields=name,geometry&key=${ApiConfig.googlePlacesApiKey}",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (!data.containsKey("result")) return {};

    final result = data["result"];
    final loc = result["geometry"]["location"];

    return {
      "name": result["name"],
      "lat": loc["lat"],
      "lng": loc["lng"],
    };
  }
}
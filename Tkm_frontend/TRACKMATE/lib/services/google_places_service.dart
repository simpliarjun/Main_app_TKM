import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trackmate_app/config/api_config.dart';

class GooglePlacesService {
  Future<List<dynamic>> searchPlaces(String query) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.placesBaseUrl}/autocomplete/json?input=$query&key=${ApiConfig.googlePlacesApiKey}&components=country:in'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in searchPlaces: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
          '${ApiConfig.placesBaseUrl}/details/json?place_id=$placeId&key=${ApiConfig.googlePlacesApiKey}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in getPlaceDetails: $e');
      return null;
    }
  }
}
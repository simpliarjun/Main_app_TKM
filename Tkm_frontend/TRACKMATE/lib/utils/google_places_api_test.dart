import 'package:http/http.dart' as http;
import 'dart:convert';

/// 🧪 Google Places API Test Suite
/// Tests all functionality of Google Places API integration
class GooglePlacesApiTest {
  static const String apiKey = 'YOUR_GOOGLE_API_KEY_HERE'; // Places API
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Test 1: Autocomplete API
  static Future<Map<String, dynamic>> testAutocomplete(String query) async {
    print('🔍 TEST 1: Autocomplete API');
    print('Query: $query');
    
    try {
      final url = Uri.parse(
        '$baseUrl/autocomplete/json?input=$query&key=$apiKey&components=country:in'
      );
      print('📍 URL: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          print('✅ Found ${predictions.length} suggestions:');
          
          for (int i = 0; i < (predictions.length > 3 ? 3 : predictions.length); i++) {
            print('  ${i + 1}. ${predictions[i]['description']}');
            print('     Place ID: ${predictions[i]['place_id']}');
          }
          
          return {
            'success': true,
            'status': data['status'],
            'count': predictions.length,
            'predictions': predictions,
          };
        } else {
          print('❌ Error: ${data['status']}');
          print('   Message: ${data['error_message'] ?? 'Unknown error'}');
          return {'success': false, 'status': data['status']};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('   Response: ${response.body}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 2: Place Details API
  static Future<Map<String, dynamic>> testPlaceDetails(String placeId) async {
    print('\n🔍 TEST 2: Place Details API');
    print('Place ID: $placeId');
    
    try {
      final url = Uri.parse(
        '$baseUrl/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address,name,address_components'
      );
      print('📍 URL: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          print('✅ Place Details:');
          print('   Name: ${result['name'] ?? 'N/A'}');
          print('   Address: ${result['formatted_address'] ?? 'N/A'}');
          print('   Latitude: ${result['geometry']?['location']?['lat'] ?? 'N/A'}');
          print('   Longitude: ${result['geometry']?['location']?['lng'] ?? 'N/A'}');
          
          return {
            'success': true,
            'status': data['status'],
            'place': result,
          };
        } else {
          print('❌ Error: ${data['status']}');
          return {'success': false, 'status': data['status']};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 3: Geocoding API (Address to Coordinates)
  static Future<Map<String, dynamic>> testGeocoding(String address) async {
    print('\n🔍 TEST 3: Geocoding API (Address → Coordinates)');
    print('Address: $address');
    
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey&components=country:in'
      );
      print('📍 URL: ${url.toString().split('?')[0]}?...');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status: ${data['status']}');
        
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          print('✅ Geocoding Result:');
          print('   Address: ${result['formatted_address']}');
          print('   Latitude: ${result['geometry']['location']['lat']}');
          print('   Longitude: ${result['geometry']['location']['lng']}');
          
          return {
            'success': true,
            'status': data['status'],
            'result': result,
          };
        } else {
          print('❌ Error: ${data['status']}');
          return {'success': false, 'status': data['status']};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 4: Reverse Geocoding (Coordinates to Address)
  static Future<Map<String, dynamic>> testReverseGeocoding(
    double latitude,
    double longitude,
  ) async {
    print('\n🔍 TEST 4: Reverse Geocoding API (Coordinates → Address)');
    print('Latitude: $latitude, Longitude: $longitude');
    
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey'
      );
      print('📍 URL: ${url.toString().split('?')[0]}?...');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📊 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status: ${data['status']}');
        
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          print('✅ Reverse Geocoding Result:');
          print('   Address: ${result['formatted_address']}');
          
          return {
            'success': true,
            'status': data['status'],
            'address': result['formatted_address'],
          };
        } else {
          print('❌ Error: ${data['status']}');
          return {'success': false, 'status': data['status']};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('═════════════════════════════════════════════════════════');
    print('🧪 GOOGLE PLACES API - COMPREHENSIVE TEST SUITE');
    print('═════════════════════════════════════════════════════════');
    print('API Key: ${apiKey.substring(0, 15)}...${apiKey.substring(apiKey.length - 10)}');
    print('═════════════════════════════════════════════════════════\n');

    // Test 1: Autocomplete
    final testQuery = 'New Delhi';
    final autocompleteResult = await testAutocomplete(testQuery);
    
    if (autocompleteResult['success'] == true &&
        (autocompleteResult['predictions'] as List).isNotEmpty) {
      // Test 2: Place Details
      final firstPlaceId =
          (autocompleteResult['predictions'] as List).first['place_id'];
      final detailsResult = await testPlaceDetails(firstPlaceId);

      // Test 3: Geocoding
      final geocodingResult = await testGeocoding('Mumbai, Maharashtra');

      // Test 4: Reverse Geocoding
      if (geocodingResult['success'] == true) {
        final lat = geocodingResult['result']['geometry']['location']['lat'];
        final lng = geocodingResult['result']['geometry']['location']['lng'];
        await testReverseGeocoding(lat, lng);
      }
    }

    print('\n═════════════════════════════════════════════════════════');
    print('✅ TEST SUITE COMPLETED');
    print('═════════════════════════════════════════════════════════');
  }
}

/// Run tests in main app
void testGooglePlacesApi() {
  GooglePlacesApiTest.runAllTests();
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GooglePlacesApiTestScreen extends StatefulWidget {
  const GooglePlacesApiTestScreen({super.key});

  @override
  State<GooglePlacesApiTestScreen> createState() =>
      _GooglePlacesApiTestScreenState();
}

class _GooglePlacesApiTestScreenState extends State<GooglePlacesApiTestScreen> {
  static const String apiKey = 'YOUR_GOOGLE_API_KEY_HERE'; // Places API
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';

  List<String> _testLogs = [];
  bool _isTesting = false;

  void _addLog(String message) {
    setState(() {
      _testLogs.add('${DateTime.now().toIso8601String().split('T')[1].split('.')[0]} - $message');
    });
  }

  void _clearLogs() {
    setState(() => _testLogs = []);
  }

  Future<void> _testAutoComplete() async {
    _addLog('🔍 Testing Autocomplete API with "New Delhi"...');
    setState(() => _isTesting = true);

    try {
      final url = Uri.parse(
        '$baseUrl/autocomplete/json?input=New%20Delhi&key=$apiKey&components=country:in'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          _addLog('✅ Autocomplete SUCCESS: Found ${predictions.length} suggestions');
          for (var p in predictions.take(3)) {
            _addLog('   • ${p['description']} (ID: ${p['place_id'].toString().substring(0, 15)}...)');
          }
        } else {
          _addLog('❌ Autocomplete FAILED: ${data['status']}');
        }
      } else {
        _addLog('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _addLog('❌ Exception: $e');
    }

    setState(() => _isTesting = false);
  }

  Future<void> _testGeocoding() async {
    _addLog('🔍 Testing Geocoding API with "Mumbai, Maharashtra"...');
    setState(() => _isTesting = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=Mumbai%2C%20Maharashtra&key=$apiKey'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];
          _addLog('✅ Geocoding SUCCESS');
          _addLog('   Address: ${result['formatted_address']}');
          _addLog('   Coordinates: $lat, $lng');
        } else {
          _addLog('❌ Geocoding FAILED: ${data['status']}');
        }
      } else {
        _addLog('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _addLog('❌ Exception: $e');
    }

    setState(() => _isTesting = false);
  }

  Future<void> _testPlaceDetails() async {
    _addLog('🔍 Testing Place Details API...');
    _addLog('Step 1: Getting autocomplete suggestions for "Bangalore"...');
    setState(() => _isTesting = true);

    try {
      // Step 1: Get autocomplete suggestions
      final autocompleteUrl = Uri.parse(
        '$baseUrl/autocomplete/json?input=Bangalore&key=$apiKey&components=country:in'
      );

      final autocompleteResponse = await http.get(autocompleteUrl).timeout(const Duration(seconds: 10));

      if (autocompleteResponse.statusCode == 200) {
        final autocompleteData = json.decode(autocompleteResponse.body);
        if (autocompleteData['status'] == 'OK' &&
            (autocompleteData['predictions'] as List).isNotEmpty) {
          final placeId = autocompleteData['predictions'][0]['place_id'];
          _addLog('   Found Place ID: ${placeId.substring(0, 15)}...');

          // Step 2: Get place details
          _addLog('Step 2: Getting place details...');
          final detailsUrl = Uri.parse(
            '$baseUrl/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address,name'
          );

          final detailsResponse = await http.get(detailsUrl).timeout(const Duration(seconds: 10));

          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            if (detailsData['status'] == 'OK') {
              final result = detailsData['result'];
              _addLog('✅ Place Details SUCCESS');
              _addLog('   Name: ${result['name']}');
              _addLog('   Address: ${result['formatted_address']}');
              _addLog('   Lat: ${result['geometry']['location']['lat']}');
              _addLog('   Lng: ${result['geometry']['location']['lng']}');
            } else {
              _addLog('❌ Place Details FAILED: ${detailsData['status']}');
            }
          } else {
            _addLog('❌ HTTP Error: ${detailsResponse.statusCode}');
          }
        } else {
          _addLog('❌ Autocomplete FAILED: ${autocompleteData['status']}');
        }
      }
    } catch (e) {
      _addLog('❌ Exception: $e');
    }

    setState(() => _isTesting = false);
  }

  Future<void> _testReverseGeocoding() async {
    _addLog('🔍 Testing Reverse Geocoding API...');
    _addLog('Getting address for coordinates: 19.076, 72.877 (Mumbai)...');
    setState(() => _isTesting = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=19.076,72.877&key=$apiKey'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          _addLog('✅ Reverse Geocoding SUCCESS');
          _addLog('   Address: ${result['formatted_address']}');
        } else {
          _addLog('❌ Reverse Geocoding FAILED: ${data['status']}');
        }
      } else {
        _addLog('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _addLog('❌ Exception: $e');
    }

    setState(() => _isTesting = false);
  }

  Future<void> _testAllApis() async {
    _clearLogs();
    _addLog('═══════════════════════════════════════');
    _addLog('🧪 GOOGLE PLACES API - FULL TEST SUITE');
    _addLog('═══════════════════════════════════════');

    await _testAutoComplete();
    await Future.delayed(const Duration(seconds: 1));
    await _testGeocoding();
    await Future.delayed(const Duration(seconds: 1));
    await _testPlaceDetails();
    await Future.delayed(const Duration(seconds: 1));
    await _testReverseGeocoding();

    _addLog('═══════════════════════════════════════');
    _addLog('✅ All tests completed!');
    _addLog('═══════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Google Places API Test'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Test Buttons
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Individual APIs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testAutoComplete,
                      icon: const Icon(Icons.search),
                      label: const Text('Autocomplete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00adb5),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testGeocoding,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Geocoding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00adb5),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testPlaceDetails,
                      icon: const Icon(Icons.details),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00adb5),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testReverseGeocoding,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Reverse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00adb5),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testAllApis,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run All Tests'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Logs
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF16213E),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Test Logs (${_testLogs.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: _clearLogs,
                          tooltip: 'Clear logs',
                        ),
                      ],
                    ),
                  ),
                  if (_isTesting)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Color(0xFF00adb5),
                      ),
                    ),
                  Expanded(
                    child: _testLogs.isEmpty
                        ? Center(
                            child: Text(
                              'No logs yet. Click a test button to get started!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _testLogs.length,
                            itemBuilder: (context, index) {
                              final log = _testLogs[index];
                              Color textColor = Colors.white70;
                              if (log.contains('✅')) {
                                textColor = Colors.green;
                              } else if (log.contains('❌')) {
                                textColor = Colors.red;
                              } else if (log.contains('🔍')) {
                                textColor = const Color(0xFF00adb5);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

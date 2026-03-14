// cost_calculator.dart - Part 1
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;
import 'package:trackmate_app/config/api_config.dart';

class CostCalculatorScreen extends StatefulWidget {
  const CostCalculatorScreen({super.key});

  @override
  State<CostCalculatorScreen> createState() => _CostCalculatorScreenState();
}

class _CostCalculatorScreenState extends State<CostCalculatorScreen>
    with SingleTickerProviderStateMixin {

  // Controllers
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Autocomplete state
  List<dynamic> _startSuggestions = [];
  List<dynamic> _endSuggestions = [];
  bool _isSearchingStart = false;
  bool _isSearchingEnd = false;

  // ✅ API keys are loaded from ApiConfig (from .env)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Add listeners for autocomplete
    _startController.addListener(() {
      if (_startController.text.isNotEmpty) {
        _searchStartLocations(_startController.text);
      } else {
        setState(() => _startSuggestions = []);
      }
    });
    
    _endController.addListener(() {
      if (_endController.text.isNotEmpty) {
        _searchEndLocations(_endController.text);
      } else {
        setState(() => _endSuggestions = []);
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // ✅ NEW: Search for start location suggestions
  Future<void> _searchStartLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _startSuggestions = [];
        _isSearchingStart = false;
      });
      return;
    }

    setState(() => _isSearchingStart = true);

    try {
      // Get API suggestions
      final apiSuggestions = await _getPlaceSuggestions(query);
      
      // Add predefined cities that match the query
      final predefinedCities = [
        'Delhi', 'Mumbai', 'Bangalore', 'Goa', 'Kolkata', 'Hyderabad',
        'Pune', 'Jaipur', 'Coimbatore', 'Mysore', 'Agra', 'Lucknow', 'Nashik'
      ];
      
      final matchingCities = predefinedCities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .map((city) => {
            'description': '$city, India',
            'main_text': city,
            'secondary_text': 'India (Quick Route)',
            'place_id': city,
            'is_predefined': true,
          } as dynamic)
          .toList();

      setState(() {
        _startSuggestions = [...matchingCities, ...apiSuggestions];
        _isSearchingStart = false;
      });
    } catch (e) {
      setState(() => _isSearchingStart = false);
      debugPrint('Error searching start location: $e');
    }
  }

  // ✅ NEW: Search for end location suggestions
  Future<void> _searchEndLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _endSuggestions = [];
        _isSearchingEnd = false;
      });
      return;
    }

    setState(() => _isSearchingEnd = true);

    try {
      // Get API suggestions
      final apiSuggestions = await _getPlaceSuggestions(query);
      
      // Add predefined cities that match the query
      final predefinedCities = [
        'Delhi', 'Mumbai', 'Bangalore', 'Goa', 'Kolkata', 'Hyderabad',
        'Pune', 'Jaipur', 'Coimbatore', 'Mysore', 'Agra', 'Lucknow', 'Nashik'
      ];
      
      final matchingCities = predefinedCities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .map((city) => {
            'description': '$city, India',
            'main_text': city,
            'secondary_text': 'India (Quick Route)',
            'place_id': city,
            'is_predefined': true,
          } as dynamic)
          .toList();

      setState(() {
        _endSuggestions = [...matchingCities, ...apiSuggestions];
        _isSearchingEnd = false;
      });
    } catch (e) {
      setState(() => _isSearchingEnd = false);
      debugPrint('Error searching end location: $e');
    }
  }
  
  // ✅ NEW: Get place suggestions from Google Places Autocomplete API
  Future<List<dynamic>> _getPlaceSuggestions(String input) async {
    final String url =
        '${ApiConfig.placesBaseUrl}/autocomplete/json?input=$input&key=${ApiConfig.googlePlacesApiKey}&components=country:in';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'] ?? [];
        } else {
          debugPrint('Autocomplete error: ${data['status']}');
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    }
  }
  
  // ✅ NEW: Get place details (coordinates) from place ID
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final String url =
        '${ApiConfig.placesBaseUrl}/details/json?place_id=$placeId&key=${ApiConfig.googlePlacesApiKey}&fields=geometry,formatted_address';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      return null;
    }
  }
  
  // ✅ NEW: Handle start location selection
  void _selectStartLocation(dynamic place) async {
    final placeId = place['place_id'];
    final placeDetails = await _getPlaceDetails(placeId);

    if (placeDetails != null) {
      final address = placeDetails['formatted_address'] ?? place['description'];
      setState(() {
        _startController.text = address;
        _startSuggestions = [];
      });
    }
  }

  // ✅ NEW: Handle end location selection
  void _selectEndLocation(dynamic place) async {
    final placeId = place['place_id'];
    final placeDetails = await _getPlaceDetails(placeId);

    if (placeDetails != null) {
      final address = placeDetails['formatted_address'] ?? place['description'];
      setState(() {
        _endController.text = address;
        _endSuggestions = [];
      });
    }
  }
  // cost_calculator.dart - Part 2 (Add after Part 1)

  Future<void> _calculateCost() async {
    if (_startController.text.trim().isEmpty || _endController.text.trim().isEmpty) {
      _showSnackBar('Please enter both locations', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      // First check if we have a predefined route
      final predefinedDistance = _getPredefinedDistance(
        _startController.text.trim(),
        _endController.text.trim(),
      );

      double distance;
      
      if (predefinedDistance != null) {
        distance = predefinedDistance;
        debugPrint('✅ Using predefined route distance: $predefinedDistance km');
      } else {
        // Try API coordinates
        final startCoords = await _getCoordinates(_startController.text.trim());
        final endCoords = await _getCoordinates(_endController.text.trim());

        if (startCoords == null || endCoords == null) {
          throw Exception('Could not find one or both locations. Please try common Indian cities.');
        }

        distance = _calculateDistanceFromCoords(
          startCoords['lat']!,
          startCoords['lng']!,
          endCoords['lat']!,
          endCoords['lng']!,
        );
      }

      if (distance <= 0) {
        throw Exception('Cannot calculate distance - cities too close or invalid');
      }

      setState(() {
        _results = _generateTravelOptions(distance);
        _isLoading = false;
      });

      _animationController.forward(from: 0.0);
      _showSnackBar('✅ Calculation complete!', isError: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF5252) : const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Predefined routes database for common Indian cities (fallback)
  double? _getPredefinedDistance(String startCity, String endCity) {
    final normalizeCity = (String city) => city.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .replaceAll(RegExp(r'(new\s*)?delhi'), 'delhi')
        .replaceAll(RegExp(r'bengaluru|bangalore'), 'bangalore')
        .replaceAll(RegExp(r'bhopal|bhopals'), 'bhopal')
        .replaceAll(RegExp(r'(navi\s*)?mumbai'), 'mumbai');

    final start = normalizeCity(startCity);
    final end = normalizeCity(endCity);

    // Predefined distances (km) - common Indian routes
    const routes = {
      'delhi-mumbai': 1400.0,
      'mumbai-delhi': 1400.0,
      'delhi-bangalore': 2150.0,
      'bangalore-delhi': 2150.0,
      'delhi-goa': 1770.0,
      'goa-delhi': 1770.0,
      'mumbai-bangalore': 980.0,
      'bangalore-mumbai': 980.0,
      'delhi-kolkata': 1500.0,
      'kolkata-delhi': 1500.0,
      'delhi-hyderabad': 1580.0,
      'hyderabad-delhi': 1580.0,
      'mumbai-goa': 580.0,
      'goa-mumbai': 580.0,
      'bangalore-hyderabad': 570.0,
      'hyderabad-bangalore': 570.0,
      'kolkata-bangalore': 2050.0,
      'bangalore-kolkata': 2050.0,
      'mumbai-pune': 150.0,
      'pune-mumbai': 150.0,
      'delhi-jaipur': 260.0,
      'jaipur-delhi': 260.0,
      'bangalore-coimbatore': 240.0,
      'coimbatore-bangalore': 240.0,
      'mumbai-nashik': 180.0,
      'nashik-mumbai': 180.0,
      'delhi-lucknow': 500.0,
      'lucknow-delhi': 500.0,
      'bangalore-mysore': 140.0,
      'mysore-bangalore': 140.0,
      'hyderabad-pune': 760.0,
      'pune-hyderabad': 760.0,
      'delhi-agra': 206.0,
      'agra-delhi': 206.0,
    };

    return routes['$start-$end'];
  }

  Future<Map<String, double>?> _getCoordinates(String address) async {
    try {
      // First, try to get distance from predefined routes if both cities are common
      if (_startController.text.isNotEmpty && _endController.text.isNotEmpty) {
        final predefinedDistance = _getPredefinedDistance(
          _startController.text,
          _endController.text,
        );
        if (predefinedDistance != null) {
          // Return dummy coordinates - distance will be calculated from predefined value
          return {
            'lat': 0.0,
            'lng': (predefinedDistance / 111.0), // Approximate conversion
          };
        }
      }

      // Fallback: Try API call
      final url = Uri.parse(
        '${ApiConfig.geocodingBaseUrl}/json?address=${Uri.encodeComponent(address)}&key=${ApiConfig.googleGeocodingApiKey}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': (location['lat'] as num).toDouble(),
            'lng': (location['lng'] as num).toDouble(),
          };
        } else {
          // API returned error - use predefined fallback
          debugPrint('API returned status: ${data['status']}');
          final predefinedDistance = _getPredefinedDistance(
            _startController.text,
            _endController.text,
          );
          if (predefinedDistance != null) {
            return {
              'lat': 0.0,
              'lng': (predefinedDistance / 111.0),
            };
          }
          throw Exception('Location not found and no fallback route available');
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      // Last resort: try predefined routes
      final predefinedDistance = _getPredefinedDistance(
        _startController.text,
        _endController.text,
      );
      if (predefinedDistance != null) {
        return {
          'lat': 0.0,
          'lng': (predefinedDistance / 111.0),
        };
      }
      rethrow;
    }
  }

  double _calculateDistanceFromCoords(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

// Continue to Part 3 for _generateTravelOptions...// cost_calculator.dart - Part 3 (Add after Part 2)
//
  Map<String, dynamic> _generateTravelOptions(double distanceKm) {
    final fuelOptions = [
      {
        'fuel_type': 'Petrol',
        'estimated_cost': (distanceKm * 9.5).round(),
        'cost_per_km': 9.5,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.12).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '⛽',
        'color': 0xFFFF6B6B,
        'pros': ['Comfortable', 'Flexible schedule', 'Door-to-door'],
        'cons': ['Long drive', 'Can be tiring'],
      },
      {
        'fuel_type': 'Diesel',
        'estimated_cost': (distanceKm * 7.0).round(),
        'cost_per_km': 7.0,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.10).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '⛽',
        'color': 0xFF4ECDC4,
        'pros': ['Comfortable', 'Economical', 'Good mileage'],
        'cons': ['Long drive', 'Fuel availability'],
      },
      {
        'fuel_type': 'CNG',
        'estimated_cost': (distanceKm * 4.5).round(),
        'cost_per_km': 4.5,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.08).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '🌿',
        'color': 0xFF95E1D3,
        'pros': ['Eco-friendly', 'Very cheap', 'Clean fuel'],
        'cons': ['Limited CNG stations', 'Reduced boot space'],
      },
      {
        'fuel_type': 'Electric',
        'estimated_cost': (distanceKm * 2.5).round(),
        'cost_per_km': 2.5,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.05).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '⚡',
        'color': 0xFFFECA57,
        'pros': ['Most eco-friendly', 'Cheapest running', 'Silent ride'],
        'cons': ['Charging infrastructure', 'Range anxiety'],
      },
    ];

    final allOptions = [
      {'mode': 'car', 'fuel_options': fuelOptions},
      {
        'mode': 'flight',
        'estimated_cost_min': (distanceKm * 3).round(),
        'estimated_cost_max': (distanceKm * 5.5).round(),
        'time_hours': (distanceKm / 750 + 2).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.15).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '✈️',
        'color': 0xFF6C63FF,
        'pros': ['Fastest option', 'Time-saving', 'Long distance ideal'],
        'cons': ['Most expensive', 'Airport hassle', 'Weather dependent'],
      },
      {
        'mode': 'train',
        'estimated_cost_min': (distanceKm * 0.5).round(),
        'estimated_cost_max': (distanceKm * 1.7).round(),
        'time_hours': (distanceKm / 45).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.04).toStringAsFixed(1),
        'comfort_rating': 4,
        'icon': '🚆',
        'color': 0xFF00D9FF,
        'pros': ['Most affordable', 'Comfortable', 'Very eco-friendly'],
        'cons': ['Takes longer', 'Fixed schedule'],
      },
      {
        'mode': 'bus',
        'estimated_cost_min': (distanceKm * 0.8).round(),
        'estimated_cost_max': (distanceKm * 1.2).round(),
        'time_hours': (distanceKm / 40).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.09).toStringAsFixed(1),
        'comfort_rating': 3,
        'icon': '🚌',
        'color': 0xFFFF9FF3,
        'pros': ['Budget-friendly', 'Widely available', 'No driving stress'],
        'cons': ['Less comfortable', 'Frequent stops', 'Longer journey'],
      },
    ];

    String recommendedMode = 'train';
    int minCost = (distanceKm * 0.5).round();

    return {
      'distance_km': distanceKm.toStringAsFixed(1),
      'options': allOptions,
      'recommendation': {
        'mode': recommendedMode,
        'reason': 'Best balance of cost, comfort & eco-friendliness',
        'savings': ((distanceKm * 3.0) - minCost).round(),
      },
    };
  }

  // Continue to Part 4 for build method...// cost_calculator.dart - Part 4 (Add after Part 3)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1E2139)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildInputCard(),
                const SizedBox(height: 24),
                _buildCalculateButton(),
                if (_isLoading) ...[
                  const SizedBox(height: 40),
                  _buildLoadingIndicator(),
                ],
                if (_results != null) ...[
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildResults(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calculate, color: Color(0xFF6C63FF), size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Travel Cost\nCalculator',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare prices across different travel modes',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2139),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route, color: Color(0xFF00D9FF), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Journey Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // ✅ START LOCATION WITH AUTOCOMPLETE
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Color(0xFF00D9FF), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _startController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Starting Point (e.g., Delhi, Mumbai)',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_isSearchingStart)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                  ],
                ),
              ),
              // ✅ START SUGGESTIONS DROPDOWN
              if (_startSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _startSuggestions.length > 5 ? 5 : _startSuggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.1),
                      height: 1,
                      thickness: 0.5,
                    ),
                    itemBuilder: (context, index) {
                      final place = _startSuggestions[index];
                      final description = place['description'] ?? 'Unknown';
                      return InkWell(
                        onTap: () => _selectStartLocation(place),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFF00D9FF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  description,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // ✅ END LOCATION WITH AUTOCOMPLETE
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFFF5252), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Destination (e.g., Goa, Bangalore)',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_isSearchingEnd)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                  ],
                ),
              ),
              // ✅ END SUGGESTIONS DROPDOWN
              if (_endSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _endSuggestions.length > 5 ? 5 : _endSuggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.1),
                      height: 1,
                      thickness: 0.5,
                    ),
                    itemBuilder: (context, index) {
                      final place = _endSuggestions[index];
                      final description = place['description'] ?? 'Unknown';
                      return InkWell(
                        onTap: () => _selectEndLocation(place),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFFFF5252)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  description,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _calculateCost,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 24),
            SizedBox(width: 12),
            Text(
              'Calculate Travel Costs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6C63FF),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Calculating best routes...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Continue to Part 5 for results widgets...// cost_calculator.dart - Part 5 (Add after Part 4)

  Widget _buildResults() {
    final distance = _results!['distance_km'];
    final options = _results!['options'] as List;
    final recommendation = _results!['recommendation'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Distance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$distance km',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.route, color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withOpacity(0.15),
            border: Border.all(color: const Color(0xFF00D9FF), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFF00D9FF), size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Recommended Option',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🚆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation['mode'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation['reason'],
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.savings, color: Color(0xFF00D9FF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save up to ₹${recommendation['savings']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'All Travel Options',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) => _buildOptionCard(opt)),
      ],
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option) {
    try {
      final mode = option['mode'];
      
      // Validate required fields
      if (mode == null) {
        return const SizedBox.shrink();
      }
      
      // Check if option has required fields
      if (mode != 'car') {
        if (!option.containsKey('estimated_cost_min') || 
            !option.containsKey('estimated_cost_max')) {
          debugPrint('⚠️ Option missing cost fields: $mode');
          return const SizedBox.shrink();
        }
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2139),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            leading: Text(
              _getEmoji(mode),
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(
              mode.toString().toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                mode == 'car'
                    ? 'Multiple fuel options available'
                    : '₹${option['estimated_cost_min'] ?? 0} - ₹${option['estimated_cost_max'] ?? 0}',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            children: [
              mode == 'car' ? _buildCarOptions(option) : _buildTransportDetails(option),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building option card: $e');
      return const SizedBox.shrink();
    }
  }

  String _getEmoji(String mode) {
    final emojis = {
      'car': '🚗',
      'flight': '✈️',
      'train': '🚆',
      'bus': '🚌',
    };
    return emojis[mode] ?? '🚗';
  }

  // Continue to Part 6 for detailed option widgets...// cost_calculator.dart - Part 6 FINAL (Add after Part 5)

  Widget _buildCarOptions(Map<String, dynamic> option) {
    try {
      final fuels = option['fuel_options'] as List?;
      
      if (fuels == null || fuels.isEmpty) {
        debugPrint('⚠️ No fuel options available for car mode');
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No fuel options available',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      
      return Column(
        children: fuels.map((fuel) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF252B48),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(fuel['color'] as int? ?? 0xFF6C63FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(fuel['icon'] ?? '⛽', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          fuel['fuel_type'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(fuel['color'] as int? ?? 0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${fuel['estimated_cost'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.access_time, '${fuel['time_hours'] ?? '0'}h'),
                    _buildInfoChip(Icons.eco, '${fuel['co2_kg'] ?? '0'}kg CO₂'),
                    _buildInfoChip(Icons.star, '${fuel['comfort_rating'] ?? 0}/5'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProsCons(
                  (fuel['pros'] as List?) ?? [],
                  (fuel['cons'] as List?) ?? [],
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('❌ Error building car options: $e');
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading options: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildTransportDetails(Map<String, dynamic> option) {
    try {
      // Safely extract values with defaults
      final costMin = option['estimated_cost_min'] as int? ?? 0;
      final costMax = option['estimated_cost_max'] as int? ?? 0;
      final timeHours = option['time_hours'] as String? ?? '0';
      final co2kg = option['co2_kg'] as String? ?? '0';
      final comfort = option['comfort_rating'] as int? ?? 0;
      final pros = (option['pros'] as List?) ?? [];
      final cons = (option['cons'] as List?) ?? [];
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF252B48),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cost Range',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8F92A1), fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹$costMin - ₹$costMax',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(option['color'] as int? ?? 0xFF6C63FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.access_time, '${timeHours}h'),
                _buildInfoChip(Icons.eco, '${co2kg}kg CO₂'),
                _buildInfoChip(Icons.star, '$comfort/5'),
              ],
            ),
            const SizedBox(height: 20),
            _buildProsCons(pros, cons),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building transport details: $e');
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading details: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2139),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProsCons(List pros, List cons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00D9FF), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pros.join(', '),
                style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel, color: Color(0xFFFF5252), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cons.join(', '),
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
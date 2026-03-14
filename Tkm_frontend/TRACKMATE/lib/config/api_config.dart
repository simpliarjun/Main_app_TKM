import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API Configuration Service
/// All API keys and URLs are loaded from .env file
class ApiConfig {
  // API Keys - loaded from .env
  static String get googlePlacesApiKey =>
      dotenv.env['places_api_key'] ?? _fallbackPlacesKey;
  
  static String get googleGeocodingApiKey =>
      dotenv.env['geocoding_api_key'] ?? _fallbackGeocodingKey;
  
  static String get googleDirectionsApiKey =>
      dotenv.env['directions_api_key'] ?? _fallbackDirectionsKey;
  
  static String get googleTranslateApiKey =>
      dotenv.env['google_translate_api_key'] ?? _fallbackTranslateKey;

  // Base URLs
  static String get baseApiUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://13.232.167.211/api';

  // Auth endpoints
  static String get loginUrl =>
      dotenv.env['LOGIN_URL'] ?? '$baseApiUrl/auth/login/';
  
  static String get signupUrl =>
      dotenv.env['SIGNUP_URL'] ?? '$baseApiUrl/auth/signup/';
  
  static String get logoutUrl =>
      dotenv.env['LOGOUT_URL'] ?? '$baseApiUrl/auth/logout/';
  
  static String get forgotPasswordUrl =>
      dotenv.env['FORGOT_PASSWORD_URL'] ?? '$baseApiUrl/auth/forgot-password/';
  
  static String get resetPasswordUrl =>
      dotenv.env['RESET_PASSWORD_URL'] ?? '$baseApiUrl/auth/reset-password/';
  
  static String get verifyPhoneOtpUrl =>
      dotenv.env['VERIFY_PHONE_OTP_URL'] ?? '$baseApiUrl/auth/verify/';
  
  static String get sendPhoneOtpUrl =>
      dotenv.env['SEND_PHONE_OTP_URL'] ?? '$baseApiUrl/auth/signup/';

  // Fallback keys (should never be used in production)
  static const String _fallbackPlacesKey = 'YOUR_GOOGLE_API_KEY_HERE';
  static const String _fallbackGeocodingKey = 'YOUR_GOOGLE_API_KEY_HERE';
  static const String _fallbackDirectionsKey = 'YOUR_GOOGLE_API_KEY_HERE';
  static const String _fallbackTranslateKey = 'YOUR_GOOGLE_API_KEY_HERE';

  // Google Maps API Constants
  static const String placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode';
  static const String directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions';

  // Validation
  static bool isConfigured() {
    return googlePlacesApiKey.isNotEmpty &&
        googleGeocodingApiKey.isNotEmpty &&
        googleDirectionsApiKey.isNotEmpty;
  }
}

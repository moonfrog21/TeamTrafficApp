/// Central configuration for Google Cloud API access.
/// This key is used by the Dart-side HTTP clients for:
///   - Google Places Autocomplete API
///   - Google Geocoding API
///   - Google Directions API
///
/// Ensure the key has the following APIs enabled in Google Cloud Console:
///   - Maps SDK for Android
///   - Maps SDK for iOS
///   - Places API
///   - Geocoding API
///   - Directions API (or Routes API)
class AppConfig {
  static const String googleMapsApiKey = 'AIzaSyCG1HNd6jMx5mjhNlpAd8HbWsIszTQ6Thk';

  // Base URLs for Google APIs
  static const String placesAutocompleteBaseUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String geocodingBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
}

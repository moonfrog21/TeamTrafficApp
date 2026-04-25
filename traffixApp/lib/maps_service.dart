import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'config.dart';

class PlaceSuggestion {
  final String description;
  final String placeId;

  PlaceSuggestion({required this.description, required this.placeId});
}

class MapsService {
  final _uuid = const Uuid();
  String? _sessionToken;

  /// Starts a new session for Places API autocomplete billing
  void startSession() {
    _sessionToken = _uuid.v4();
  }

  /// Ends the current session after a final Place Details or Geocoding call
  void endSession() {
    _sessionToken = null;
  }

  /// Fetches autocomplete suggestions from Google Places API
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String input) async {
    if (input.isEmpty) return [];
    if (_sessionToken == null) startSession();

    final url = Uri.parse(
        '${AppConfig.placesAutocompleteBaseUrl}?input=${Uri.encodeComponent(input)}&key=${AppConfig.googleMapsApiKey}&sessiontoken=$_sessionToken');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => PlaceSuggestion(
                    description: p['description'],
                    placeId: p['place_id'],
                  ))
              .toList();
        }
      }
    } catch (e) {
      // Intentionally ignore errors for autocomplete to prevent UI spam
    }
    return [];
  }

  /// Resolves a Place ID into exact Latitude/Longitude coordinates using Geocoding API
  Future<Map<String, double>?> getPlaceCoordinates(String placeId) async {
    final url = Uri.parse(
        '${AppConfig.geocodingBaseUrl}?place_id=$placeId&key=${AppConfig.googleMapsApiKey}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': location['lat'].toDouble(),
            'lng': location['lng'].toDouble(),
          };
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
}

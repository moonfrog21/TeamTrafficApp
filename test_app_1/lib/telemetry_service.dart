import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class TelemetryService {
  static String? _userId;

  /// Initialize and retrieve unique device ID
  static Future<String> _getDeviceId() async {
    if (_userId != null) return _userId!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Unique Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else {
        deviceId = 'unknown';
      }

      _userId = deviceId;
      return _userId!;
    } catch (e) {
      _userId = 'error_${DateTime.now().millisecondsSinceEpoch}';
      return _userId!;
    }
  }

  /// Request location permission and return the result
  static Future<bool> _requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse || 
             result == LocationPermission.always;
    } else if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied, user must enable in settings
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Extract current GPS location data
  static Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Construct the JSON payload with telemetry data
  static Map<String, dynamic> _constructPayload(
    double latitude,
    double longitude,
    String timestamp,
  ) {
    return {
      'user': _userId ?? 'unknown',
      'latitude': latitude.toString(),
      'Longitude': longitude.toString(),
      'time': timestamp,
    };
  }

  /// Format ISO 8601 timestamp to ISO 8601 string format
  static String _formatTimeAsIso8601(String isoTimestamp) {
    final dateTime = DateTime.parse(isoTimestamp);
    return dateTime.toIso8601String().split('.')[0];
  }

  /// Get current system time as ISO 8601 string
  static String _getCurrentTimestamp() {
    return DateTime.now().toIso8601String().split('.')[0];
  }

  /// Send GPS data to ngrok endpoint
  static Future<TelemetryResponse> sendGpsData() async {
    try {
      // Step 0: Initialize device ID
      await _getDeviceId();

      // Step 1: Request location permission
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        return TelemetryResponse(
          success: false,
          statusCode: 0,
          message: 'Location permission denied',
        );
      }

      // Step 2: Get the saved ngrok URL
      final ngrokUrl = await StorageService.getNgrokUrl();
      if (ngrokUrl == null || ngrokUrl.isEmpty) {
        return TelemetryResponse(
          success: false,
          statusCode: 0,
          message: 'Ngrok URL not configured',
        );
      }

      // Step 3: Extract current location
      final position = await _getCurrentLocation();
      if (position == null) {
        return TelemetryResponse(
          success: false,
          statusCode: 0,
          message: 'Failed to retrieve GPS location',
        );
      }

      // Step 4: Get current timestamp
      final timestamp = _getCurrentTimestamp();

      // Step 5: Construct JSON payload
      final payload = _constructPayload(
        position.latitude,
        position.longitude,
        timestamp,
      );

      // Step 6: Send HTTP POST request
      final endpoint = '$ngrokUrl/data';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const SocketException('Request timeout'),
      );

      return TelemetryResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        message: 'HTTP ${response.statusCode}',
      );
    } on SocketException catch (e) {
      return TelemetryResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    } on TimeoutException catch (_) {
      return TelemetryResponse(
        success: false,
        statusCode: 0,
        message: 'Request timeout - server unreachable',
      );
    } catch (e) {
      return TelemetryResponse(
        success: false,
        statusCode: 0,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}

/// Response model for telemetry operations
class TelemetryResponse {
  final bool success;
  final int statusCode;
  final String message;

  TelemetryResponse({
    required this.success,
    required this.statusCode,
    required this.message,
  });
}
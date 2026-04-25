import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _ngrokUrlKey = 'ngrok_url';
  static SharedPreferences? _prefs;

  /// Initialize the storage service by loading SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the saved ngrok URL from device storage
  static Future<String?> getNgrokUrl() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(_ngrokUrlKey);
  }

  /// Save the ngrok URL to device storage
  static Future<bool> setNgrokUrl(String url) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.setString(_ngrokUrlKey, url);
  }

  /// Clear the stored ngrok URL
  static Future<bool> clearNgrokUrl() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.remove(_ngrokUrlKey);
  }
}
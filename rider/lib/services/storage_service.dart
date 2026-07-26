import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  static Future<bool> setString(String key, String value) =>
      _instance.setString(key, value);
  static String? getString(String key) => _instance.getString(key);

  static Future<bool> setBool(String key, bool value) =>
      _instance.setBool(key, value);
  static bool? getBool(String key) => _instance.getBool(key);

  static Future<bool> remove(String key) => _instance.remove(key);
  static Future<bool> clear() => _instance.clear();

  static bool get isOnboardingDone =>
      getBool(AppConstants.keyOnboardingDone) ?? false;

  static Future<void> setOnboardingDone() =>
      setBool(AppConstants.keyOnboardingDone, true);

  static Future<void> saveAuthToken(String token) =>
      setString(AppConstants.keyAuthToken, token);

  static Future<void> logout() async {
    await remove(AppConstants.keyAuthToken);
    await remove(AppConstants.keyUserId);
    await remove(AppConstants.keyUserName);
    await remove(AppConstants.keyUserEmail);
    await remove(AppConstants.keyUserPhone);
  }

  static String get themeMode =>
      getString(AppConstants.keyThemeMode) ?? 'system';

  static Future<void> setThemeMode(String mode) =>
      setString(AppConstants.keyThemeMode, mode);
}

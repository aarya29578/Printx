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

  // String
  static Future<bool> setString(String key, String value) =>
      _instance.setString(key, value);

  static String? getString(String key) => _instance.getString(key);

  // Bool
  static Future<bool> setBool(String key, bool value) =>
      _instance.setBool(key, value);

  static bool? getBool(String key) => _instance.getBool(key);

  // Int
  static Future<bool> setInt(String key, int value) =>
      _instance.setInt(key, value);

  static int? getInt(String key) => _instance.getInt(key);

  // List
  static Future<bool> setStringList(String key, List<String> value) =>
      _instance.setStringList(key, value);

  static List<String>? getStringList(String key) =>
      _instance.getStringList(key);

  // Remove
  static Future<bool> remove(String key) => _instance.remove(key);

  static Future<bool> clear() => _instance.clear();

  // App-specific helpers
  static bool get isOnboardingDone =>
      getBool(AppConstants.keyOnboardingDone) ?? false;

  static Future<void> setOnboardingDone() =>
      setBool(AppConstants.keyOnboardingDone, true);

  static bool get isLoggedIn =>
      getString(AppConstants.keyAuthToken) != null;

  static Future<void> saveAuthToken(String token) =>
      setString(AppConstants.keyAuthToken, token);

  static String? get authToken =>
      getString(AppConstants.keyAuthToken);

  static Future<void> logout() async {
    await remove(AppConstants.keyAuthToken);
    await remove(AppConstants.keyUserId);
    await remove(AppConstants.keyUserName);
    await remove(AppConstants.keyUserEmail);
    await remove(AppConstants.keyUserPhone);
  }

  static List<String> get recentSearches =>
      getStringList(AppConstants.keyRecentSearches) ?? [];

  static Future<void> addRecentSearch(String query) async {
    final searches = recentSearches;
    searches.remove(query);
    searches.insert(0, query);
    final trimmed = searches.take(10).toList();
    await setStringList(AppConstants.keyRecentSearches, trimmed);
  }

  static Future<void> clearRecentSearches() =>
      remove(AppConstants.keyRecentSearches);

  static String get themeMode =>
      getString(AppConstants.keyThemeMode) ?? 'system';

  static Future<void> setThemeMode(String mode) =>
      setString(AppConstants.keyThemeMode, mode);
}

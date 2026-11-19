import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Splits sensitive session data (secure storage) from non-sensitive
/// preferences (SharedPreferences).
class SessionStorage {
  SessionStorage({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? preferences,
  }) : _secure = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferences.getInstance;

  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> Function() _preferences;

  static const _tokenKey = 'erp_access_token';
  static const _refreshKey = 'erp_refresh_token';
  static const _rememberKey = 'erp_remember_me';
  static const _employeeIdKey = 'erp_saved_employee_id';
  static const _themeKey = 'erp_theme_mode';
  static const _notificationsKey = 'erp_notifications_enabled';
  static const _lastEmailKey = 'erp_last_email';

  Future<String?> readToken() => _secure.read(key: _tokenKey);
  Future<String?> readRefreshToken() => _secure.read(key: _refreshKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secure.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secure.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _refreshKey);
  }

  Future<bool> readRememberMe() async {
    final prefs = await _preferences();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<String?> readSavedEmployeeId() async {
    final prefs = await _preferences();
    return prefs.getString(_employeeIdKey);
  }

  Future<void> saveRememberMe(bool value, {String? employeeId}) async {
    final prefs = await _preferences();
    await prefs.setBool(_rememberKey, value);
    if (value && employeeId != null) {
      await prefs.setString(_employeeIdKey, employeeId);
    } else if (!value) {
      await prefs.remove(_employeeIdKey);
    }
  }

  Future<String> readThemeMode() async {
    final prefs = await _preferences();
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> saveThemeMode(String value) async {
    final prefs = await _preferences();
    await prefs.setString(_themeKey, value);
  }

  Future<bool> readNotificationsEnabled() async {
    final prefs = await _preferences();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> saveNotificationsEnabled(bool value) async {
    final prefs = await _preferences();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<String?> readLastEmail() async {
    final prefs = await _preferences();
    return prefs.getString(_lastEmailKey);
  }

  Future<void> saveLastEmail(String value) async {
    final prefs = await _preferences();
    await prefs.setString(_lastEmailKey, value);
  }
}

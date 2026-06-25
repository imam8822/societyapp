import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  // ── In-memory cache ──
  // flutter_secure_storage reads can fail on Windows (Credential Manager
  // backend), so we keep a memory mirror that is always reliable.
  static final Map<String, String> _cache = {};

  static Future<void> saveAuthData({
    required String token,
    required String refreshToken,
    required String role,
    required String userId,
    required String userName,
  }) async {
    // Write to memory cache first (instant, always works)
    _cache[AppConstants.tokenKey] = token;
    _cache[AppConstants.refreshTokenKey] = refreshToken;
    _cache[AppConstants.roleKey] = role;
    _cache[AppConstants.userIdKey] = userId;
    _cache[AppConstants.userNameKey] = userName;

    // Then persist to secure storage (best-effort on Windows)
    try {
      await Future.wait([
        _storage.write(key: AppConstants.tokenKey, value: token),
        _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
        _storage.write(key: AppConstants.roleKey, value: role),
        _storage.write(key: AppConstants.userIdKey, value: userId),
        _storage.write(key: AppConstants.userNameKey, value: userName),
      ]);
    } catch (e) {
      debugPrint('[StorageService] Secure storage write failed: $e');
    }
    debugPrint('[StorageService] Auth data saved (token length: ${token.length})');
  }

  static Future<String?> getToken() async {
    // Check memory cache first
    if (_cache.containsKey(AppConstants.tokenKey)) {
      final token = _cache[AppConstants.tokenKey];
      debugPrint('[StorageService] getToken => cache hit (${token?.length} chars)');
      return token;
    }
    // Fall back to secure storage
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        _cache[AppConstants.tokenKey] = token;
      }
      debugPrint('[StorageService] getToken => ${token != null ? "storage hit (${token.length} chars)" : "NULL"}');
      return token;
    } catch (e) {
      debugPrint('[StorageService] getToken failed: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    if (_cache.containsKey(AppConstants.refreshTokenKey)) return _cache[AppConstants.refreshTokenKey];
    try {
      final val = await _storage.read(key: AppConstants.refreshTokenKey);
      if (val != null) _cache[AppConstants.refreshTokenKey] = val;
      return val;
    } catch (_) { return null; }
  }

  static Future<String?> getRole() async {
    if (_cache.containsKey(AppConstants.roleKey)) return _cache[AppConstants.roleKey];
    try {
      final val = await _storage.read(key: AppConstants.roleKey);
      if (val != null) _cache[AppConstants.roleKey] = val;
      return val;
    } catch (_) { return null; }
  }

  static Future<String?> getUserId() async {
    if (_cache.containsKey(AppConstants.userIdKey)) return _cache[AppConstants.userIdKey];
    try {
      final val = await _storage.read(key: AppConstants.userIdKey);
      if (val != null) _cache[AppConstants.userIdKey] = val;
      return val;
    } catch (_) { return null; }
  }

  static Future<String?> getUserName() async {
    if (_cache.containsKey(AppConstants.userNameKey)) return _cache[AppConstants.userNameKey];
    try {
      final val = await _storage.read(key: AppConstants.userNameKey);
      if (val != null) _cache[AppConstants.userNameKey] = val;
      return val;
    } catch (_) { return null; }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() async {
    _cache.clear();
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[StorageService] clearAll failed: $e');
    }
  }
}

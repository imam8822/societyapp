import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveAuthData({
    required String token,
    required String role,
    required String userId,
    required String userName,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.tokenKey, value: token),
      _storage.write(key: AppConstants.roleKey, value: role),
      _storage.write(key: AppConstants.userIdKey, value: userId),
      _storage.write(key: AppConstants.userNameKey, value: userName),
    ]);
  }

  static Future<String?> getToken() =>
      _storage.read(key: AppConstants.tokenKey);

  static Future<String?> getRole() =>
      _storage.read(key: AppConstants.roleKey);

  static Future<String?> getUserId() =>
      _storage.read(key: AppConstants.userIdKey);

  static Future<String?> getUserName() =>
      _storage.read(key: AppConstants.userNameKey);

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() => _storage.deleteAll();
}

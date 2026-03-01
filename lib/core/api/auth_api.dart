import 'api_client.dart';
import '../../models/auth_models.dart';

class AuthApi {
  static Future<LoginResponse> login(String phone, String password) async {
    final res = await ApiClient.instance.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return LoginResponse.fromJson(res.data);
  }

  static Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await ApiClient.instance.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

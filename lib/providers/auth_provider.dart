import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api/auth_api.dart';
import '../core/api/api_client.dart';
import '../core/storage/storage_service.dart';
import '../core/api/api_services.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;
  final String? role;
  final String? userName;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
    this.role,
    this.userName,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
    String? role,
    String? userName,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        role: role ?? this.role,
        userName: userName ?? this.userName,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await StorageService.isLoggedIn();
    if (loggedIn) {
      final role = await StorageService.getRole();
      final name = await StorageService.getUserName();
      state = state.copyWith(isLoggedIn: true, role: role, userName: name);
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await AuthApi.login(phone, password);
      await StorageService.saveAuthData(
        token: res.token,
        refreshToken: res.refreshToken,
        role: res.role,
        userId: res.userId.toString(),
        userName: res.fullName,
      );
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        role: res.role,
        userName: res.fullName,
      );

      try {
        await FirebaseMessaging.instance.requestPermission();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await NotificationApi.saveFcmToken(fcmToken);
        }
      } catch (_) {
        // Ignore FCM errors so login still succeeds
      }

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: apiError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    ApiClient.reset();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

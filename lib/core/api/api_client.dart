import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  static Dio? _instance;
  // Callback to notify the auth provider to log out (set externally by the app)
  static Future<void> Function()? onForceLogout;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Retry Interceptor ──
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.requestOptions.method != 'GET') {
          return handler.next(error);
        }

        // Check if it is a transient error
        bool isTransient = false;
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError ||
            (error.response != null && error.response!.statusCode! >= 500)) {
          isTransient = true;
        }

        if (!isTransient) {
          return handler.next(error);
        }

        int retryCount = error.requestOptions.extra['retryCount'] ?? 0;
        if (retryCount >= 3) {
          if (kDebugMode) {
            debugPrint('[ApiClient] ❌ Exhausted all 3 retries for ${error.requestOptions.path}');
          }
          return handler.next(error);
        }

        retryCount++;
        error.requestOptions.extra['retryCount'] = retryCount;

        // Exponential backoff: 1s, 2s, 4s
        int delaySeconds = 1 << (retryCount - 1);
        if (kDebugMode) {
          debugPrint('[ApiClient] ⚠️ Transient error on ${error.requestOptions.path}. Retrying in ${delaySeconds}s (Attempt $retryCount/3)...');
        }
        await Future.delayed(Duration(seconds: delaySeconds));

        try {
          final retryRes = await dio.fetch(error.requestOptions);
          return handler.resolve(retryRes);
        } catch (e) {
          return handler.next(e is DioException ? e : error);
        }
      },
    ));

    // ── Auth interceptor — attach JWT to every request ──
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) {
            debugPrint('[ApiClient] Token attached to ${options.method} ${options.path}');
          }
        } else {
          if (kDebugMode) {
            debugPrint('[ApiClient] ⚠️ NO TOKEN for ${options.method} ${options.path}');
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[ApiClient] ❌ ${error.response?.statusCode} on ${error.requestOptions.path}');
        }
        
        if (error.response?.statusCode == 401 && 
            !error.requestOptions.path.contains('/auth/refresh') && 
            !error.requestOptions.path.contains('/auth/login')) {
          
          final token = await StorageService.getToken();
          final refreshToken = await StorageService.getRefreshToken();
          
          if (token != null && refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
              final res = await refreshDio.post('/auth/refresh', data: {
                'token': token,
                'refreshToken': refreshToken
              });
              
              final newToken = res.data['token'];
              final newRefreshToken = res.data['refreshToken'];
              final role = res.data['role'];
              final userId = res.data['userId'].toString();
              final fullName = res.data['fullName'];
              
              await StorageService.saveAuthData(
                token: newToken,
                refreshToken: newRefreshToken,
                role: role,
                userId: userId,
                userName: fullName
              );

              // Retry original request
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryRes = await dio.fetch(error.requestOptions);
              return handler.resolve(retryRes);
            } catch (e) {
              // Refresh failed — force logout via the auth provider
              if (kDebugMode) {
                debugPrint('[ApiClient] Token refresh failed, forcing logout');
              }
              await StorageService.clearAll();
              reset();
              // Trigger full auth provider logout so GoRouter redirects to /login
              if (onForceLogout != null) {
                await onForceLogout!();
              }
            }
          } else {
            // No tokens at all — force logout
            await StorageService.clearAll();
            reset();
            if (onForceLogout != null) {
              await onForceLogout!();
            }
          }
        }
        
        return handler.next(error);
      },
    ));

    return dio;
  }

  // Reset client (e.g. after logout)
  static void reset() => _instance = null;
}

// Helper to extract error message from API response
String apiError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.response?.statusCode == 401) return 'Session expired. Please login again.';
    if (e.response?.statusCode == 403) return 'You do not have permission to do this.';
    if (e.response?.statusCode == 409) return 'This record was changed by someone else. Please refresh and try again.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your network.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      if (e.error != null && e.error.toString().contains('SocketException')) {
        return 'No internet connection. Please check your network.';
      }
      return 'Cannot reach server. Check your network.';
    }
  }
  return 'An unexpected error occurred. Please try again.';
}

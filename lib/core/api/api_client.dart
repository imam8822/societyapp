import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  static Dio? _instance;

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
          debugPrint('[ApiClient] ❌ Exhausted all 3 retries for ${error.requestOptions.path}');
          // NetworkErrorWidget will be shown downstream
          return handler.next(error);
        }

        retryCount++;
        error.requestOptions.extra['retryCount'] = retryCount;

        // Exponential backoff: 1s, 2s, 4s
        int delaySeconds = 1 << (retryCount - 1);
        debugPrint('[ApiClient] ⚠️ Transient error on ${error.requestOptions.path}. Retrying in ${delaySeconds}s (Attempt $retryCount/3)...');
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
          debugPrint('[ApiClient] Token attached to ${options.method} ${options.path}');
        } else {
          debugPrint('[ApiClient] ⚠️ NO TOKEN for ${options.method} ${options.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        debugPrint('[ApiClient] ❌ ${error.response?.statusCode} on ${error.requestOptions.path}');
        
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
              // Refresh failed, let the app handle logout
              debugPrint('[ApiClient] Token refresh failed: $e');
              await StorageService.clearAll();
              reset();
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
  return e.toString();
}

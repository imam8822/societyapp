import 'package:dio/dio.dart';
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

    // ── Auth interceptor — attach JWT to every request ──
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
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
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your network.';
    }
  }
  return e.toString();
}

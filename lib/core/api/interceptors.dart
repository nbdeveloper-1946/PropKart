import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class JwtInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Ignore errors reading storage in requests
    }
    super.onRequest(options, handler);
  }
}

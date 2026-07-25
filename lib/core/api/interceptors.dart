import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../storage/session_cleanup.dart';

class JwtInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  /// Paths that must not trigger forced logout on 401 (login/register).
  static const _authExemptPrefixes = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/forgot',
    '/auth/reset',
    '/health',
  ];

  bool _isExempt(RequestOptions options) {
    final path = options.path;
    for (final prefix in _authExemptPrefixes) {
      if (path.contains(prefix)) return true;
    }
    return false;
  }

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
    } catch (_) {}
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 401 && !_isExempt(err.requestOptions)) {
      // Fire-and-forget local teardown + AuthBloc notification.
      SessionCleanup.clearLocalSession(clearToken: true).whenComplete(() {
        SessionCleanup.notifyForcedLogout();
      });
    }
    super.onError(err, handler);
  }
}

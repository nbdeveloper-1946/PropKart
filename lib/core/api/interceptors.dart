import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../storage/session_cleanup.dart';
import '../../features/auth/repository/auth_repository.dart';

class JwtInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();
  final AuthRepository _authRepository = AuthRepository();

  bool _isRefreshing = false;

  /// Paths that must not trigger forced logout / refresh on 401.
  static const _authExemptPrefixes = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/forgot',
    '/auth/reset',
    '/auth/refresh',
    '/health',
  ];

  /// Public endpoints should not receive Authorization (confused deputy).
  static const _publicPrefixes = <String>[
    '/share-sessions/public',
    '/auth/login',
    '/auth/refresh',
    '/auth/forgot',
    '/health',
  ];

  bool _matchesAny(String path, List<String> prefixes) {
    for (final prefix in prefixes) {
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
      if (!_matchesAny(options.path, _publicPrefixes)) {
        final token = await _secureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } else {
        options.headers.remove('Authorization');
      }
    } catch (_) {}
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status == 401 && !_matchesAny(path, _authExemptPrefixes)) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshed = await _authRepository.refreshSession();
          if (refreshed) {
            final token = await _secureStorage.getToken();
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final clone = await Dio(
                BaseOptions(
                  baseUrl: opts.baseUrl,
                  connectTimeout: opts.connectTimeout,
                  receiveTimeout: opts.receiveTimeout,
                ),
              ).fetch(opts);
              _isRefreshing = false;
              return handler.resolve(clone);
            } catch (e) {
              // fall through to logout
            }
          }
        } finally {
          _isRefreshing = false;
        }
      }

      await SessionCleanup.clearLocalSession(clearToken: true);
      SessionCleanup.notifyForcedLogout();
    }
    super.onError(err, handler);
  }
}

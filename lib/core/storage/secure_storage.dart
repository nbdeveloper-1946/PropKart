import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _webSessionHintKey = 'web_cookie_session';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String? inMemoryToken;
  static String? inMemoryRefreshToken;
  /// Web cookie-session marker (not a secret — cookies hold the tokens).
  static bool webCookieSession = false;

  /// On web: keep access token in memory only as fallback when cookies are blocked.
  /// Never persist JWTs to disk/localStorage on web.
  Future<void> saveToken(String token, {bool persist = true}) async {
    inMemoryToken = token;
    await _storage.delete(key: _tokenKey);
    if (kIsWeb && !kDebugMode) {
      return;
    }
    if (persist) {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Future<void> saveRefreshToken(String? refreshToken, {bool persist = true}) async {
    inMemoryRefreshToken = refreshToken;
    await _storage.delete(key: _refreshTokenKey);
    if (kIsWeb && !kDebugMode) {
      // Refresh stays in HttpOnly cookie on web — do not persist to JS storage.
      inMemoryRefreshToken = null;
      return;
    }
    if (refreshToken == null || refreshToken.isEmpty) return;
    if (persist) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> markWebCookieSession({required bool active, bool persistHint = false}) async {
    webCookieSession = active;
    if (!kIsWeb) return;
    if (active && persistHint) {
      await _storage.write(key: _webSessionHintKey, value: '1');
    } else {
      await _storage.delete(key: _webSessionHintKey);
    }
  }

  Future<bool> hasWebSessionHint() async {
    if (!kIsWeb) return false;
    if (webCookieSession) return true;
    final v = await _storage.read(key: _webSessionHintKey);
    return v == '1';
  }

  Future<String?> getToken() async {
    return inMemoryToken ?? (kIsWeb && !kDebugMode ? null : await _storage.read(key: _tokenKey));
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb && !kDebugMode) return null;
    return inMemoryRefreshToken ?? await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteToken() async {
    inMemoryToken = null;
    inMemoryRefreshToken = null;
    webCookieSession = false;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _webSessionHintKey);
  }
}

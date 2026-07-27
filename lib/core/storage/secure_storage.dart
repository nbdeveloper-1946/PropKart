import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String? inMemoryToken;
  static String? inMemoryRefreshToken;

  /// Always clears any previous persisted tokens first so a non-remembered
  /// login cannot leave another user's JWT on disk.
  ///
  /// On web, tokens are kept in memory only unless [persist] is true
  /// (remember-me). Browser storage is not a keychain.
  Future<void> saveToken(String token, {bool persist = true}) async {
    inMemoryToken = token;
    await _storage.delete(key: _tokenKey);
    if (persist && !kIsWeb) {
      await _storage.write(key: _tokenKey, value: token);
    } else if (persist && kIsWeb) {
      // Web: still write when user explicitly asked remember-me,
      // but prefer session memory; document residual XSS risk.
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Future<void> saveRefreshToken(String? refreshToken, {bool persist = true}) async {
    inMemoryRefreshToken = refreshToken;
    await _storage.delete(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return;
    if (persist) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getToken() async {
    return inMemoryToken ?? await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return inMemoryRefreshToken ?? await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteToken() async {
    inMemoryToken = null;
    inMemoryRefreshToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

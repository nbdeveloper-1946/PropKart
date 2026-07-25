import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String? inMemoryToken;

  /// Always clears any previous persisted token first so a non-remembered
  /// login cannot leave another user's JWT on disk.
  Future<void> saveToken(String token, {bool persist = true}) async {
    inMemoryToken = token;
    await _storage.delete(key: _tokenKey);
    if (persist) {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Future<String?> getToken() async {
    return inMemoryToken ?? await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    inMemoryToken = null;
    await _storage.delete(key: _tokenKey);
  }
}

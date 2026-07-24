import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = "auth_token";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String? inMemoryToken;

  Future<void> saveToken(String token, {bool persist = true}) async {
    inMemoryToken = token;
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

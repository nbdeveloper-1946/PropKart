import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/session_cleanup.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();

  Future<UserModel> login(String email, String password, bool rememberMe) async {
    // Drop prior session data before accepting a new identity.
    await SessionCleanup.clearLocalSession(clearToken: true);

    final responseData = await _authService.login(email, password);
    final user = UserModel.fromJson(responseData);

    if (user.token == null || user.token!.isEmpty) {
      throw Exception('Login succeeded but no access token was returned.');
    }

    await _secureStorage.saveToken(user.token!, persist: rememberMe);
    return user;
  }

  Future<UserModel> getProfile() async {
    try {
      final responseData = await _authService.getProfile();
      final token = await _secureStorage.getToken();

      final userMap = Map<String, dynamic>.from(responseData);
      if (token != null) {
        userMap['token'] = token;
      }
      return UserModel.fromJson(userMap);
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    await SessionCleanup.clearLocalSession(clearToken: true);
  }

  Future<String?> getSavedToken() async {
    return await _secureStorage.getToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}

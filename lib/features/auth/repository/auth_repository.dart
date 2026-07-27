import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/session_cleanup.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();

  Future<UserModel> login(String email, String password, bool rememberMe) async {
    await SessionCleanup.clearLocalSession(clearToken: true);

    final responseData = await _authService.login(
      email,
      password,
      rememberMe: rememberMe,
    );
    final user = UserModel.fromJson(responseData);

    if (user.token == null || user.token!.isEmpty) {
      throw Exception('Login succeeded but no access token was returned.');
    }

    final refresh = _extractRefreshToken(responseData);

    // On web without remember-me: memory-only tokens (no disk persist).
    final shouldPersist = rememberMe;

    await _secureStorage.saveToken(user.token!, persist: shouldPersist);
    await _secureStorage.saveRefreshToken(refresh, persist: shouldPersist);

    // Do not keep JWT on the in-memory user model used by UI/equality.
    return user.copyWith(token: null);
  }

  String? _extractRefreshToken(Map<String, dynamic> responseData) {
    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data['refreshToken']?.toString() ?? data['refresh_token']?.toString();
    }
    return responseData['refreshToken']?.toString() ??
        responseData['refresh_token']?.toString();
  }

  Future<bool> refreshSession() async {
    final refresh = await _secureStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await _authService.refresh(refresh);
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final access = data['token']?.toString() ?? data['accessToken']?.toString();
      final nextRefresh = data['refreshToken']?.toString() ?? data['refresh_token']?.toString();
      if (access == null || access.isEmpty) return false;

      final hadPersistedRefresh = await _secureStorage.getRefreshToken() != null;
      await _secureStorage.saveToken(access, persist: hadPersistedRefresh);
      if (nextRefresh != null && nextRefresh.isNotEmpty) {
        await _secureStorage.saveRefreshToken(nextRefresh, persist: hadPersistedRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final responseData = await _authService.getProfile();
      return UserModel.fromJson(responseData).copyWith(token: null);
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    final refresh = await _secureStorage.getRefreshToken();
    try {
      await _authService.logout(refreshToken: refresh);
    } catch (_) {}
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

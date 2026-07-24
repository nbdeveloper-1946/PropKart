import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();

  Future<UserModel> login(String email, String password, bool rememberMe) async {
    final responseData = await _authService.login(email, password);
    final user = UserModel.fromJson(responseData);
    
    if (user.token != null) {
      await _secureStorage.saveToken(user.token!, persist: rememberMe);
    }
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
      // If profile fetching fails (token expired / invalid), clear local storage
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteToken();
  }

  Future<String?> getSavedToken() async {
    return await _secureStorage.getToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}

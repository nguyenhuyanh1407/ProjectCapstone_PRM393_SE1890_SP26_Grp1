import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<User> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return User.fromJson(response);
  }

  Future<void> logout() async {
    await _apiService.get('/auth/logout');
  }
}

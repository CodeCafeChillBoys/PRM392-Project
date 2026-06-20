import '../datasources/remote/api_client.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  // Gọi API đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    final body = {
      'username': username,
      'password': password,
    };
    
    // Gửi POST request tới BE
    final response = await _apiClient.post(ApiConstants.loginEndpoint, body);
    
    // Trả về dữ liệu từ BE (thường chứa Token và User data)
    return response; 
  }
}

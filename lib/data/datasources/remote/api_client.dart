import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class ApiClient {
  final http.Client _client = http.Client();

  // Hàm xử lý GET request
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  // Hàm xử lý POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  // Hàm xử lý chung kết quả trả về từ server
  dynamic _processResponse(http.Response response) {
    // Nếu BE trả về mảng thay vì object, jsonDecode sẽ tạo ra List
    final body = jsonDecode(response.body);
    
    // Status Code 2xx là thành công
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      // Bắt lỗi từ server trả về (tuỳ vào cấu trúc JSON lỗi của BE)
      throw Exception(body['message'] ?? 'Có lỗi xảy ra (Code: ${response.statusCode})');
    }
  }
}

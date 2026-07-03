import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

/// Thrown when the backend returns a non-2xx status.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin HTTP wrapper around the TechStoreAPI. Endpoints and base URL come from
/// [ApiConfig]; the JSON (de)serialisation lives in the model classes.
///
/// This is wired but dormant: while [AppConfig.useMockData] is `true` the
/// services never call it. When the backend is ready, flip that flag and these
/// methods are exercised — add the auth header in [_headers] then.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Optional bearer token, set after login once auth is wired end-to-end.
  String? authToken;
  String? userId;
  String? userName;
  String? userEmail;
  String? userRole;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? query}) async {
    final res = await _client
        .get(ApiConfig.uri(endpoint, query), headers: _headers)
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> post(String endpoint, {Object? body}) async {
    final res = await _client
        .post(ApiConfig.uri(endpoint),
            headers: _headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> put(String endpoint, {Object? body}) async {
    final res = await _client
        .put(ApiConfig.uri(endpoint),
            headers: _headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  Future<dynamic> delete(String endpoint) async {
    final res = await _client
        .delete(ApiConfig.uri(endpoint), headers: _headers)
        .timeout(ApiConfig.timeout);
    return _decode(res);
  }

  /// Gửi multipart/form-data (POST/PUT) — upload ảnh sản phẩm.
  /// [fileField] phải khớp tên property IFormFile bên BE (mặc định `Image`).
  Future<dynamic> sendMultipart(
    String method,
    String endpoint, {
    Map<String, String> fields = const {},
    String? filePath,
    String fileField = 'Image',
  }) async {
    final request = http.MultipartRequest(method, ApiConfig.uri(endpoint));
    request.headers['Accept'] = 'application/json';
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    request.fields.addAll(fields);
    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    final streamed = await request.send().timeout(ApiConfig.timeout);
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _errorMessage(res.body));
  }

  /// BE trả lỗi dạng JSON string ("Ảnh tối đa 5MB") hoặc object — bóc ra
  /// text đọc được cho toast; body không phải JSON thì dùng thô.
  static String _errorMessage(String body) {
    if (body.isEmpty) return body;
    try {
      final decoded = jsonDecode(body);
      if (decoded is String) return decoded;
      if (decoded is Map<String, dynamic>) {
        final m = decoded['message'] ?? decoded['title'] ?? decoded['error'];
        if (m is String) return m;
      }
    } catch (_) {
      // body không phải JSON → giữ nguyên.
    }
    return body;
  }
}

/// Shared client instance used by the service layer.
final ApiClient apiClient = ApiClient();

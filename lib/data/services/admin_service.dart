import '../../core/config/api_config.dart';
import '../models/admin_stats.dart';
import '../models/device_info.dart';
import '../models/login_session_info.dart';
import '../models/product.dart';
import '../models/user_summary.dart';
import 'api_client.dart';

/// Gọi các endpoint CHỈ-Admin (UsersController + AdminController phía BE, đều
/// `[Authorize(Policy="AdminOnly")]`). ApiClient tự đính kèm Bearer token nên
/// role được thực thi ở BE — FE chỉ điều hướng, không phải hàng rào bảo mật.
///
/// Các controller trả thẳng list/object (không bọc `{success,data}`), nhưng
/// helper vẫn chịu được dạng bọc `{data:[]}` phòng khi BE thêm result filter.
class AdminService {
  AdminService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  // ── Người dùng ────────────────────────────────────────────────────────────

  /// Danh sách người dùng, lọc tuỳ chọn theo [role] ('Customer'|'Staff'|'Admin').
  Future<List<UserSummary>> fetchUsers({String? role}) async {
    final json = await _client.get(
      ApiConfig.usersList,
      query: (role != null && role.isNotEmpty) ? {'role': role} : null,
    );
    return _asList(json).map(UserSummary.fromJson).toList();
  }

  /// Đổi role người dùng → trả về bản ghi đã cập nhật. Ném [ApiException] khi
  /// BE từ chối (vd không tìm thấy user, role không hợp lệ).
  Future<UserSummary> changeUserRole(String id, String role) async {
    final json = await _client.put(
      ApiConfig.userRole(id),
      body: {'role': role},
    );
    return UserSummary.fromJson(_asMap(json));
  }

  // ── Thống kê / vận hành ────────────────────────────────────────────────────

  /// Thống kê dashboard. [from]/[to] gửi dạng ISO-8601 **UTC** (BE lọc theo
  /// `OrderDate` UTC); bỏ trống → BE mặc định 30 ngày gần nhất.
  Future<AdminStats> fetchStats({DateTime? from, DateTime? to}) async {
    final query = <String, dynamic>{
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    final json = await _client.get(
      ApiConfig.adminStats,
      query: query.isEmpty ? null : query,
    );
    return AdminStats.fromJson(_asMap(json));
  }

  Future<List<LoginSessionInfo>> fetchSessions() async {
    final json = await _client.get(ApiConfig.adminSessions);
    return _asList(json).map(LoginSessionInfo.fromJson).toList();
  }

  Future<List<DeviceInfo>> fetchDevices() async {
    final json = await _client.get(ApiConfig.adminDevices);
    return _asList(json).map(DeviceInfo.fromJson).toList();
  }

  // ── Kho ────────────────────────────────────────────────────────────────────

  /// Sản phẩm tồn ≤ [threshold] (mặc định 10 — khớp default BE).
  Future<List<Product>> fetchLowStock({int threshold = 10}) async {
    final json = await _client.get(
      ApiConfig.adminLowStock,
      query: {'threshold': threshold},
    );
    return _asList(json).map(Product.fromJson).toList();
  }

  /// Cập nhật tồn kho 1 sản phẩm → trả về bản ghi đã cập nhật.
  Future<Product> updateStock(String id, int quantity) async {
    final json = await _client.put(
      ApiConfig.adminProductStock(id),
      body: {'stockQuantity': quantity},
    );
    return Product.fromJson(_asMap(json));
  }

  // ── Helpers (chịu cả bare-list lẫn `{data:[]}`) ─────────────────────────────

  static List<Map<String, dynamic>> _asList(dynamic json) {
    final raw = json is Map<String, dynamic>
        ? (json['data'] ?? json['items'])
        : json;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  static Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is Map<String, dynamic>) return data;
      return json;
    }
    return <String, dynamic>{};
  }
}

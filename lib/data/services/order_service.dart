import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../models/order_model.dart';
import 'api_client.dart';

/// Result of a checkout — the created order id and, for gateway methods
/// (VNPay), the URL the app should hand off to.
class OrderResult {
  const OrderResult({required this.orderId, this.gatewayUrl});
  final String orderId;
  final String? gatewayUrl;

  bool get needsGateway => gatewayUrl != null;
}

/// Places orders via `POST /api/order/checkout` (Checkout & Billing).
class OrderService {
  OrderService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  /// [paymentMethod] must be one of `VNPay | CreditCard | BankTransfer | COD`.
  Future<OrderResult> checkout({
    required String shippingAddress,
    required String paymentMethod,
    required double total,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 900));
      // Deterministic demo order id (no Random — keeps mock reproducible).
      final orderId = 'TV${24900 + (total.round() % 90)}';
      return OrderResult(
        orderId: orderId,
        gatewayUrl: paymentMethod == 'VNPay'
            ? '${ApiConfig.baseUrl}${ApiConfig.vnpayGateway(orderId)}'
            : null,
      );
    }
    final userId = _client.userId;
    if (userId == null) {
      throw Exception('Chưa đăng nhập — không thể đặt hàng.');
    }
    final json = await _client.post(ApiConfig.checkout, body: {
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'userId': userId, // BE bắt buộc userId
    }) as Map<String, dynamic>;
    // orderId: VNPay trả ở top-level, COD nằm trong data.id
    final data = json['data'];
    final orderId = json['orderId'] ??
        json['id'] ??
        (data is Map<String, dynamic> ? data['id'] : null) ??
        '';
    return OrderResult(
      orderId: '$orderId',
      gatewayUrl: json['paymentUrl'] as String? ?? json['gatewayUrl'] as String?,
    );
  }

  /// Tra trạng thái thanh toán của đơn (cho màn chờ VNPay): 'Pending' | 'Paid' | 'Failed'.
  Future<String> fetchPaymentStatus(String orderId) async {
    final json = await _client.get(ApiConfig.orderById(orderId));
    final map = (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json is Map<String, dynamic> ? json : <String, dynamic>{});
    return map['paymentStatus'] as String? ?? '';
  }

  /// Lấy tất cả đơn (cho trang Staff).
  Future<List<OrderModel>> fetchAllOrders() async {
    final json = await _client.get(ApiConfig.orders);
    final list = json is List ? json : const [];
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy đơn của 1 user (cho màn "Đơn của tôi").
  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    final json = await _client.get(ApiConfig.ordersByUser(userId));
    final list = json is List ? json : const [];
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Đổi trạng thái đơn (Staff): PUT /api/Orders/{id}/status (body = chuỗi trạng thái).
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.put(ApiConfig.orderStatusById(orderId), body: status);
  }
}

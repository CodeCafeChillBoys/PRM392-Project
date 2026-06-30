import 'package:latlong2/latlong.dart';

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
    double? destinationLat,
    double? destinationLng,
    double? shippingFee,
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
      // Toạ độ + phí ship: BE bỏ qua tới khi bổ sung (gap C1 trong báo cáo),
      // gửi sẵn để khi BE thêm là chạy luôn không cần sửa FE.
      'destinationLat': ?destinationLat,
      'destinationLng': ?destinationLng,
      'shippingFee': ?shippingFee,
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

  /// Gán shipper cho đơn (Staff) → BE tự đổi status sang Shipped.
  /// PUT /api/orders/{id}/assign-shipper?staffId={staffId}
  Future<void> assignShipper(String orderId, String staffId) async {
    await _client.put('${ApiConfig.assignShipper(orderId)}?staffId=$staffId');
  }

  /// Shipper gửi vị trí hiện tại → BE lưu + bắn realtime cho khách (SignalR).
  /// POST /api/tracking/location
  Future<void> sendLocation({
    required String shipperId,
    required double lat,
    required double lng,
    String? orderId,
  }) async {
    await _client.post(ApiConfig.trackingLocation, body: {
      'shipperId': shipperId,
      'lat': lat,
      'lng': lng,
      'orderId': ?orderId,
    });
  }

  /// Vị trí shipper hiện tại của đơn (gọi 1 lần khi mở map theo dõi).
  /// null nếu BE chưa có (đơn chưa giao / shipper chưa gửi GPS).
  Future<LatLng?> fetchShipperLocation(String orderId) async {
    try {
      final json = await _client.get(ApiConfig.trackingByOrder(orderId));
      if (json is Map) {
        final lat = (json['lat'] as num?)?.toDouble();
        final lng = (json['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    } catch (_) {
      // 400/404: đơn chưa ở trạng thái giao hoặc shipper chưa gửi vị trí.
    }
    return null;
  }
}

import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
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
    final json = await _client.post(ApiConfig.checkout, body: {
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
    }) as Map<String, dynamic>;
    return OrderResult(
      orderId: '${json['orderId'] ?? json['id'] ?? ''}',
      gatewayUrl: json['paymentUrl'] as String? ?? json['gatewayUrl'] as String?,
    );
  }
}

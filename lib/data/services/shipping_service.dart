import '../../core/config/api_config.dart';
import '../models/shipping_quote.dart';
import 'api_client.dart';

/// Tính phí ship qua BE `POST /api/shipping/calculate`.
/// BE dùng Goong tính khoảng cách thực tế từ kho → toạ độ nhà khách, trả về
/// quãng đường (km), thời gian dự kiến (phút), phí ship (đ) và tuyến đường vẽ.
class ShippingService {
  ShippingService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<ShippingQuote> calculate({
    required double destinationLat,
    required double destinationLng,
  }) async {
    final json = await _client.post(
      ApiConfig.shippingCalculate,
      body: {
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
      },
    ) as Map<String, dynamic>;
    return ShippingQuote.fromJson(json);
  }
}

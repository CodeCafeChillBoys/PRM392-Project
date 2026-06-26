import '../../core/config/api_config.dart';
import '../models/address_option.dart';
import 'api_client.dart';

/// Gọi BE Shipping (BE proxy sang GHN): danh sách tỉnh/huyện/xã + tính phí ship.
class ShippingService {
  ShippingService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<List<AddressOption>> fetchProvinces() =>
      _fetchList(ApiConfig.shippingProvinces);

  Future<List<AddressOption>> fetchDistricts(int provinceId) =>
      _fetchList(ApiConfig.shippingDistricts(provinceId));

  Future<List<AddressOption>> fetchWards(int districtId) =>
      _fetchList(ApiConfig.shippingWards(districtId));

  Future<List<AddressOption>> _fetchList(String endpoint) async {
    final json = await _client.get(endpoint);
    final list = json is List ? json : const [];
    return list
        .map((e) => AddressOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tính phí ship (đ). [toWardCode] là chuỗi; [weight] gram (null → BE dùng mặc định).
  Future<int> calcFee({
    required int toDistrictId,
    required String toWardCode,
    int? weight,
  }) async {
    final json = await _client.post(ApiConfig.shippingFee, body: {
      'toDistrictId': toDistrictId,
      'toWardCode': toWardCode,
      'weight': ?weight,
    }) as Map<String, dynamic>;
    return (json['total'] as num?)?.toInt() ?? 0;
  }
}

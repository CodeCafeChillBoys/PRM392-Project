import '../../core/config/api_config.dart';
import '../models/cart_item.dart';
import 'api_client.dart';

/// Gọi module Cart của TechStoreAPI (/api/Carts).
class CartService {
  CartService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  /// GET: lấy giỏ hàng của user đang đăng nhập.
  Future<List<CartItem>> fetchCart() async {
    final userId = _client.userId;
    if (userId == null) return [];                       // chưa đăng nhập → giỏ rỗng
    final json = await _client.get(ApiConfig.cartByUserId(userId));
    final list = json is List ? json : const [];         // BE trả về MẢNG thẳng
    return list
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST: thêm 1 sản phẩm vào giỏ.
  Future<void> addItem(String productId, int quantity) async {
    final userId = _client.userId;
    if (userId == null) return;
    await _client.post(ApiConfig.cartAdd, body: {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
    });
  }

  /// PUT: đặt lại số lượng cho 1 dòng giỏ.
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _client.put(ApiConfig.cartItemById(cartItemId), body: {'quantity': quantity});
  }

  /// DELETE: xoá 1 dòng giỏ.
  Future<void> removeItem(String cartItemId) async {
    await _client.delete(ApiConfig.cartItemById(cartItemId));
  }

  /// DELETE: xoá sạch giỏ của user.
  Future<void> clearCart() async {
    final userId = _client.userId;
    if (userId == null) return;
    await _client.delete(ApiConfig.cartClear(userId));
  }
}

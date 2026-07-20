import '../../core/config/api_config.dart';
import '../models/cart_item.dart';
import 'api_client.dart';

/// Gọi module Cart của TechStoreAPI (/api/Carts).
class CartService {
  CartService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<List<CartItem>> fetchCart() async {
    final userId = _client.userId;
    if (userId == null) return [];
    final json = await _client.get(ApiConfig.cartByUserId(userId));
    final list = json is List ? json : const [];
    return list
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem(String productId, int quantity) async {
    final userId = _client.userId;
    if (userId == null) return;
    await _client.post(
      ApiConfig.cartAdd,
      body: {'userId': userId, 'productId': productId, 'quantity': quantity},
    );
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _client.put(
      ApiConfig.cartItemById(cartItemId),
      body: {'quantity': quantity},
    );
  }

  Future<void> removeItem(String cartItemId) async {
    await _client.delete(ApiConfig.cartItemById(cartItemId));
  }

  Future<void> clearCart() async {
    final userId = _client.userId;
    if (userId == null) return;
    await _client.delete(ApiConfig.cartClear(userId));
  }
}

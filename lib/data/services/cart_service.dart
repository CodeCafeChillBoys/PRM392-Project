import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../models/cart_item.dart';
import 'api_client.dart';
import 'mock_data.dart';

/// Talks to the TechStoreAPI Cart module (add / update-qty / remove).
///
/// The UI's source of truth is the in-memory `CartController`; this service is
/// what that controller calls to persist changes to the backend. In mock mode
/// the mutations just simulate latency and echo the result back.
class CartService {
  CartService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<List<CartItem>> fetchCart() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockData.cart;
    }
    final json = await _client.get(ApiConfig.cart);
    final List<dynamic> list = (json is Map<String, dynamic> && json['data'] is List)
        ? (json['data'] as List)
        : (json is List ? json : []);
    return list
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem(String productId, int quantity) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return;
    }
    await _client
        .post(ApiConfig.cart, body: {'productId': productId, 'quantity': quantity});
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return;
    }
    await _client
        .put(ApiConfig.cartItemById(cartItemId), body: {'quantity': quantity});
  }

  Future<void> removeItem(String cartItemId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return;
    }
    await _client.delete(ApiConfig.cartItemById(cartItemId));
  }
}

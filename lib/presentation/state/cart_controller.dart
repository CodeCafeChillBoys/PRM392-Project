import 'package:flutter/foundation.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/services/cart_service.dart';

/// Giỏ hàng: mỗi thao tác gọi API qua [CartService] rồi refresh lại từ BE.
class CartController extends ChangeNotifier {
  CartController({CartService? service}) : _service = service ?? CartService();

  final CartService _service;
  List<CartItem> _items = const [];
  bool _loading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isEmpty => _items.isEmpty;
  String? get error => _error;
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.totalPrice);

  /// Tải/đồng bộ giỏ từ BE.
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchCart();
    } catch (e) {
      _error = 'Không tải được giỏ hàng.';
      _items = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => refresh();

  Future<void> add(Product product, {int quantity = 1}) async {
    try {
      await _service.addItem(product.id, quantity);
      await refresh();
    } catch (e) {
      _error = 'Thêm vào giỏ thất bại.';
      notifyListeners();
    }
  }

  Future<void> setQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) return remove(cartItemId);
    try {
      await _service.updateQuantity(cartItemId, quantity);
      await refresh();
    } catch (e) {
      _error = 'Cập nhật số lượng thất bại.';
      notifyListeners();
    }
  }

  Future<void> remove(String cartItemId) async {
    try {
      await _service.removeItem(cartItemId);
      await refresh();
    } catch (e) {
      _error = 'Xoá sản phẩm thất bại.';
      notifyListeners();
    }
  }

  Future<void> clear() async {
    try {
      await _service.clearCart();
      await refresh();
    } catch (e) {
      _error = 'Xoá giỏ thất bại.';
      notifyListeners();
    }
  }
}

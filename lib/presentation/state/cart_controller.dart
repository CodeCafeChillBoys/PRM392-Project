import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/services/cart_service.dart';

/// In-memory cart — the UI's source of truth. Mutations update locally for an
/// instant response, then sync to the backend through [CartService]
/// (fire-and-forget; failures are non-fatal while running on mock data).
class CartController extends ChangeNotifier {
  CartController({CartService? service}) : _service = service ?? CartService() {
    _load();
  }

  final CartService _service;
  final List<CartItem> _items = [];
  bool _loading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isEmpty => _items.isEmpty;
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.totalPrice);

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      final seed = await _service.fetchCart();
      _items
        ..clear()
        ..addAll(seed);
    } catch (_) {
      // Keep an empty cart on failure; UI shows the empty state.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => _load();

  /// Add [product] (merging quantity if it's already in the cart).
  void add(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => i.productId == product.id);
    if (index >= 0) {
      _items[index] =
          _items[index].copyWith(quantity: _items[index].quantity + quantity);
    } else {
      _items.add(CartItem.fromProduct(
        product,
        quantity: quantity,
        id: 'c_${product.id}_${_items.length}',
      ));
    }
    notifyListeners();
    unawaited(_service.addItem(product.id, quantity).catchError((Object _) {}));
  }

  void setQuantity(String cartItemId, int quantity) {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index < 0) return;
    if (quantity <= 0) {
      remove(cartItemId);
      return;
    }
    _items[index] = _items[index].copyWith(quantity: quantity);
    notifyListeners();
    unawaited(
        _service.updateQuantity(cartItemId, quantity).catchError((Object _) {}));
  }

  void remove(String cartItemId) {
    _items.removeWhere((i) => i.id == cartItemId);
    notifyListeners();
    unawaited(_service.removeItem(cartItemId).catchError((Object _) {}));
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/services/cart_service.dart';

/// Giỏ hàng — BE là nguồn dữ liệu chính (source of truth).
///
/// Mỗi thao tác (thêm/sửa/xoá) gọi API tới [CartService] rồi [refresh] lại từ
/// backend, để giỏ luôn đồng bộ và mỗi dòng giỏ mang ĐÚNG `id` thật của BE
/// (cần cho sửa số lượng / xoá). Khác với bản cũ: không còn cập nhật local kiểu
/// "fire-and-forget" và không nuốt lỗi.
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

  /// Tải/đồng bộ giỏ hàng từ BE. Gọi sau khi đăng nhập và sau mỗi thay đổi.
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

  /// Giữ tên cũ cho nơi nào còn gọi.
  Future<void> reload() => refresh();

  /// Thêm [product] vào giỏ (BE tự cộng dồn nếu đã có) rồi đồng bộ lại.
  Future<void> add(Product product, {int quantity = 1}) async {
    try {
      await _service.addItem(product.id, quantity);
      await refresh();
    } catch (e) {
      _error = 'Thêm vào giỏ thất bại.';
      notifyListeners();
    }
  }

  /// Đặt lại số lượng cho 1 dòng giỏ ([cartItemId] = id thật do BE trả về).
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

  /// Xoá 1 dòng giỏ.
  Future<void> remove(String cartItemId) async {
    try {
      await _service.removeItem(cartItemId);
      await refresh();
    } catch (e) {
      _error = 'Xoá sản phẩm thất bại.';
      notifyListeners();
    }
  }

  /// Xoá sạch giỏ của user.
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

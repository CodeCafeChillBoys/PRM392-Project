import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Danh sách "Yêu thích" lưu LOCAL (SharedPreferences) — thuần client, không API.
/// Singleton + [ValueNotifier] để tim trên card, badge header và màn Wishlist
/// cùng cập nhật realtime khi bật/tắt ở bất kỳ đâu.
class WishlistService {
  WishlistService._();
  static final WishlistService instance = WishlistService._();
  static const _key = 'void_wishlist_ids';

  /// Tập id sản phẩm đã thích. Nghe [notifier] để rebuild khi đổi.
  final ValueNotifier<Set<String>> notifier = ValueNotifier<Set<String>>({});

  Set<String> get ids => notifier.value;
  int get count => notifier.value.length;
  bool isWished(String id) => notifier.value.contains(id);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      notifier.value = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    } catch (_) {
      notifier.value = <String>{};
    }
  }

  /// Bật/tắt yêu thích 1 sản phẩm; trả về trạng thái mới (true = đã thích).
  Future<bool> toggle(String id) async {
    final next = Set<String>.from(notifier.value);
    final nowWished = !next.remove(id);
    if (nowWished) next.add(id);
    notifier.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, next.toList());
    } catch (_) {
      // Lưu lỗi (hiếm) → giữ trạng thái trong bộ nhớ, không chặn UI.
    }
    return nowWished;
  }
}

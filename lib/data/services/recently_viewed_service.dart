import 'package:shared_preferences/shared_preferences.dart';

/// Lưu id sản phẩm KHÁCH VỪA XEM (local, không cần BE).
///
/// Chỉ lưu id — tên/giá/ảnh luôn đọc từ catalog hiện tại nên không bao giờ
/// hiển thị dữ liệu cũ (giá đổi, hết hàng...). Danh sách mới nhất đứng trước,
/// tối đa [_max] mục.
class RecentlyViewedService {
  RecentlyViewedService._();
  static final instance = RecentlyViewedService._();

  static const _key = 'void_recently_viewed_ids';
  static const _max = 10;

  List<String> _ids = const [];

  /// Id đã xem, mới nhất trước (rỗng nếu chưa nạp/chưa xem gì).
  List<String> get ids => _ids;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids = prefs.getStringList(_key) ?? const [];
    } catch (_) {
      _ids = const [];
    }
  }

  /// Ghi nhận vừa xem [productId] — đẩy lên đầu, khử trùng, cắt bớt đuôi.
  Future<void> add(String productId) async {
    if (productId.isEmpty) return;
    _ids = [productId, ..._ids.where((e) => e != productId)].take(_max).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids);
    } catch (_) {
      // Không lưu được cũng không sao — danh sách trong phiên vẫn đúng.
    }
  }
}

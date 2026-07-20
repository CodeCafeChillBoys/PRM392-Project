import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_address.dart';

/// Sổ địa chỉ giao hàng lưu LOCAL (SharedPreferences) — thuần client, không API.
///
/// Theo khuôn [RecentlyViewedService]/[WishlistService]: singleton, nạp 1 lần
/// rồi giữ trong bộ nhớ. Danh sách phát qua [notifier] để Sổ địa chỉ và bảng
/// chọn ở Checkout cùng cập nhật realtime khi thêm/sửa/xoá/đổi mặc định.
///
/// Bất biến: tối đa 1 địa chỉ [SavedAddress.isDefault]; địa chỉ mặc định luôn
/// được sắp lên đầu danh sách để UI hiển thị nhất quán.
class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  static const _key = 'void_saved_addresses_v1';

  /// Nguồn sự thật — nghe qua [ValueListenableBuilder] để rebuild khi đổi.
  final ValueNotifier<List<SavedAddress>> notifier =
      ValueNotifier<List<SavedAddress>>(const []);

  bool _loaded = false;

  /// Bản sao chỉ-đọc danh sách hiện tại (mặc định đứng đầu).
  List<SavedAddress> list() => notifier.value;

  /// Địa chỉ mặc định — null khi sổ trống. Không thể đặt tên getter là
  /// `default` (từ khoá Dart) nên dùng [defaultAddress].
  SavedAddress? get defaultAddress {
    final items = notifier.value;
    if (items.isEmpty) return null;
    return items.firstWhere((a) => a.isDefault, orElse: () => items.first);
  }

  /// Nạp từ đĩa. An toàn khi gọi lại nhiều lần (chỉ đọc đĩa lần đầu).
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const <String>[];
      final items = <SavedAddress>[];
      for (final s in raw) {
        try {
          items.add(
            SavedAddress.fromJson(jsonDecode(s) as Map<String, dynamic>),
          );
        } catch (_) {
          // Bỏ qua bản ghi hỏng, không làm hỏng cả sổ.
        }
      }
      _loaded = true;
      _emit(_ordered(items));
    } catch (_) {
      _loaded = true;
      _emit(const []);
    }
  }

  /// Thêm địa chỉ mới. Địa chỉ đầu tiên trong sổ tự động thành mặc định.
  Future<void> add(SavedAddress address) async {
    var items = [...notifier.value];
    final makeDefault = address.isDefault || items.isEmpty;
    if (makeDefault) {
      items = items.map((a) => a.copyWith(isDefault: false)).toList();
    }
    items.add(address.copyWith(isDefault: makeDefault));
    await _persist(items);
  }

  /// Cập nhật địa chỉ theo [SavedAddress.id]. Bỏ qua nếu không tìm thấy.
  Future<void> update(SavedAddress address) async {
    final items = [...notifier.value];
    final idx = items.indexWhere((a) => a.id == address.id);
    if (idx == -1) return;
    items[idx] = address;
    if (address.isDefault) {
      for (var i = 0; i < items.length; i++) {
        if (i != idx) items[i] = items[i].copyWith(isDefault: false);
      }
    }
    await _persist(items);
  }

  /// Xoá địa chỉ theo [id]. Nếu vừa xoá cái mặc định mà sổ vẫn còn địa chỉ →
  /// gán cái đầu tiên làm mặc định để luôn có 1 địa chỉ mặc định.
  Future<void> remove(String id) async {
    final items = [...notifier.value]..removeWhere((a) => a.id == id);
    if (items.isNotEmpty && !items.any((a) => a.isDefault)) {
      items[0] = items[0].copyWith(isDefault: true);
    }
    await _persist(items);
  }

  /// Đặt [id] làm địa chỉ mặc định (bỏ mặc định ở các địa chỉ còn lại).
  Future<void> setDefault(String id) async {
    if (!notifier.value.any((a) => a.id == id)) return;
    final items = notifier.value
        .map((a) => a.copyWith(isDefault: a.id == id))
        .toList();
    await _persist(items);
  }

  // Mặc định luôn lên đầu; giữ nguyên thứ tự chèn của các địa chỉ còn lại.
  List<SavedAddress> _ordered(List<SavedAddress> items) => [
    ...items.where((a) => a.isDefault),
    ...items.where((a) => !a.isDefault),
  ];

  Future<void> _persist(List<SavedAddress> items) async {
    final ordered = _ordered(items);
    _emit(ordered);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        ordered.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (_) {
      // Không lưu được cũng không sao — danh sách trong phiên vẫn đúng.
    }
  }

  void _emit(List<SavedAddress> items) =>
      notifier.value = List.unmodifiable(items);
}

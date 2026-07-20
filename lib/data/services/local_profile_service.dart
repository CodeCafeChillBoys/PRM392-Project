import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thông tin cá nhân lưu LOCAL. Hiện chỉ số điện thoại: BE chưa có endpoint cập
/// nhật hồ sơ (tên/email lấy từ phiên đăng nhập, chỉ đọc), nên số ĐT lưu trên
/// máy để hiển thị + điền nhanh sau này. Singleton + [ValueNotifier] cho realtime.
class LocalProfileService {
  LocalProfileService._();
  static final LocalProfileService instance = LocalProfileService._();
  static const _phoneKey = 'void_local_phone';

  final ValueNotifier<String> phone = ValueNotifier<String>('');

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      phone.value = p.getString(_phoneKey) ?? '';
    } catch (_) {
      phone.value = '';
    }
  }

  Future<void> setPhone(String value) async {
    phone.value = value.trim();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_phoneKey, value.trim());
    } catch (_) {
      // Lưu lỗi (hiếm) → giữ trong bộ nhớ.
    }
  }
}

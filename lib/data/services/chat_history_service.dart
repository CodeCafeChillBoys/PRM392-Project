import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lưu lịch sử hội thoại chat AI (local, không cần BE — BE không lưu hội thoại).
///
/// Toàn bộ danh sách tin nhắn được [jsonEncode] thành 1 chuỗi và cất trong
/// SharedPreferences ([_key]); chỉ giữ [_max] tin gần nhất để prefs không phình.
/// Cùng kiểu singleton + prefs như [RecentlyViewedService].
class ChatHistoryService {
  ChatHistoryService._();
  static final instance = ChatHistoryService._();

  static const _key = 'void_chat_history_v1';
  static const _max = 200;

  List<Map<String, dynamic>> _messages = const [];

  /// Lịch sử đã nạp (rỗng nếu chưa nạp / chưa có gì).
  List<Map<String, dynamic>> get messages => _messages;

  /// Nạp lịch sử từ prefs. Dữ liệu hỏng / sai định dạng → trả rỗng (không ném).
  Future<List<Map<String, dynamic>>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        _messages = const [];
        return _messages;
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _messages = decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList(growable: false);
      } else {
        _messages = const [];
      }
    } catch (_) {
      _messages = const [];
    }
    return _messages;
  }

  /// Ghi đè toàn bộ lịch sử (giữ [_max] tin cuối). Lỗi ghi → bỏ qua, phiên
  /// hiện tại vẫn đúng.
  Future<void> save(List<Map<String, dynamic>> messages) async {
    _messages = messages.length > _max
        ? messages.sublist(messages.length - _max)
        : List<Map<String, dynamic>>.from(messages);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_messages));
    } catch (_) {
      // Không lưu được cũng không sao.
    }
  }

  /// Xoá sạch lịch sử (prefs + cache trong phiên).
  Future<void> clear() async {
    _messages = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Bỏ qua — coi như đã xoá ở phía UI.
    }
  }
}

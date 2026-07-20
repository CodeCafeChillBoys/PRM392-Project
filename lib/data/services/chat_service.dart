import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import 'api_client.dart';

/// Gọi ChatBot AI của TechStoreAPI (`POST /api/Chat`) — Gemini phía BE.
/// BE không nhận/lưu lịch sử hội thoại, mỗi lần gọi chỉ gửi 1 tin nhắn.
class ChatService {
  ChatService({ApiClient? client}) : _client = client ?? apiClient;
  final ApiClient _client;

  Future<String> sendMessage(String message) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return _mockReply(message);
    }
    final json = await _client.post(ApiConfig.chat, body: {'message': message});
    final Map<String, dynamic> data =
        (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : (json is Map<String, dynamic> ? json : {});
    final reply = data['reply'];
    if (reply is String && reply.trim().isNotEmpty) return reply;
    return 'Xin lỗi, mình chưa có câu trả lời.';
  }

  /// Vài mẫu trả lời tiếng Việt giả lập, chọn theo từ khoá đơn giản.
  String _mockReply(String message) {
    final q = message.toLowerCase();
    if (q.contains('ship')) {
      return 'Phí ship được tính theo khoảng cách thực tế từ kho đến địa chỉ nhận hàng của bạn, hiển thị ngay ở bước Thanh toán nhé.';
    }
    if (q.contains('iphone') || q.contains('sản phẩm')) {
      return 'Shop hiện có nhiều mẫu iPhone và thiết bị công nghệ chính hãng, bạn có thể xem chi tiết ở trang Sản phẩm nhé.';
    }
    return 'Xin chào! Mình là trợ lý AI của TechStore, rất vui được hỗ trợ bạn.';
  }
}

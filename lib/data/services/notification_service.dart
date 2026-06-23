import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../models/app_notification.dart';
import 'api_client.dart';
import 'mock_data.dart';

/// Loads the user's notification feeds (promo + orders).
class NotificationService {
  NotificationService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<NotificationFeeds> fetchNotifications() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockData.notifications;
    }
    final json = await _client.get(ApiConfig.notifications) as Map<String, dynamic>;
    List<AppNotification> parse(String key) => (json[key] as List? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationFeeds(promo: parse('promo'), orders: parse('orders'));
  }
}

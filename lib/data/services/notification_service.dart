import '../../core/config/api_config.dart';
import '../models/app_notification.dart';
import 'api_client.dart';

/// Loads the user's notification feeds (promo + orders).
class NotificationService {
  NotificationService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<NotificationFeeds> fetchNotifications() async {
    final json = await _client.get(ApiConfig.notifications);
    final Map<String, dynamic> data = (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : (json is Map<String, dynamic> ? json : {});
    List<AppNotification> parse(String key) => (data[key] as List? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationFeeds(promo: parse('promo'), orders: parse('orders'));
  }

  Future<void> markAsRead(String id) async {
    await _client.put(ApiConfig.markNotificationRead(id));
  }

  Future<void> markAllAsRead() async {
    await _client.put(ApiConfig.markAllNotificationsRead);
  }
}

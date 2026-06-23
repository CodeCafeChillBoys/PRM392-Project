/// Tone of a notification's leading icon tile.
enum NotificationTone { accent, violet, neutral }

NotificationTone _toneFromString(String? s) {
  switch (s) {
    case 'violet':
      return NotificationTone.violet;
    case 'neutral':
      return NotificationTone.neutral;
    default:
      return NotificationTone.accent;
  }
}

/// A notification row (promo or order update).
class AppNotification {
  const AppNotification({
    required this.iconName,
    required this.tone,
    required this.unread,
    required this.title,
    required this.body,
    required this.time,
  });

  final String iconName;
  final NotificationTone tone;
  final bool unread;
  final String title;
  final String body;
  final String time;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        iconName: json['icon'] as String? ?? 'bell',
        tone: _toneFromString(json['tone'] as String?),
        unread: json['unread'] as bool? ?? false,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        time: json['time'] as String? ?? '',
      );
}

/// Two notification feeds, mirroring the screen's Khuyến mãi / Đơn hàng tabs.
class NotificationFeeds {
  const NotificationFeeds({required this.promo, required this.orders});

  final List<AppNotification> promo;
  final List<AppNotification> orders;
}

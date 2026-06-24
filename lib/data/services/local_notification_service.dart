import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service with platform configurations
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // In ra FCM Token để kiểm tra
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('================ FCM TOKEN ================\n$token\n==========================================');
    } catch (e) {
      debugPrint('Lỗi lấy FCM Token khi khởi tạo LocalNotificationService: $e');
    }

    // Đăng ký nhận tin nhắn khi app đang mở ở foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('--- NHẬN ĐƯỢC TIN NHẮN FCM FOREGROUND ---');
      debugPrint('Message data payload: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message notification title: ${message.notification?.title}');
        debugPrint('Message notification body: ${message.notification?.body}');
      }

      // Hỗ trợ cả trường hợp BE gửi bằng Notification payload hoặc Data-only payload
      final title = message.notification?.title ?? 
                    message.data['title'] ?? 
                    message.data['notificationTitle'] ?? 
                    'Thông báo';
      final body = message.notification?.body ?? 
                   message.data['body'] ?? 
                   message.data['message'] ?? 
                   message.data['notificationBody'] ?? 
                   '';

      if (message.notification != null || body.isNotEmpty) {
        showNotification(
          title: title,
          body: body,
        );
      } else {
        debugPrint('Không thể hiển thị thông báo vì cả notification và body đều rỗng.');
      }
    });
  }

  /// Request permissions for local notifications (iOS and Android 13+)
  static Future<void> requestPermission() async {
    // Xin quyền cho Firebase Messaging
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Yêu cầu quyền Firebase Messaging thất bại: $e');
    }

    // Xin quyền cho Local Notifications
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Show a notification in the status bar
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fcm_foreground_channel_id',
      'Thông báo TechStore',
      channelDescription: 'Kênh hiển thị thông báo FCM khi ứng dụng ở foreground',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 999, // Notification ID
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}

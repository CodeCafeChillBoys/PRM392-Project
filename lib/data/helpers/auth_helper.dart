import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:tech_void/data/models/device_context.dart';

import 'device_helper.dart';

class AuthHelper {
  AuthHelper._();

  static Future<DeviceContext> getDeviceContext() async {
    final deviceInfo = await DeviceHelper.getDeviceInfo();

    String fcmToken = '';

    try {
      fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    } catch (e) {
      debugPrint('FirebaseMessaging token retrieval failed: $e');
    }

    return DeviceContext(
      deviceId: deviceInfo['deviceId'] ?? '',
      deviceName: deviceInfo['deviceName'] ?? '',
      deviceType: deviceInfo['deviceType'] ?? '',
      fcmToken: fcmToken,
    );
  }
}

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;

      return {
        'deviceId': androidInfo.id,
        'deviceName': '${androidInfo.brand} ${androidInfo.model}',
        'deviceType': 'Android',
      };
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;

      return {
        'deviceId': iosInfo.identifierForVendor ?? '',
        'deviceName': iosInfo.name,
        'deviceType': 'iOS',
      };
    }

    return {'deviceId': '', 'deviceName': '', 'deviceType': ''};
  }
}

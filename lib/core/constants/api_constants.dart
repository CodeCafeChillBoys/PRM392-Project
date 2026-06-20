import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Thay địa chỉ IP tĩnh này bằng IPv4 của máy tính bạn (dùng ipconfig trên Windows)
  // nếu bạn cắm cáp chạy máy thật.
  static const String physicalDeviceIp = '192.168.1.15'; 

  static String get baseUrl {
    if (kIsWeb) {
      // Chạy trên trình duyệt Web
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid) {
      // Chạy trên Emulator Android (Dùng 10.0.2.2)
      // Nếu chạy trên điện thoại thật Android, đổi thành: return 'http://$physicalDeviceIp:5000/api';
      return 'http://10.0.2.2:5000/api';
    } else if (Platform.isIOS) {
      // Chạy trên iOS Simulator
      // Nếu chạy trên iPhone thật, đổi thành: return 'http://$physicalDeviceIp:5000/api';
      return 'http://localhost:5000/api';
    } else {
      // Desktop Windows/Mac
      return 'http://localhost:5000/api';
    }
  }
  
  // Các endpoint
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String productsEndpoint = '/products';
}

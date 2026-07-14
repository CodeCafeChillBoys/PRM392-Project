import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

/// Bộ chuyển theme dual-mode: dark "VOID LUXE" (mặc định) / light "VOID PAPER".
///
/// Là NƠI DUY NHẤT gọi [AppColors.configure]. Widget đọc AppColors tại build
/// nên chỉ những cây đang watch controller này mới rebuild — RootShell,
/// StaffShell và MaterialApp gốc watch nó; toggle đặt ở tab Cá nhân (đỉnh
/// stack) nên mọi thứ đang hiển thị đều được vẽ lại ngay.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _prefKey = 'void_theme_is_light';

  bool _isLight = false;
  bool get isLight => _isLight;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKey);
      if (saved != null && saved != _isLight) {
        _apply(saved);
      }
    } catch (_) {
      // Không đọc được prefs → giữ dark mặc định.
    }
  }

  void toggle() => setLight(!_isLight);

  void setLight(bool value) {
    if (value == _isLight) return;
    _apply(value);
    // Lưu nền sau, không chặn UI.
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_prefKey, value))
        .catchError((_) => true);
  }

  void _apply(bool isLight) {
    _isLight = isLight;
    AppColors.configure(isLight: isLight);
    // Status bar: nền trong suốt, icon tương phản với canvas của theme.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      ),
    );
    notifyListeners();
  }
}

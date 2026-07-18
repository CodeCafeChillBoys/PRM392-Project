import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../state/theme_controller.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import '../../../data/services/auth_service.dart';

/// Tiện ích dùng chung cho 4 tab-page của khu Admin: nút app bar (đổi theme +
/// đăng xuất) và luồng logout — tránh lặp ở từng màn.
class AdminActions {
  AdminActions._();

  /// Danh sách nút cho `TvAppBar.actions`: [extra] (nút riêng của màn) đặt
  /// trước, rồi tới toggle theme và đăng xuất — thứ tự đồng nhất mọi tab.
  static List<Widget> appBar(
    BuildContext context, {
    List<Widget> extra = const [],
  }) {
    return [
      ...extra,
      TvIconButton(
        icon: TvIcon(
          AppColors.isLight ? 'moon' : 'sun',
          color: AppColors.textAccent,
        ),
        tooltip: AppColors.isLight ? 'Chuyển nền tối' : 'Chuyển nền sáng',
        onPressed: () => context.read<ThemeController>().toggle(),
      ),
      TvIconButton(
        icon: TvIcon('log-out', color: AppColors.textAccent),
        tooltip: 'Đăng xuất',
        onPressed: () => logout(context),
      ),
    ];
  }

  /// Đăng xuất → xoá session + về màn đăng nhập (xoá cả stack).
  static Future<void> logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

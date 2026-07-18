import 'package:flutter/material.dart';

import '../../data/services/api_client.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/root_shell.dart';
import '../screens/staff/staff_shell.dart';

/// Small navigation helpers shared across screens.
class AppRoutes {
  AppRoutes._();

  /// Email được cấp quyền Staff → vào thẳng App Staff (dùng `userId` Guid thật
  /// từ JWT làm `staffId`). Tạm hardcode để test; khi BE có role Staff thật thì
  /// thay bằng đọc `role` từ JWT.
  static const Set<String> staffEmails = {'vuquang02062004@gmail.com'};

  static bool isStaffEmail(String? email) =>
      email != null && staffEmails.contains(email.toLowerCase());

  /// Vào app sau khi xác thực thành công, xoá stack đăng nhập để nút back không
  /// quay lại được luồng login. Ưu tiên: Admin → Staff → khách (RootShell).
  static void enterApp(BuildContext context) {
    // Admin xét TRƯỚC Staff: role thật từ JWT (BE đã có enum Admin + policy).
    // Không có fallback email cho Admin — chỉ JWT role mới mở khu quản trị.
    if (apiClient.userRole == 'Admin') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminShell()),
        (route) => false,
      );
      return;
    }
    // Ưu tiên role thật từ JWT; email chỉ là fallback (trước khi BE set role).
    if (apiClient.userRole == 'Staff' || isStaffEmail(apiClient.userEmail)) {
      apiClient.userRole = 'Staff';
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StaffShell()),
        (route) => false,
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const RootShell(welcomeMessage: 'Đăng nhập thành công!'),
      ),
      (route) => false,
    );
  }
}

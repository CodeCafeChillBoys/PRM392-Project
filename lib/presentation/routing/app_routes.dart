import 'package:flutter/material.dart';

import '../screens/root_shell.dart';

/// Small navigation helpers shared across screens.
class AppRoutes {
  AppRoutes._();

  /// Enter the main app after a successful verification, clearing the auth
  /// stack so the back button can't return to the login flow.
  static void enterApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RootShell(welcomeMessage: 'Đăng nhập thành công!'),
      ),
      (route) => false,
    );
  }
}

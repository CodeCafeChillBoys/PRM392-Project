import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../state/theme_controller.dart';
import '../../widgets/widgets.dart';
import 'admin_orders_stock_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_ops_screen.dart';
import 'admin_users_screen.dart';

/// Khung khu vực Admin: bottom nav 4 tab (Tổng quan · Người dùng · Vận hành ·
/// Đơn & Kho) — cùng pattern [StaffShell]. Mỗi tab là tab-page tự có app bar;
/// shell lo Scaffold + nav. IndexedStack giữ state khi chuyển tab (khỏi tải lại
/// dữ liệu dashboard mỗi lần bấm nav).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _navItems = [
    TvNavItem(label: 'Tổng quan', iconName: 'layout-dashboard'),
    TvNavItem(label: 'Người dùng', iconName: 'users'),
    TvNavItem(label: 'Vận hành', iconName: 'activity'),
    TvNavItem(label: 'Đơn & Kho', iconName: 'package'),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Watch theme để shell admin vẽ lại khi đổi light/dark.
    context.watch<ThemeController>();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: IndexedStack(
        // Key theo theme — remount tab (nhiều widget const) khi đổi light/dark.
        key: ValueKey('admin-tabs-${AppColors.isLight}'),
        index: _index,
        children: const [
          AdminOverviewScreen(),
          AdminUsersScreen(),
          AdminOpsScreen(),
          AdminOrdersStockScreen(),
        ],
      ),
      bottomNavigationBar: TvBottomNav(
        items: _navItems,
        activeIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

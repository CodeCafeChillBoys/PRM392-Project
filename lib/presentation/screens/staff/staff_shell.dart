import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../state/theme_controller.dart';
import '../../widgets/widgets.dart';
import 'staff_orders_screen.dart';
import 'staff_products_screen.dart';
import 'staff_refunds_screen.dart';
import 'staff_revenue_screen.dart';

/// Khung khu vực Staff: bottom nav 4 tab (Giao hàng · Sản phẩm · Hoàn tiền ·
/// Doanh thu) —
/// pattern RootShell của khách. Mỗi tab là tab-page tự có app bar; shell lo
/// Scaffold + nav. IndexedStack giữ state để timer GPS màn giao hàng không
/// bị reset khi chuyển tab.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  static const _navItems = [
    TvNavItem(label: 'Giao hàng', iconName: 'truck'),
    TvNavItem(label: 'Sản phẩm', iconName: 'package'),
    TvNavItem(label: 'Hoàn tiền', iconName: 'refund'),
    TvNavItem(label: 'Doanh thu', iconName: 'bar-chart'),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Watch theme để shell staff vẽ lại khi đổi light/dark.
    context.watch<ThemeController>();
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: IndexedStack(
        // Key theo theme — remount tab const khi đổi light/dark.
        // (Đổi theme sẽ reset timer GPS đang chạy; staff bấm lại "Xem & Chạy".)
        key: ValueKey('staff-tabs-${AppColors.isLight}'),
        index: _index,
        children: const [
          StaffOrdersScreen(),
          StaffProductsScreen(),
          StaffRefundsScreen(),
          StaffRevenueScreen(),
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/widgets.dart';
import 'staff_orders_screen.dart';
import 'staff_products_screen.dart';
import 'staff_revenue_screen.dart';

/// Khung khu vực Staff: bottom nav 3 tab (Giao hàng · Sản phẩm · Doanh thu) —
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
    TvNavItem(label: 'Doanh thu', iconName: 'bar-chart'),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: IndexedStack(
        index: _index,
        children: const [
          StaffOrdersScreen(),
          StaffProductsScreen(),
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

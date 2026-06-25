import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../state/app_nav.dart';
import '../state/cart_controller.dart';
import '../widgets/widgets.dart';
import 'profile/profile_screen.dart';
import 'shop/cart_screen.dart';
import 'shop/product_list_screen.dart';

/// Main app shell after sign-in: a bottom-nav scaffold over the four tabs
/// (Explore / Search / Cart / Profile). The selected tab is driven by [AppNav]
/// so deeper routes (e.g. product detail) can switch tabs.
///
/// Detail, checkout and notifications are pushed full-screen routes on top of
/// this shell.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.welcomeMessage});

  /// One-off toast shown after entering the app (e.g. "Đăng nhập thành công!").
  final String? welcomeMessage;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _navItems = [
    TvNavItem(label: 'Explore', iconName: 'compass'),
    TvNavItem(label: 'Search', iconName: 'search'),
    TvNavItem(label: 'Cart', iconName: 'shopping-bag'),
    TvNavItem(label: 'Profile', iconName: 'user'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Vào app sau khi đăng nhập → tải giỏ hàng thật từ BE (userId đã có).
      context.read<CartController>().refresh();
      final message = widget.welcomeMessage;
      if (message != null) TvToast.show(context, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<AppNav>().tabIndex;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: DotGridBackground(
        child: IndexedStack(
          index: index,
          children: const [
            ProductListScreen(),
            ProductListScreen(autofocusSearch: true),
            CartScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: TvBottomNav(
        items: _navItems,
        activeIndex: index,
        onChanged: (i) => context.read<AppNav>().select(i),
      ),
    );
  }
}

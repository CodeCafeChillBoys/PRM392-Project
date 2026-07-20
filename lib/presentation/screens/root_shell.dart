import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../state/app_nav.dart';
import '../state/cart_controller.dart';
import '../state/theme_controller.dart';
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
  // Label tiếng Việt — đồng bộ ngôn ngữ với toàn app (hết lai tiếng Anh).
  static final _navItems = [
    const TvNavItem(label: 'Khám phá', iconName: 'compass'),
    const TvNavItem(label: 'Tìm kiếm', iconName: 'search'),
    // Icon giỏ = đích của hiệu ứng bay vào giỏ (bottom nav chỉ có 1 trong shell).
    TvNavItem(
      label: 'Giỏ hàng',
      iconName: 'shopping-bag',
      iconKey: FlyToCart.cartIconKey,
    ),
    const TvNavItem(label: 'Cá nhân', iconName: 'user'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Tải giỏ từ BE sau khi đăng nhập.
      context.read<CartController>().refresh();
      final message = widget.welcomeMessage;
      if (message != null) TvToast.show(context, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme để toàn shell (tabs đang hiển thị) vẽ lại khi đổi light/dark.
    context.watch<ThemeController>();
    final index = context.watch<AppNav>().tabIndex;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      // extendBody để nội dung cuộn lộ sau bottom nav glass (BackdropFilter).
      extendBody: true,
      body: DotGridBackground(
        child: IndexedStack(
          // Key theo theme: các tab là const instance nên sẽ không tự rebuild
          // khi đổi light/dark — đổi key để remount với palette mới.
          key: ValueKey('tabs-${AppColors.isLight}'),
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
        floating: true, // khu khách: nav nổi kính bo tròn (VOID CYAN)
        onChanged: (i) => context.read<AppNav>().select(i),
      ),
    );
  }
}

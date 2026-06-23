import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/services/notification_service.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';

/// Notifications — Khuyến mãi / Đơn hàng tabs with notification rows.
/// Mirrors `NotificationsScreen.jsx`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  String _tab = 'promo';
  NotificationFeeds? _feeds;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final feeds = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _feeds = feeds;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().count;
    final appNav = context.read<AppNav>();
    final list = _tab == 'promo'
        ? (_feeds?.promo ?? const <AppNotification>[])
        : (_feeds?.orders ?? const <AppNotification>[]);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Thông báo',
            onBack: () => Navigator.pop(context),
            actions: [
              TvIconButton(
                icon: const TvIcon('shopping-cart'),
                badge: cartCount > 0 ? cartCount : null,
                tooltip: 'Giỏ hàng',
                onPressed: () {
                  appNav.goToCart();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        TvTabs(
                          distribute: true,
                          value: _tab,
                          onChanged: (v) => setState(() => _tab = v),
                          tabs: const [
                            TvTab('promo', 'KHUYẾN MÃI'),
                            TvTab('orders', 'ĐƠN HÀNG'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                TvNotificationItem(notification: list[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

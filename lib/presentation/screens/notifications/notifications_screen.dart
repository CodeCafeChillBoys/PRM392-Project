import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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

  Future<void> _markAsRead(AppNotification notification) async {
    if (!notification.unread) return;

    if (_feeds == null) return;

    final updatedPromo = _feeds!.promo.map((item) {
      if (item.id == notification.id) {
        return item.copyWith(unread: false);
      }
      return item;
    }).toList();

    final updatedOrders = _feeds!.orders.map((item) {
      if (item.id == notification.id) {
        return item.copyWith(unread: false);
      }
      return item;
    }).toList();

    setState(() {
      _feeds = NotificationFeeds(promo: updatedPromo, orders: updatedOrders);
    });

    try {
      await _service.markAsRead(notification.id);
    } catch (e) {
      if (mounted) {
        TvToast.show(context, 'Không thể cập nhật trạng thái đã đọc');
        _load();
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final hasUnreadPromo = _feeds?.promo.any((item) => item.unread) ?? false;
    final hasUnreadOrders = _feeds?.orders.any((item) => item.unread) ?? false;
    if (!hasUnreadPromo && !hasUnreadOrders) {
      TvToast.show(context, 'Không có thông báo mới nào');
      return;
    }

    if (_feeds != null) {
      final updatedPromo = _feeds!.promo
          .map((item) => item.copyWith(unread: false))
          .toList();
      final updatedOrders = _feeds!.orders
          .map((item) => item.copyWith(unread: false))
          .toList();
      setState(() {
        _feeds = NotificationFeeds(promo: updatedPromo, orders: updatedOrders);
      });
    }

    try {
      await _service.markAllAsRead();
      if (mounted) {
        TvToast.show(context, 'Đã đánh dấu đọc tất cả thông báo');
      }
    } catch (e) {
      if (mounted) {
        TvToast.show(context, 'Không thể đánh dấu đọc tất cả');
        _load();
      }
    }
  }

  /// Thông báo "ma" cho skeleton.
  static const _ghost = AppNotification(
    id: 'ghost',
    iconName: 'bell',
    tone: NotificationTone.neutral,
    unread: false,
    title: 'Đang tải thông báo',
    body: 'Nội dung thông báo đang được tải về từ máy chủ.',
    time: 'vừa xong',
  );

  Widget _skeleton() => Skeletonizer(
    effect: ShimmerEffect(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
    ),
    child: ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        58,
        AppSpacing.gutter,
        24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const TvNotificationItem(notification: _ghost),
    ),
  );

  /// Empty state theo từng tab (trước đây tab rỗng chỉ là khoảng trắng).
  Widget _empty() {
    final promo = _tab == 'promo';
    return ListView(
      children:
          [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSoft,
                      border: Border.all(color: AppColors.accentSoftLine),
                    ),
                    child: TvIcon(
                      promo ? 'ticket-percent' : 'package',
                      size: 30,
                      color: AppColors.textAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    promo ? 'Chưa có khuyến mãi' : 'Chưa có thông báo đơn hàng',
                    style: AppText.h2().copyWith(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      promo
                          ? 'Ưu đãi và mã giảm giá mới sẽ xuất hiện ở đây.'
                          : 'Cập nhật về đơn hàng của bạn sẽ hiện ở đây.',
                      textAlign: TextAlign.center,
                      style: AppText.sm(AppColors.textTertiary),
                    ),
                  ),
                ),
              ]
              .animate(interval: AppEffects.staggerStep)
              .fadeIn(duration: AppEffects.durEnter)
              .moveY(
                begin: AppEffects.entranceRise,
                end: 0,
                curve: AppEffects.easeStandard,
              ),
    );
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
                icon: const TvIcon('check-check'),
                tooltip: 'Đọc tất cả',
                onPressed: _loading ? null : _markAllAsRead,
              ),
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
                ? _skeleton()
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      8,
                      AppSpacing.gutter,
                      24,
                    ),
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
                          child: list.isEmpty
                              ? _empty()
                              : ListView.separated(
                                  // Key theo tab → đổi tab là stagger chạy lại.
                                  key: ValueKey(_tab),
                                  padding: EdgeInsets.zero,
                                  itemCount: list.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) =>
                                      TvNotificationItem(
                                            notification: list[i],
                                            onTap: () => _markAsRead(list[i]),
                                          )
                                          .animate(
                                            delay:
                                                AppEffects.staggerStep *
                                                i.clamp(0, 6),
                                          )
                                          .fadeIn(
                                            duration: AppEffects.durEnter,
                                            curve: AppEffects.easeStandard,
                                          )
                                          .moveY(
                                            begin: AppEffects.entranceRise,
                                            end: 0,
                                            duration: AppEffects.durEnter,
                                            curve: AppEffects.easeStandard,
                                          ),
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';

/// Khoảng thời gian lọc doanh thu — áp cho mọi số trên màn (theo `orderDate`).
enum _RevenueRange {
  today('Hôm nay'),
  last7Days('7 ngày'),
  thisMonth('Tháng này'),
  all('Tất cả');

  const _RevenueRange(this.label);
  final String label;

  bool accepts(DateTime? d, DateTime now) {
    if (this == _RevenueRange.all) return true;
    if (d == null) return false;
    switch (this) {
      case _RevenueRange.today:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case _RevenueRange.last7Days:
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case _RevenueRange.thisMonth:
        return d.year == now.year && d.month == now.month;
      case _RevenueRange.all:
        return true;
    }
  }
}

/// Trang Staff — Doanh thu (spec 2026-07-06): tổng doanh thu, VNPay/COD đã
/// thu, COD chờ thu, phần shop nhận từ phí ship, và hoa hồng của nhân viên
/// hiện tại. Tính client-side trên `fetchAllOrders()` — chưa có endpoint
/// thống kê riêng. Tab-page: tự có app bar, không Scaffold.
class StaffRevenueScreen extends StatefulWidget {
  const StaffRevenueScreen({super.key});

  @override
  State<StaffRevenueScreen> createState() => _StaffRevenueScreenState();
}

class _StaffRevenueScreenState extends State<StaffRevenueScreen> {
  final _service = OrderService();
  final _auth = AuthService();

  List<OrderModel> _orders = [];
  bool _loading = true;
  _RevenueRange _range = _RevenueRange.today;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.fetchAllOrders();
      if (mounted) setState(() => _orders = list);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được dữ liệu doanh thu.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  List<OrderModel> get _visible {
    final now = DateTime.now();
    // BE trả orderDate dạng UTC (đuôi Z) → phải toLocal() trước khi so
    // theo ngày/tháng, không thì đơn đặt 0h–7h sáng VN rớt khỏi "Hôm nay".
    return _orders
        .where((o) =>
            _range.accepts(DateTime.tryParse(o.orderDate)?.toLocal(), now))
        .toList();
  }

  // ── Quy tắc tính doanh thu ("Mô hình tiền" trong spec) ───────────────────
  static bool _isCounted(OrderModel o) {
    if (o.status == OrderStatus.cancelled) return false;
    if (o.paymentStatus == 'Failed') return false;
    if (o.paymentMethod == 'VNPay') return o.paymentStatus == 'Paid';
    return o.status == OrderStatus.delivered;
  }

  static bool _isCodPending(OrderModel o) =>
      o.paymentMethod != 'VNPay' &&
      o.status != OrderStatus.delivered &&
      o.status != OrderStatus.cancelled;

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  @override
  Widget build(BuildContext context) {
    // Tab-page trong StaffShell: shell lo Scaffold + bottom nav.
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Doanh thu',
          actions: [
            TvIconButton(
              icon: TvIcon('log-out', color: AppColors.textAccent),
              tooltip: 'Đăng xuất',
              onPressed: _logout,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TvTabs(
            distribute: true,
            value: _range.name,
            tabs: [
              for (final r in _RevenueRange.values) TvTab(r.name, r.label),
            ],
            onChanged: (v) => setState(() =>
                _range = _RevenueRange.values.firstWhere((r) => r.name == v)),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      // Skeleton dashboard: bóng của chính bố cục thẻ tổng + lưới 2x2.
      return Skeletonizer(
        effect: ShimmerEffect(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter, 14, AppSpacing.gutter, 24),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _totalCard(12500000, 8),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('VNPay đã thu', 8000000)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('COD đã thu', 4500000)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _statCard('COD chờ thu', 1200000, warn: true)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Shop nhận từ ship', 90000)),
            ]),
            const SizedBox(height: 12),
            _myIncomeCard(60000, 4),
          ],
        ),
      );
    }
    final orders = _visible;
    final counted = orders.where(_isCounted).toList();
    final vnpaySum = counted
        .where((o) => o.paymentMethod == 'VNPay')
        .fold<double>(0, (s, o) => s + o.totalAmount);
    final codSum = counted
        .where((o) => o.paymentMethod != 'VNPay')
        .fold<double>(0, (s, o) => s + o.totalAmount);
    final codPending =
        orders.where(_isCodPending).fold<double>(0, (s, o) => s + o.totalAmount);
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).toList();
    final shipFeeSum = delivered.fold<double>(0, (s, o) => s + o.shippingFee);
    final shopShipShare =
        shipFeeSum * (1 - AppConfig.shipperCommissionRate);

    final myId = apiClient.userId;
    final myDelivered = myId == null
        ? const <OrderModel>[]
        : delivered.where((o) => o.staffId == myId).toList();
    final myShipFeeSum =
        myDelivered.fold<double>(0, (s, o) => s + o.shippingFee);
    final myCommission = myShipFeeSum * AppConfig.shipperCommissionRate;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: ListView(
        // Key theo bộ lọc thời gian → đổi tab là các thẻ vào lại theo nhịp.
        key: ValueKey(_range),
        padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter, 14, AppSpacing.gutter, 24),
        children: [
          _totalCard(vnpaySum + codSum, counted.length)
              .animate()
              .fadeIn(duration: AppEffects.durEnter)
              .moveY(
                  begin: AppEffects.entranceRise,
                  end: 0,
                  curve: AppEffects.easeStandard),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('VNPay đã thu', vnpaySum)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('COD đã thu', codSum)),
            ],
          )
              .animate(delay: AppEffects.staggerStep)
              .fadeIn(duration: AppEffects.durEnter)
              .moveY(
                  begin: AppEffects.entranceRise,
                  end: 0,
                  curve: AppEffects.easeStandard),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _statCard('COD chờ thu', codPending, warn: true)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Shop nhận từ ship', shopShipShare)),
            ],
          )
              .animate(delay: AppEffects.staggerStep * 2)
              .fadeIn(duration: AppEffects.durEnter)
              .moveY(
                  begin: AppEffects.entranceRise,
                  end: 0,
                  curve: AppEffects.easeStandard),
          const SizedBox(height: 12),
          _myIncomeCard(myCommission, myDelivered.length)
              .animate(delay: AppEffects.staggerStep * 3)
              .fadeIn(duration: AppEffects.durEnter)
              .moveY(
                  begin: AppEffects.entranceRise,
                  end: 0,
                  curve: AppEffects.easeStandard),
          const SizedBox(height: 22),
          const TvSectionHeader(
              icon: TvIcon('bar-chart'), title: 'Đơn được tính'),
          const SizedBox(height: 12),
          if (counted.isEmpty)
            _empty()
          else
            for (final o in counted) ...[
              _orderRow(o),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _totalCard(double total, int count) {
    return TvCard(
      accent: true,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TỔNG DOANH THU', style: AppText.label(AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(formatVnd(total), style: AppText.price().copyWith(fontSize: 30)),
          const SizedBox(height: 6),
          Text('$count đơn được tính',
              style: AppText.xs(AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _statCard(String label, double value, {bool warn = false}) {
    return TvCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppText.label(AppColors.textSecondary).copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            formatVnd(value),
            style: AppText.price(warn ? AppColors.warning500 : AppColors.textAccent)
                .copyWith(fontSize: 17),
          ),
        ],
      ),
    );
  }

  Widget _myIncomeCard(double commission, int count) {
    final pct = (AppConfig.shipperCommissionRate * 100).round();
    return TvCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon('wallet', size: 18, color: AppColors.textAccent),
              const SizedBox(width: 8),
              Text('Thu nhập của tôi', style: AppText.h3().copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(formatVnd(commission), style: AppText.price().copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text('$count cuốc đã giao', style: AppText.xs(AppColors.textTertiary)),
          const SizedBox(height: 6),
          Text('$pct% phí ship mỗi cuốc',
              style: AppText.xs(AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _orderRow(OrderModel o) {
    final isVnpay = o.paymentMethod == 'VNPay';
    final time = formatRelativeFromIso(o.orderDate);
    return TvCard(
      padding: 12,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#${_shortId(o.id)}',
                        style:
                            AppText.mono(size: 12, color: AppColors.textTertiary)),
                    const SizedBox(width: 8),
                    TvBadge(
                      isVnpay ? 'VNPay' : 'COD',
                      variant:
                          isVnpay ? TvBadgeVariant.glass : TvBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  o.customerName.isEmpty ? 'Khách' : o.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong().copyWith(fontSize: 14),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(time, style: AppText.xs(AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(formatVnd(o.totalAmount),
              style: AppText.price().copyWith(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
            child: TvIcon('inbox', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
          child: Text('Chưa có doanh thu trong khoảng này',
              style: AppText.body(AppColors.textSecondary)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_stats.dart';
import '../../../data/services/admin_service.dart';
import '../../widgets/widgets.dart';
import 'admin_common.dart';
import 'admin_orders_line_chart.dart';
import 'admin_revenue_chart.dart';
import 'admin_status_donut.dart';

/// Khu Admin — Tổng quan: KPI (doanh thu / số đơn / khách mới / tồn thấp),
/// biểu đồ cột doanh thu theo ngày, đường số đơn theo ngày, donut trạng thái
/// đơn và tỉ trọng thanh toán. Số liệu lấy thẳng từ `GET /api/admin/stats` (BE
/// đã tính "counted revenue" đúng luật màn Doanh thu của Staff). Bộ lọc ngày
/// hybrid (chip nhanh + lịch chọn khoảng). Tab-page: tự có app bar.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _service = AdminService();

  AdminStats? _stats;
  bool _loading = true;
  late TvDateRange _range = TvDateRange.lastDays(30);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Gửi mốc local-00:00 → service tự đổi UTC; đúng ranh giới ngày VN.
      final stats = await _service.fetchStats(from: _range.from, to: _range.to);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được thống kê.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setRange(TvDateRange r) {
    if (r.stateKey == _range.stateKey) return;
    setState(() => _range = r);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Tổng quan',
          actions: AdminActions.appBar(context, extra: [
            TvIconButton(
              icon: TvIcon('refresh-cw', color: AppColors.textAccent),
              tooltip: 'Tải lại',
              onPressed: _load,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: TvDateFilter(value: _range, onChanged: _setRange),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return Skeletonizer(
        effect: ShimmerEffect(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
        ),
        child: _content(
          AdminStats(
            totalRevenue: 128000000,
            orderCount: 42,
            newCustomers: 12,
            lowStockCount: 3,
            shippingFeeTotal: 640000,
            statusCounts: const [
              StatusCount(status: 'Delivered', count: 28),
              StatusCount(status: 'Pending', count: 9),
              StatusCount(status: 'Cancelled', count: 5),
            ],
            paymentSplit: const [
              PaymentSplit(method: 'VNPay', count: 24, revenue: 80000000),
              PaymentSplit(method: 'COD', count: 18, revenue: 48000000),
            ],
            // Series giả để bộ khung biểu đồ cột/đường cũng nhấp nháy khi tải.
            revenueSeries: [
              for (var i = 6; i >= 0; i--)
                RevenuePoint(
                  date: DateTime.now().subtract(Duration(days: i)),
                  revenue: (i.isEven ? 30 : 14) * 1000000,
                  orders: i.isEven ? 5 : 2,
                ),
            ],
          ),
          animate: false,
        ),
      );
    }
    final stats = _stats;
    if (stats == null) {
      return _errorState();
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: _content(stats, animate: true),
    );
  }

  Widget _content(AdminStats stats, {required bool animate}) {
    Widget staggered(Widget child, int i) {
      if (!animate) return child;
      return child
          .animate(delay: AppEffects.staggerStep * i)
          .fadeIn(duration: AppEffects.durEnter, curve: AppEffects.easeStandard)
          .moveY(
              begin: AppEffects.entranceRise,
              end: 0,
              curve: AppEffects.easeStandard);
    }

    return ListView(
      key: ValueKey(_range.stateKey),
      padding:
          EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 28),
      children: [
        staggered(_revenueCard(stats), 0),
        const SizedBox(height: 12),
        staggered(
          Row(children: [
            Expanded(
                child: _kpiCard('Số đơn tính', '${stats.orderCount}', 'package')),
            const SizedBox(width: 10),
            Expanded(
                child: _kpiCard(
                    'Khách mới', '${stats.newCustomers}', 'users')),
          ]),
          1,
        ),
        const SizedBox(height: 10),
        staggered(
          Row(children: [
            Expanded(
                child: _kpiCard('Phí ship thu',
                    formatVnd(stats.shippingFeeTotal), 'truck')),
            const SizedBox(width: 10),
            Expanded(
                child: _kpiCard('Tồn thấp', '${stats.lowStockCount}',
                    'circle-alert',
                    warn: stats.lowStockCount > 0)),
          ]),
          2,
        ),
        // Biểu đồ CỘT — doanh thu theo ngày.
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
              icon: TvIcon('bar-chart'), title: 'Doanh thu theo ngày'),
          3,
        ),
        const SizedBox(height: 12),
        staggered(
          TvCard(child: AdminRevenueChart(points: stats.revenueSeries)),
          4,
        ),
        // Biểu đồ ĐƯỜNG — số đơn theo ngày.
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
              icon: TvIcon('activity'), title: 'Số đơn theo ngày'),
          5,
        ),
        const SizedBox(height: 12),
        staggered(
          TvCard(child: AdminOrdersLineChart(points: stats.revenueSeries)),
          6,
        ),
        // Biểu đồ TRÒN (donut) — tỉ trọng trạng thái đơn.
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
              icon: TvIcon('pie-chart'), title: 'Trạng thái đơn'),
          7,
        ),
        const SizedBox(height: 12),
        staggered(
          TvCard(child: AdminStatusDonut(data: stats.statusCounts)),
          8,
        ),
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
              icon: TvIcon('credit-card'), title: 'Thanh toán'),
          9,
        ),
        const SizedBox(height: 12),
        staggered(_paymentSplit(stats), 10),
      ],
    );
  }

  Widget _revenueCard(AdminStats stats) {
    return TvCard(
      accent: true,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DOANH THU (${_range.label})',
              style: AppText.label(AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(formatVnd(stats.totalRevenue),
              style: AppText.price().copyWith(fontSize: 30)),
          const SizedBox(height: 6),
          Text('${stats.orderCount} đơn được tính · gồm phí ship',
              style: AppText.xs(AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, String icon,
      {bool warn = false}) {
    return TvCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon(icon,
                  size: 15,
                  color:
                      warn ? AppColors.warning500 : AppColors.textAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(AppColors.textSecondary)
                        .copyWith(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.price(
                    warn ? AppColors.warning500 : AppColors.textAccent)
                .copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _paymentSplit(AdminStats stats) {
    if (stats.paymentSplit.isEmpty) {
      return TvCard(
        child: Text('Chưa có thanh toán trong khoảng này',
            style: AppText.sm(AppColors.textSecondary)),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < stats.paymentSplit.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _paymentCard(stats.paymentSplit[i])),
        ],
      ],
    );
  }

  Widget _paymentCard(PaymentSplit ps) {
    final isVnpay = ps.method == 'VNPay';
    return TvCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvBadge(isVnpay ? 'VNPay' : 'COD',
              variant: isVnpay ? TvBadgeVariant.glass : TvBadgeVariant.neutral),
          const SizedBox(height: 8),
          Text(formatVnd(ps.revenue),
              style: AppText.price().copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text('${ps.count} đơn', style: AppText.xs(AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _errorState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
            child:
                TvIcon('circle-alert', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
            child: Text('Không tải được thống kê',
                style: AppText.body(AppColors.textSecondary))),
        const SizedBox(height: 16),
        Center(
          child: TvButton(
            label: 'Thử lại',
            variant: TvButtonVariant.secondary,
            size: TvButtonSize.md,
            onPressed: _load,
          ),
        ),
      ],
    );
  }
}

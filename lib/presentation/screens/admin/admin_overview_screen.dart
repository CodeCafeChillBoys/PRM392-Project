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
import 'admin_revenue_chart.dart';

/// Khoảng thời gian thống kê — quy ra (from, to) gửi BE (UTC).
enum _StatRange {
  last7(7, '7 ngày'),
  last30(30, '30 ngày'),
  last90(90, '90 ngày');

  const _StatRange(this.days, this.label);
  final int days;
  final String label;
}

/// Khu Admin — Tổng quan: KPI (doanh thu / số đơn / khách mới / tồn thấp),
/// biểu đồ doanh thu theo ngày, phân rã trạng thái đơn và tỉ trọng thanh toán.
/// Số liệu lấy thẳng từ `GET /api/admin/stats` (BE đã tính "counted revenue"
/// đúng luật màn Doanh thu của Staff). Tab-page: tự có app bar.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _service = AdminService();

  AdminStats? _stats;
  bool _loading = true;
  _StatRange _range = _StatRange.last30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final stats = await _service.fetchStats(
        from: now.subtract(Duration(days: _range.days)),
        to: now,
      );
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được thống kê.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setRange(_StatRange r) {
    if (r == _range) return;
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
          actions: AdminActions.appBar(
            context,
            extra: [
              TvIconButton(
                icon: TvIcon('refresh-cw', color: AppColors.textAccent),
                tooltip: 'Tải lại',
                onPressed: _load,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TvTabs(
            distribute: true,
            value: _range.name,
            tabs: [for (final r in _StatRange.values) TvTab(r.name, r.label)],
            onChanged: (v) =>
                _setRange(_StatRange.values.firstWhere((r) => r.name == v)),
          ),
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
          const AdminStats(
            totalRevenue: 128000000,
            orderCount: 42,
            newCustomers: 12,
            lowStockCount: 3,
            shippingFeeTotal: 640000,
            statusCounts: [
              StatusCount(status: 'Delivered', count: 28),
              StatusCount(status: 'Pending', count: 9),
              StatusCount(status: 'Cancelled', count: 5),
            ],
            paymentSplit: [
              PaymentSplit(method: 'VNPay', count: 24, revenue: 80000000),
              PaymentSplit(method: 'COD', count: 18, revenue: 48000000),
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
            curve: AppEffects.easeStandard,
          );
    }

    return ListView(
      key: ValueKey(_range),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        14,
        AppSpacing.gutter,
        28,
      ),
      children: [
        staggered(_revenueCard(stats), 0),
        const SizedBox(height: 12),
        staggered(
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Số đơn tính',
                  '${stats.orderCount}',
                  'package',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard('Khách mới', '${stats.newCustomers}', 'users'),
              ),
            ],
          ),
          1,
        ),
        const SizedBox(height: 10),
        staggered(
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Phí ship thu',
                  formatVnd(stats.shippingFeeTotal),
                  'truck',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kpiCard(
                  'Tồn thấp',
                  '${stats.lowStockCount}',
                  'circle-alert',
                  warn: stats.lowStockCount > 0,
                ),
              ),
            ],
          ),
          2,
        ),
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
            icon: TvIcon('trending-up'),
            title: 'Doanh thu theo ngày',
          ),
          3,
        ),
        const SizedBox(height: 12),
        staggered(
          TvCard(child: AdminRevenueChart(points: stats.revenueSeries)),
          4,
        ),
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
            icon: TvIcon('package'),
            title: 'Trạng thái đơn',
          ),
          5,
        ),
        const SizedBox(height: 12),
        staggered(_statusBreakdown(stats), 6),
        const SizedBox(height: 22),
        staggered(
          const TvSectionHeader(
            icon: TvIcon('credit-card'),
            title: 'Thanh toán',
          ),
          7,
        ),
        const SizedBox(height: 12),
        staggered(_paymentSplit(stats), 8),
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
          Text(
            'DOANH THU (${_range.label})',
            style: AppText.label(AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            formatVnd(stats.totalRevenue),
            style: AppText.price().copyWith(fontSize: 30),
          ),
          const SizedBox(height: 6),
          Text(
            '${stats.orderCount} đơn được tính · gồm phí ship',
            style: AppText.xs(AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    String icon, {
    bool warn = false,
  }) {
    return TvCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon(
                icon,
                size: 15,
                color: warn ? AppColors.warning500 : AppColors.textAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    AppColors.textSecondary,
                  ).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.price(
              warn ? AppColors.warning500 : AppColors.textAccent,
            ).copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _statusBreakdown(AdminStats stats) {
    final total = stats.statusTotal;
    if (stats.statusCounts.isEmpty || total == 0) {
      return TvCard(
        child: Text(
          'Chưa có đơn trong khoảng này',
          style: AppText.sm(AppColors.textSecondary),
        ),
      );
    }
    // Sắp xếp giảm dần theo số lượng để trạng thái phổ biến lên đầu.
    final sorted = [...stats.statusCounts]
      ..sort((a, b) => b.count.compareTo(a.count));
    return TvCard(
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _statusRow(sorted[i], total),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(StatusCount sc, int total) {
    final ratio = total == 0 ? 0.0 : sc.count / total;
    final pct = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OrderStatusBadge(sc.status),
            const Spacer(),
            Text(
              '${sc.count} đơn · $pct%',
              style: AppText.xs(AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio == 0 ? null : ratio,
            minHeight: 6,
            backgroundColor: AppColors.bgOverlay,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }

  Widget _paymentSplit(AdminStats stats) {
    if (stats.paymentSplit.isEmpty) {
      return TvCard(
        child: Text(
          'Chưa có thanh toán trong khoảng này',
          style: AppText.sm(AppColors.textSecondary),
        ),
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
          TvBadge(
            isVnpay ? 'VNPay' : 'COD',
            variant: isVnpay ? TvBadgeVariant.glass : TvBadgeVariant.neutral,
          ),
          const SizedBox(height: 8),
          Text(
            formatVnd(ps.revenue),
            style: AppText.price().copyWith(fontSize: 16),
          ),
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
          child: TvIcon(
            'circle-alert',
            size: 44,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Không tải được thống kê',
            style: AppText.body(AppColors.textSecondary),
          ),
        ),
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

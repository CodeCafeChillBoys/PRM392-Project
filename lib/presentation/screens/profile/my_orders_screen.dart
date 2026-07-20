import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/order_service.dart';
import '../../state/app_nav.dart';
import '../../widgets/widgets.dart';
import 'order_detail_screen.dart';
import 'order_tracking_screen.dart';
import 'refund_request_sheet.dart';

/// "Đơn hàng của tôi" — khách xem đơn; đơn đang giao (`Shipped`) có nút
/// "Theo dõi đơn" mở bản đồ theo dõi shipper realtime. Vào từ tab Hồ sơ.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _service = OrderService();
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = apiClient.userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _service.fetchUserOrders(userId);
      list.sort((a, b) => b.orderDate.compareTo(a.orderDate)); // mới nhất trước
      if (mounted) setState(() => _orders = list);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được đơn hàng của bạn.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _track(OrderModel o) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o)));
  }

  /// Khách xin hoàn tiền cho đơn đã giao (trong 1 ngày) → nhập lý do + ảnh →
  /// gửi lên BE, tiền hoàn về ví sau khi staff duyệt.
  Future<void> _requestRefund(OrderModel o) async {
    final req = await showRefundRequestSheet(context);
    if (req == null || !mounted) return;
    try {
      await _service.requestRefund(o.id, req.reason, imagePath: req.imagePath);
      if (!mounted) return;
      TvToast.show(context, 'Đã gửi yêu cầu hoàn tiền, đang chờ duyệt.');
      _load();
    } catch (e) {
      if (mounted) {
        TvToast.show(
          context,
          e is ApiException ? e.message : 'Gửi yêu cầu hoàn tiền thất bại.',
        );
      }
    }
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Đơn hàng của tôi',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  /// Đơn "ma" cho skeleton — layout thật, dữ liệu giả.
  static final _ghost = OrderModel(
    id: 'ghost0000',
    customerName: 'Đang tải',
    shippingAddress: 'Đang tải địa chỉ giao hàng của đơn',
    totalAmount: 12000000,
    status: 'Pending',
    paymentMethod: 'COD',
    paymentStatus: 'Pending',
    orderDate: DateTime.now().toIso8601String(),
    shippingFee: 15000,
    staffId: '',
  );

  Widget _body() {
    if (apiClient.userId == null) {
      return _centerText('Bạn cần đăng nhập để xem đơn hàng.');
    }
    if (_loading) {
      // Skeleton thay spinner: bóng của chính layout card đơn hàng.
      return Skeletonizer(
        effect: ShimmerEffect(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
        ),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            14,
            AppSpacing.gutter,
            24,
          ),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => _orderCard(_ghost),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: _orders.isEmpty
          ? _emptyList()
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                14,
                AppSpacing.gutter,
                24,
              ),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _orderCard(_orders[i])
                  .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
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
    );
  }

  /// Empty state có lối thoát — dẫn khách về Khám phá thay vì ngõ cụt.
  Widget _emptyList() => ListView(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    children:
        [
              const SizedBox(height: 100),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentSoft,
                    border: Border.all(color: AppColors.accentSoftLine),
                  ),
                  child: TvIcon(
                    'package',
                    size: 34,
                    color: AppColors.textAccent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Chưa có đơn hàng nào',
                  style: AppText.h2().copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Đơn bạn đặt sẽ hiện ở đây để theo dõi.',
                  textAlign: TextAlign.center,
                  style: AppText.sm(AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 200,
                  child: TvButton(
                    label: 'Mua sắm ngay',
                    variant: TvButtonVariant.gradient,
                    onPressed: () {
                      context.read<AppNav>().goExplore();
                      Navigator.of(context).pop();
                    },
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

  Widget _centerText(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: AppText.body(AppColors.textSecondary),
      ),
    ),
  );

  void _openDetail(OrderModel o) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)));

  Widget _orderCard(OrderModel o) {
    final time = formatRelativeFromIso(o.orderDate);
    return PressableScale(
      onTap: () => _openDetail(o),
      scale: 0.99,
      child: TvCard(
        padding: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${_shortId(o.id)}',
                  style: AppText.mono(size: 12, color: AppColors.textTertiary),
                ),
                OrderStatusBadge(o.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              o.shippingAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                AppColors.textSecondary,
              ).copyWith(fontSize: 13),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(time, style: AppText.xs(AppColors.textTertiary)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${o.paymentMethod} · ${o.paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa TT'}',
                  style: AppText.xs(AppColors.textTertiary),
                ),
                Text(
                  formatVnd(o.totalAmount),
                  style: AppText.price().copyWith(fontSize: 15),
                ),
              ],
            ),
            if (OrderFlow.isDelivering(o.status)) ...[
              const SizedBox(height: 12),
              TvButton(
                label: 'Theo dõi đơn',
                size: TvButtonSize.md,
                fullWidth: true,
                leadingIcon: const TvIcon('map-pin', size: 18),
                onPressed: () => _track(o),
              ),
            ],
            ..._refundSection(o),
          ],
        ),
      ),
    );
  }

  /// Khối hoàn tiền theo trạng thái đơn: nút xin hoàn (đủ điều kiện) hoặc chip
  /// trạng thái đang chờ / đã hoàn.
  List<Widget> _refundSection(OrderModel o) {
    switch (o.refundState) {
      case RefundState.requested:
        return [
          const SizedBox(height: 12),
          _refundChip(
            'clock',
            'Đang chờ duyệt hoàn tiền',
            AppColors.warning500,
          ),
        ];
      case RefundState.refunded:
        return [
          const SizedBox(height: 12),
          _refundChip(
            'check-circle',
            'Đã hoàn tiền vào ví',
            AppColors.success500,
          ),
        ];
      case RefundState.none:
        if (!o.canRequestRefund) return const [];
        return [
          const SizedBox(height: 12),
          TvButton(
            label: 'Yêu cầu hoàn tiền',
            variant: TvButtonVariant.secondary,
            size: TvButtonSize.md,
            fullWidth: true,
            leadingIcon: const TvIcon('rotate-ccw', size: 18),
            onPressed: () => _requestRefund(o),
          ),
        ];
    }
  }

  Widget _refundChip(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TvIcon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppText.xs(color).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

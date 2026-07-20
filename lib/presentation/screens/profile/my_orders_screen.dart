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
import 'order_tracking_screen.dart';
import 'refund_request_screen.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o)),
    );
  }

  Future<void> _requestRefund(OrderModel o) async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RefundRequestScreen(order: o)),
    );
    if (sent == true && mounted) {
      TvToast.show(context, 'Đã gửi yêu cầu hoàn tiền.');
      await _load();
    }
  }

  Future<void> _cancelOrder(OrderModel o) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CancelReasonSheet(orderShortId: _shortId(o.id)),
    );
    if (reason == null || !mounted) return;
    try {
      await _service.cancelOrder(o.id, reason);
      if (!mounted) return;
      TvToast.show(context, 'Đã huỷ đơn hàng.');
      await _load();
    } catch (_) {
      if (mounted) TvToast.show(context, 'Huỷ đơn thất bại. Thử lại sau.');
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
              AppSpacing.gutter, 14, AppSpacing.gutter, 24),
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
                  AppSpacing.gutter, 14, AppSpacing.gutter, 24),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _orderCard(_orders[i])
                  .animate(
                    delay: AppEffects.staggerStep * i.clamp(0, 6),
                  )
                  .fadeIn(
                      duration: AppEffects.durEnter,
                      curve: AppEffects.easeStandard)
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
        children: [
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
              child: TvIcon('package', size: 34, color: AppColors.textAccent),
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child: Text('Chưa có đơn hàng nào',
                  style: AppText.h2().copyWith(fontSize: 18))),
          const SizedBox(height: 6),
          Center(
            child: Text('Đơn bạn đặt sẽ hiện ở đây để theo dõi.',
                textAlign: TextAlign.center,
                style: AppText.sm(AppColors.textTertiary)),
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
                curve: AppEffects.easeStandard),
      );

  Widget _centerText(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(msg,
              textAlign: TextAlign.center,
              style: AppText.body(AppColors.textSecondary)),
        ),
      );

  Widget _orderCard(OrderModel o) {
    final time = formatRelativeFromIso(o.orderDate);
    return TvCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${_shortId(o.id)}',
                  style: AppText.mono(size: 12, color: AppColors.textTertiary)),
              OrderStatusBadge(o.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(o.shippingAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppText.body(AppColors.textSecondary).copyWith(fontSize: 13)),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(time, style: AppText.xs(AppColors.textTertiary)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${o.paymentMethod} · ${paymentStatusLabel(o.paymentStatus)}',
                  style: AppText.xs(AppColors.textTertiary)),
              Text(formatVnd(o.totalAmount),
                  style: AppText.price().copyWith(fontSize: 15)),
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
          if (OrderFlow.customerCanCancel(o.status)) ...[
            const SizedBox(height: 12),
            TvButton(
              label: 'Huỷ đơn',
              variant: TvButtonVariant.ghost,
              size: TvButtonSize.md,
              fullWidth: true,
              leadingIcon:
                  TvIcon('x-circle', size: 18, color: AppColors.danger500),
              onPressed: () => _cancelOrder(o),
            ),
          ],
          ..._refundSection(o),
          if (o.status == OrderStatus.cancelled &&
              o.cancelReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lý do huỷ: ${o.cancelReason}',
                style: AppText.xs(AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }

  /// Khối hoàn tiền: nút yêu cầu (đơn đã giao + đã TT) hoặc chip trạng thái
  /// (chờ duyệt / đã hoàn) cho các đơn đang trong luồng refund.
  List<Widget> _refundSection(OrderModel o) {
    // Đã hoàn toàn bộ.
    if (o.paymentStatus == 'Refunded') {
      return const [
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TvBadge('Đã hoàn tiền', variant: TvBadgeVariant.success),
        ),
      ];
    }
    // Chờ staff duyệt.
    if (o.paymentStatus == 'RefundRequested') {
      return const [
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TvBadge('Chờ duyệt hoàn', variant: TvBadgeVariant.warning),
        ),
      ];
    }
    // Đã hoàn 1 phần (đơn về Paid nhưng đã có tiền hoàn) → không cho hoàn tiếp.
    if (o.refundedAmount > 0) {
      return [
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TvBadge('Đã hoàn 1 phần: ${formatVnd(o.refundedAmount)}',
              variant: TvBadgeVariant.success),
        ),
      ];
    }
    // Còn hạn → cho yêu cầu hoàn.
    if (o.status == OrderStatus.delivered &&
        o.paymentStatus == 'Paid' &&
        o.refundWindowOpen) {
      return [
        const SizedBox(height: 12),
        TvButton(
          label: 'Yêu cầu hoàn tiền',
          variant: TvButtonVariant.ghost,
          size: TvButtonSize.md,
          fullWidth: true,
          leadingIcon: const TvIcon('refund', size: 18),
          onPressed: () => _requestRefund(o),
        ),
      ];
    }
    return const [];
  }
}

/// Bottom sheet chọn lý do huỷ đơn — preset + ghi chú tuỳ chọn. Trả về chuỗi
/// lý do qua [Navigator.pop] (null nếu khách đóng mà không xác nhận).
class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet({required this.orderShortId});

  final String orderShortId;

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  static const _presets = [
    'Đổi ý, không muốn mua nữa',
    'Đặt nhầm sản phẩm / số lượng',
    'Muốn thay đổi địa chỉ / thông tin',
    'Tìm được nơi khác giá tốt hơn',
    'Lý do khác',
  ];

  int _selected = 0;
  final _noteCtrl = TextEditingController();

  bool get _isOther => _selected == _presets.length - 1;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _noteCtrl.text.trim();
    if (_isOther && note.isEmpty) {
      TvToast.show(context, 'Vui lòng nhập lý do huỷ.');
      return;
    }
    final preset = _presets[_selected];
    final reason =
        _isOther ? note : (note.isEmpty ? preset : '$preset — $note');
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Huỷ đơn #${widget.orderShortId}', style: AppText.h3()),
              const SizedBox(height: 4),
              Text(
                'Chọn lý do huỷ — nếu đơn trả bằng Ví, tiền sẽ hoàn về ví của bạn.',
                style: AppText.xs(AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _presets.length; i++) ...[
                _reasonRow(i),
                if (i < _presets.length - 1) const SizedBox(height: 8),
              ],
              if (_isOther) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  style: AppText.body(),
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do huỷ...',
                    hintStyle: AppText.sm(AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TvButton(
                label: 'Xác nhận huỷ đơn',
                variant: TvButtonVariant.gradient,
                size: TvButtonSize.lg,
                fullWidth: true,
                leadingIcon: const TvIcon('x-circle', size: 18),
                onPressed: _confirm,
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Không huỷ nữa',
                      style: AppText.sm(AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasonRow(int i) {
    final selected = i == _selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentSoftLine : AppColors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.textAccent : AppColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _presets[i],
                style: AppText.sm(
                  selected ? AppColors.textPrimary : AppColors.textSecondary,
                ).copyWith(fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

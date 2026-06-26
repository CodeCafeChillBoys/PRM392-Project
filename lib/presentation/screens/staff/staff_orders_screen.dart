import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';

/// Trang Staff: quản lý đơn theo 4 tab (Tất cả / Chờ XN / Đang giao / Xong).
/// Staff KHÔNG tự đánh dấu "Đã giao" — đơn `Shipped` phải đợi khách bấm
/// "Đã nhận hàng" (xem [OrderFlow]).
class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  final _service = OrderService();
  final _auth = AuthService();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _busyId;
  StaffTab _tab = StaffTab.all;

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
      if (mounted) TvToast.show(context, 'Không tải được danh sách đơn.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance(OrderModel o, String status) async {
    setState(() => _busyId = o.id);
    try {
      await _service.updateOrderStatus(o.id, status);
      await _load();
    } catch (_) {
      if (mounted) TvToast.show(context, 'Đổi trạng thái thất bại.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _cancel(OrderModel o) async {
    final ok = await showTvConfirm(
      context,
      title: 'Huỷ đơn hàng?',
      message: 'Đơn #${_shortId(o.id)} sẽ chuyển sang "Đã huỷ". '
          'Hành động này không thể hoàn tác.',
      confirmLabel: 'Huỷ đơn',
    );
    if (ok == true) await _advance(o, OrderStatus.cancelled);
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  List<OrderModel> get _visible =>
      _orders.where((o) => _tab.accepts(o.status)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Quản lý đơn hàng',
            actions: [
              TvIconButton(
                icon: const TvIcon('log-out', color: AppColors.textAccent),
                tooltip: 'Đăng xuất',
                onPressed: _logout,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TvTabs(
              distribute: true,
              value: _tab.name,
              tabs: [for (final t in StaffTab.values) TvTab(t.name, t.label)],
              onChanged: (v) => setState(
                  () => _tab = StaffTab.values.firstWhere((t) => t.name == v)),
            ),
          ),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.textAccent));
    }
    final items = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: items.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _orderCard(items[i]),
            ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Center(
            child: TvIcon('inbox', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
          child: Text('Không có đơn ở trạng thái này',
              style: AppText.body(AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _orderCard(OrderModel o) {
    final action = OrderFlow.staffPrimaryAction(o.status);
    final canCancel = OrderFlow.staffCanCancel(o.status);
    final awaiting = OrderFlow.isAwaitingCustomer(o.status);
    final busy = _busyId == o.id;
    final meta = _metaLine(o);

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
          Text(o.customerName.isEmpty ? 'Khách' : o.customerName,
              style: AppText.h3().copyWith(fontSize: 15)),
          if (meta != null) ...[
            const SizedBox(height: 2),
            Text(meta, style: AppText.xs(AppColors.textTertiary)),
          ],
          const SizedBox(height: 6),
          Text(o.shippingAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppText.body(AppColors.textSecondary).copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${o.paymentMethod} · ${o.paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa TT'}',
                  style: AppText.xs(AppColors.textTertiary)),
              Text(formatVnd(o.totalAmount),
                  style: AppText.price().copyWith(fontSize: 15)),
            ],
          ),
          if (action != null || canCancel || awaiting) ...[
            const SizedBox(height: 12),
            _actions(o, action, canCancel, awaiting, busy),
          ],
        ],
      ),
    );
  }

  /// "2 sản phẩm · 5 phút trước" — ẩn phần sản phẩm nếu BE không trả itemCount,
  /// ẩn phần thời gian nếu orderDate không parse được.
  String? _metaLine(OrderModel o) {
    final time = formatRelativeFromIso(o.orderDate);
    final parts = <String>[
      if (o.itemCount != null) '${o.itemCount} sản phẩm',
      if (time.isNotEmpty) time,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _actions(OrderModel o, StaffAction? action, bool canCancel,
      bool awaiting, bool busy) {
    if (awaiting) {
      // Đang giao: chờ khách xác nhận đã nhận hàng — staff không thao tác.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TvIcon('clock', size: 15, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text('Chờ khách xác nhận đã nhận hàng',
                style: AppText.sm(AppColors.textSecondary)),
          ],
        ),
      );
    }
    return Row(
      children: [
        if (action != null)
          Expanded(
            child: TvButton(
              label: action.label,
              size: TvButtonSize.md,
              fullWidth: true,
              loading: busy,
              onPressed: () => _advance(o, action.nextStatus),
            ),
          ),
        if (action != null && canCancel) const SizedBox(width: 10),
        if (canCancel)
          TvButton(
            label: 'Huỷ',
            variant: TvButtonVariant.ghost,
            size: TvButtonSize.md,
            onPressed: busy ? null : () => _cancel(o),
          ),
      ],
    );
  }
}

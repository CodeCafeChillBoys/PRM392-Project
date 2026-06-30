import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import 'order_tracking_screen.dart';

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

  Widget _body() {
    if (apiClient.userId == null) {
      return _centerText('Bạn cần đăng nhập để xem đơn hàng.');
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.textAccent));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: _orders.isEmpty
          ? _emptyList()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _orderCard(_orders[i]),
            ),
    );
  }

  Widget _emptyList() => ListView(
        children: [
          const SizedBox(height: 120),
          const Center(
              child:
                  TvIcon('package', size: 44, color: AppColors.textTertiary)),
          const SizedBox(height: 12),
          Center(
              child: Text('Bạn chưa có đơn hàng nào',
                  style: AppText.body(AppColors.textSecondary))),
        ],
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
                  '${o.paymentMethod} · ${o.paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa TT'}',
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
        ],
      ),
    );
  }
}

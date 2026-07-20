import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import 'order_tracking_screen.dart';

/// Chi tiết 1 đơn hàng: timeline trạng thái, danh sách sản phẩm đã mua (tên/ảnh/
/// số lượng/đơn giá), hoá đơn (tiền hàng + phí ship + tổng), thanh toán, địa chỉ,
/// mốc "đã giao lúc", và trạng thái hoàn tiền. Chỉ ĐỌC + mở theo dõi khi đang giao.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  late OrderModel _order = widget.order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Đơn ở list có thể thiếu lines → nạp lại bản đầy đủ.
      final full = await _service.fetchOrderById(widget.order.id);
      if (mounted) setState(() => _order = full);
    } catch (_) {
      // Giữ dữ liệu từ list nếu tải lại lỗi.
    }
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  /// "HH:mm · dd/MM/yyyy" từ DateTime (không cần intl).
  String _fmtDateTime(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.hour)}:${p(d.minute)} · ${p(d.day)}/${p(d.month)}/${d.year}';
  }

  double get _subtotal =>
      _order.lines.fold(0.0, (s, l) => s + l.unitPrice * l.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Chi tiết đơn hàng',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.textAccent,
              backgroundColor: AppColors.bgSurface,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  14,
                  AppSpacing.gutter,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _headerCard(),
                  const SizedBox(height: 12),
                  if (_order.status.toLowerCase() == 'cancelled')
                    _cancelledBanner()
                  else
                    _timelineCard(),
                  const SizedBox(height: 12),
                  _productsCard(),
                  const SizedBox(height: 12),
                  _invoiceCard(),
                  const SizedBox(height: 12),
                  _paymentAddressCard(),
                  if (_order.refundState != RefundState.none) ...[
                    const SizedBox(height: 12),
                    _refundCard(),
                  ],
                  if (OrderFlow.isDelivering(_order.status)) ...[
                    const SizedBox(height: 16),
                    TvButton(
                      label: 'Theo dõi đơn',
                      size: TvButtonSize.lg,
                      fullWidth: true,
                      leadingIcon: const TvIcon('map-pin', size: 18),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(order: _order),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    final o = _order;
    final delivered = o.deliveredAt;
    return TvCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${_shortId(o.id)}',
                style: AppText.mono(size: 13, color: AppColors.textSecondary),
              ),
              OrderStatusBadge(o.status),
            ],
          ),
          if (o.orderDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Đặt lúc ${formatRelativeFromIso(o.orderDate)}',
              style: AppText.xs(AppColors.textTertiary),
            ),
          ],
          if (delivered != null && o.status.toLowerCase() == 'delivered') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                TvIcon('check-circle', size: 15, color: AppColors.success500),
                const SizedBox(width: 6),
                Text(
                  'Đã giao lúc ${_fmtDateTime(delivered)}',
                  style: AppText.sm(
                    AppColors.success500,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const _steps = [
    ('package', 'Đặt hàng', 'Đơn đã được ghi nhận'),
    ('check-circle', 'Xác nhận', 'Shop đã xác nhận đơn'),
    ('truck', 'Đang giao', 'Shipper đang giao đến bạn'),
    ('home', 'Đã giao', 'Giao hàng thành công'),
  ];

  int get _currentStep {
    switch (_order.status.toLowerCase()) {
      case 'confirmed':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0; // pending / pendingpayment
    }
  }

  Widget _timelineCard() {
    final cur = _currentStep;
    return TvCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _steps.length; i++)
            _timelineRow(i, cur, isLast: i == _steps.length - 1),
        ],
      ),
    );
  }

  Widget _timelineRow(int i, int cur, {required bool isLast}) {
    final done = i <= cur;
    final active = i == cur;
    final color = done ? AppColors.textAccent : AppColors.textTertiary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.accentSoft : AppColors.bgElevated,
                  border: Border.all(
                    color: done
                        ? AppColors.accentSoftLine
                        : AppColors.borderDefault,
                  ),
                ),
                child: TvIcon(_steps[i].$1, size: 15, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: i < cur
                        ? AppColors.accentSoftLine
                        : AppColors.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _steps[i].$2,
                    style: AppText.body().copyWith(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: done
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(_steps[i].$3, style: AppText.xs(AppColors.textTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelledBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.dangerLine),
      ),
      child: Row(
        children: [
          TvIcon('x-circle', size: 18, color: AppColors.danger500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đơn hàng đã bị huỷ.',
              style: AppText.sm(
                AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsCard() {
    final lines = _order.lines;
    return TvCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSectionHeader(
            icon: TvIcon('shopping-bag', color: AppColors.textAccent),
            title: 'Sản phẩm${lines.isNotEmpty ? ' (${lines.length})' : ''}',
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            Text(
              'Không có chi tiết sản phẩm cho đơn này.',
              style: AppText.sm(AppColors.textTertiary),
            )
          else
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.borderSubtle),
                ),
              _lineRow(lines[i]),
            ],
        ],
      ),
    );
  }

  Widget _lineRow(OrderLine l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: SizedBox(
            width: 56,
            height: 56,
            child: ColoredBox(
              color: AppColors.ink900,
              child: ProductImage(url: l.imageUrl),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (l.brand.isNotEmpty)
                Text(
                  l.brand.toUpperCase(),
                  style: AppText.xs(AppColors.textTertiary),
                ),
              Text(
                l.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body().copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatVnd(l.unitPrice)} × ${l.quantity}',
                style: AppText.xs(AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatVnd(l.unitPrice * l.quantity),
          style: AppText.price().copyWith(fontSize: 14),
        ),
      ],
    );
  }

  Widget _invoiceCard() {
    final hasLines = _order.lines.isNotEmpty;
    return TvCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TvSectionHeader(title: 'Hoá đơn'),
          const SizedBox(height: 12),
          if (hasLines)
            TvSummaryRow(label: 'Tiền hàng', value: formatVnd(_subtotal)),
          TvSummaryRow(
            label: 'Phí vận chuyển',
            value: _order.shippingFee > 0
                ? formatVnd(_order.shippingFee)
                : 'Miễn phí',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          TvSummaryRow(
            label: 'Tổng thanh toán',
            value: formatVnd(_order.totalAmount),
            emphasis: true,
          ),
        ],
      ),
    );
  }

  Widget _paymentAddressCard() {
    final o = _order;
    final paid = o.paymentStatus.toLowerCase() == 'paid';
    return TvCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            'credit-card',
            'Thanh toán',
            '${o.paymentMethod} · ${paid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
          ),
          const SizedBox(height: 14),
          _infoRow('map-pin', 'Giao đến', o.shippingAddress),
        ],
      ),
    );
  }

  Widget _infoRow(String icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvIcon(icon, size: 18, color: AppColors.textAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.xs(AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: AppText.sm(AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _refundCard() {
    final requested = _order.refundState == RefundState.requested;
    final color = requested ? AppColors.warning500 : AppColors.success500;
    final label = requested
        ? 'Đang chờ duyệt hoàn tiền'
        : 'Đã hoàn tiền vào ví';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon(
                requested ? 'clock' : 'check-circle',
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.sm(color).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if ((_order.refundReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do: ${_order.refundReason}',
              style: AppText.sm(AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

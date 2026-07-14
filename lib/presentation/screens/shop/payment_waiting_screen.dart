import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/order_service.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';

enum _PayState { waiting, paid, failed }

/// Sau khi mở cổng VNPay (trình duyệt ngoài): poll trạng thái đơn
/// (GET /api/Orders/{id}) mỗi 3s đến khi paymentStatus = Paid → hiện màn
/// thành công ngay trong app.
class PaymentWaitingScreen extends StatefulWidget {
  const PaymentWaitingScreen({
    super.key,
    required this.orderId,
    required this.gatewayUrl,
  });

  final String orderId;
  final String gatewayUrl;

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  final _orderService = OrderService();
  Timer? _timer;
  bool _checking = false;
  _PayState _state = _PayState.waiting;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _openGateway();
    _timer = Timer.periodic(
        const Duration(seconds: 3), (_) => _poll(isAuto: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openGateway() async {
    try {
      await launchUrl(Uri.parse(widget.gatewayUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {/* đơn đã tạo; lỗi mở cổng thì user bấm "Mở lại cổng" */}
  }

  Future<void> _poll({bool isAuto = false}) async {
    if (_checking || _state != _PayState.waiting) return;
    _checking = true;
    _ticks++;
    try {
      final status = await _orderService.fetchPaymentStatus(widget.orderId);
      if (!mounted) return;
      if (status == 'Paid') {
        _timer?.cancel();
        context.read<CartController>().refresh();
        setState(() => _state = _PayState.paid);
      } else if (status == 'Failed' || status == 'Cancelled') {
        _timer?.cancel();
        setState(() => _state = _PayState.failed);
      } else if (!isAuto) {
        TvToast.show(context,
            'Đơn vẫn đang chờ thanh toán. Hoàn tất trên VNPay rồi bấm kiểm tra lại nhé.');
      }
    } catch (_) {
      if (!isAuto && mounted) TvToast.show(context, 'Lỗi kiểm tra trạng thái.');
    } finally {
      _checking = false;
      if (_ticks >= 40) _timer?.cancel();
    }
  }

  void _goHome() {
    context.read<AppNav>().goExplore();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Thanh toán VNPay',
            onBack: _goHome,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_state == _PayState.paid) {
      return _result(
        icon: 'check-circle',
        color: AppColors.success500,
        title: 'Thanh toán thành công!',
        subtitle: 'Đơn hàng của bạn đã được xác nhận.',
      );
    }
    if (_state == _PayState.failed) {
      return _result(
        icon: 'x-circle',
        color: AppColors.danger500,
        title: 'Thanh toán chưa hoàn tất',
        subtitle: 'Giao dịch bị huỷ hoặc thất bại. Bạn có thể thử lại.',
      );
    }
    return _waiting();
  }

  Widget _waiting() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(color: AppColors.textAccent),
                ),
                const SizedBox(height: 24),
                Text('Đang chờ thanh toán VNPay',
                    style: AppText.h2(), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Hoàn tất thanh toán trên cổng VNPay, rồi quay lại app — màn này sẽ tự cập nhật.',
                    textAlign: TextAlign.center,
                    style: AppText.body(AppColors.textSecondary)
                        .copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        TvButton(
          label: 'Tôi đã thanh toán xong',
          size: TvButtonSize.lg,
          fullWidth: true,
          leadingIcon: const TvIcon('check', size: 18),
          onPressed: () => _poll(isAuto: false),
        ),
        const SizedBox(height: 12),
        TvButton(
          label: 'Mở lại cổng VNPay',
          variant: TvButtonVariant.ghost,
          size: TvButtonSize.lg,
          fullWidth: true,
          leadingIcon: const TvIcon('external-link', size: 18),
          onPressed: _openGateway,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _result({
    required String icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgElevated,
                    border: Border.all(color: color),
                  ),
                  child: TvIcon(icon, size: 42, color: color),
                ),
                const SizedBox(height: 24),
                Text(title, style: AppText.h1(), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(subtitle,
                      textAlign: TextAlign.center,
                      style: AppText.body(AppColors.textSecondary)
                          .copyWith(height: 1.55)),
                ),
              ],
            ),
          ),
        ),
        TvButton(
          label: 'Về trang chủ',
          size: TvButtonSize.lg,
          fullWidth: true,
          onPressed: _goHome,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

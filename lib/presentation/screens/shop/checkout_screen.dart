import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/mock_data.dart';
import '../../../data/services/order_service.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';

/// Checkout — address, shipping, payment (VNPay / CreditCard / BankTransfer /
/// COD), invoice summary (`POST /api/order/checkout`).
/// Mirrors `CheckoutScreen.jsx`.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.total});

  final double total;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const double _voucher = 120000;

  final _orderService = OrderService();
  final _address =
      TextEditingController(text: '221B Baker Street, Quận 1, TP. Hồ Chí Minh');
  String _shipping = 'fast';
  String _payment = 'VNPay';
  bool _confirming = false;

  double get _shipFee => MockData.shippingOptions
      .firstWhere((o) => o.value == _shipping)
      .fee;
  double get _grand => widget.total + _shipFee - _voucher;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final cart = context.read<CartController>();
    final appNav = context.read<AppNav>();
    final navigator = Navigator.of(context);
    try {
      final result = await _orderService.checkout(
        shippingAddress: _address.text,
        paymentMethod: _payment,
        total: _grand,
      );
      if (!mounted) return;
      if (result.needsGateway) {
        TvToast.show(context, 'Đang chuyển tới cổng VNPay…');
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        cart.clear();
        appNav.goExplore();
        navigator.pop();
        TvToast.show(
            navigator.context, 'Thanh toán VNPay thành công! Đơn đã xác nhận');
      } else {
        cart.clear();
        appNav.goExplore();
        navigator.pop();
        TvToast.show(
            navigator.context, 'Đặt hàng thành công! Đơn đang chờ xử lý');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _confirming = false);
        TvToast.show(context, 'Đặt hàng thất bại. Thử lại nhé.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVNPay = _payment == 'VNPay';
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Thanh toán',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _addressSection(),
                const SizedBox(height: 22),
                _shippingSection(),
                const SizedBox(height: 22),
                _paymentSection(),
                const SizedBox(height: 22),
                _invoiceCard(),
                const SizedBox(height: 22),
                TvButton(
                  label: isVNPay ? 'Thanh toán qua VNPay' : 'Xác nhận đặt hàng',
                  size: TvButtonSize.lg,
                  fullWidth: true,
                  loading: _confirming,
                  leadingIcon:
                      isVNPay ? const TvIcon('external-link', size: 18) : null,
                  onPressed: _confirm,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TvIcon('shield-check',
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text('Thanh toán an toàn với mã hóa AES-256',
                        style: AppText.xs(AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TvSectionHeader(
            icon: TvIcon('map-pin'), title: 'Địa chỉ nhận hàng'),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: 'Alex Nguyen',
                  style: AppText.body().copyWith(fontWeight: FontWeight.w700)),
              TextSpan(
                  text: ' · 090 123 4567',
                  style: AppText.body(AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TvInput(
          controller: _address,
          leading: const TvIcon('home'),
          hintText: 'Nhập địa chỉ giao hàng',
        ),
      ],
    );
  }

  Widget _shippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TvSectionHeader(
            icon: TvIcon('truck'), title: 'Phương thức vận chuyển'),
        const SizedBox(height: 12),
        for (final option in MockData.shippingOptions) ...[
          TvOptionRow(
            icon: TvIcon(option.iconName),
            title: option.title,
            subtitle: option.subtitle,
            trailing: formatVnd(option.fee),
            showRadio: false,
            selected: _shipping == option.value,
            onTap: () => setState(() => _shipping = option.value),
          ),
          if (option != MockData.shippingOptions.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _paymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TvSectionHeader(
            icon: TvIcon('credit-card'), title: 'Phương thức thanh toán'),
        const SizedBox(height: 12),
        for (final method in MockData.paymentMethods) ...[
          TvOptionRow(
            icon: TvIcon(method.iconName),
            title: method.title,
            subtitle: method.subtitle,
            selected: _payment == method.value,
            onTap: () => setState(() => _payment = method.value),
          ),
          if (method != MockData.paymentMethods.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _invoiceCard() {
    return TvCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TvSectionHeader(title: 'Tóm tắt hóa đơn'),
          const SizedBox(height: 12),
          TvSummaryRow(label: 'Tiền hàng', value: formatVnd(widget.total)),
          TvSummaryRow(label: 'Phí vận chuyển', value: formatVnd(_shipFee)),
          TvSummaryRow(
            label: 'Giảm giá voucher',
            value: '-${formatVnd(_voucher)}',
            tone: SummaryTone.danger,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          TvSummaryRow(
            label: 'Tổng thanh toán',
            value: formatVnd(_grand),
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

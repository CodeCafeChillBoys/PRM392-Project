import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/address_option.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/mock_data.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/shipping_service.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import 'payment_waiting_screen.dart';

/// Checkout — địa chỉ (dropdown Tỉnh/Huyện/Xã + GHN tính phí), thanh toán,
/// tóm tắt hóa đơn (`POST /api/order/checkout`).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.total});

  final double total;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderService = OrderService();
  final _shippingService = ShippingService();
  final _addressDetail = TextEditingController(); // số nhà, tên đường

  // Dropdown data + lựa chọn hiện tại.
  List<AddressOption> _provinces = [];
  List<AddressOption> _districts = [];
  List<AddressOption> _wards = [];
  AddressOption? _province;
  AddressOption? _district;
  AddressOption? _ward;

  int? _shipFee; // phí GHN (đ) — null khi chưa tính
  bool _loadingFee = false;

  String _payment = 'VNPay';
  bool _confirming = false;

  double get _grand => widget.total + (_shipFee ?? 0).toDouble();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _addressDetail.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final list = await _shippingService.fetchProvinces();
      if (mounted) setState(() => _provinces = list);
    } catch (_) {/* để dropdown trống nếu lỗi */}
  }

  // Chọn Tỉnh → tải Huyện, reset các cấp dưới + phí.
  Future<void> _onProvince(AddressOption? p) async {
    if (p == null) return;
    setState(() {
      _province = p;
      _district = null;
      _ward = null;
      _districts = [];
      _wards = [];
      _shipFee = null;
    });
    final list = await _shippingService.fetchDistricts(int.tryParse(p.id) ?? 0);
    if (mounted) setState(() => _districts = list);
  }

  // Chọn Huyện → tải Xã.
  Future<void> _onDistrict(AddressOption? d) async {
    if (d == null) return;
    setState(() {
      _district = d;
      _ward = null;
      _wards = [];
      _shipFee = null;
    });
    final list = await _shippingService.fetchWards(int.tryParse(d.id) ?? 0);
    if (mounted) setState(() => _wards = list);
  }

  // Chọn Xã → tính phí GHN.
  Future<void> _onWard(AddressOption? w) async {
    if (w == null) return;
    setState(() => _ward = w);
    await _calcFee();
  }

  Future<void> _calcFee() async {
    if (_district == null || _ward == null) return;
    setState(() => _loadingFee = true);
    try {
      final fee = await _shippingService.calcFee(
        toDistrictId: int.tryParse(_district!.id) ?? 0,
        toWardCode: _ward!.id,
      );
      if (mounted) setState(() => _shipFee = fee);
    } catch (_) {
      if (mounted) {
        setState(() => _shipFee = null);
        TvToast.show(context, 'Không tính được phí ship cho địa chỉ này.');
      }
    } finally {
      if (mounted) setState(() => _loadingFee = false);
    }
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    if (_province == null ||
        _district == null ||
        _ward == null ||
        _addressDetail.text.trim().isEmpty) {
      TvToast.show(context, 'Vui lòng chọn đủ địa chỉ nhận hàng.');
      return;
    }
    setState(() => _confirming = true);
    final cart = context.read<CartController>();
    final navigator = Navigator.of(context);

    // Ghép địa chỉ thành 1 chuỗi gửi BE (BE lưu shippingAddress dạng text).
    final shippingAddress =
        '${_addressDetail.text.trim()}, ${_ward!.name}, ${_district!.name}, ${_province!.name}';
    try {
      final result = await _orderService.checkout(
        shippingAddress: shippingAddress,
        paymentMethod: _payment,
        total: _grand,
      );
      if (!mounted) return;

      // BE đã xoá giỏ → đồng bộ lại.
      cart.refresh();

      if (result.needsGateway && result.gatewayUrl != null) {
        // Sang màn "Chờ thanh toán": tự mở cổng VNPay + poll trạng thái đơn.
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => PaymentWaitingScreen(
            orderId: result.orderId,
            gatewayUrl: result.gatewayUrl!,
          ),
        ));
      } else {
        // Thay thế màn hình Checkout bằng màn hình Kết quả thanh toán
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              success: true,
              orderId: result.orderId,
              totalAmount: _grand,
              paymentMethod: _payment,
            ),
          ),
        );
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
                _paymentSection(),
                const SizedBox(height: 22),
                _invoiceCard(),
                const SizedBox(height: 22),
                TvButton(
                  label: isVNPay ? 'Thanh toán qua VNPay' : 'Xác nhận đặt hàng',
                  size: TvButtonSize.lg,
                  fullWidth: true,
                  loading: _confirming,
                  leadingIcon: isVNPay
                      ? const TvIcon('external-link', size: 18)
                      : null,
                  onPressed: _confirm,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TvIcon(
                      'shield-check',
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Thanh toán an toàn với mã hóa AES-256',
                      style: AppText.xs(AppColors.textTertiary),
                    ),
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
          icon: TvIcon('map-pin'),
          title: 'Địa chỉ nhận hàng',
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: apiClient.userName ?? 'Bạn',
                  style: AppText.body().copyWith(fontWeight: FontWeight.w700)),
              if (apiClient.userEmail != null)
                TextSpan(
                    text: ' · ${apiClient.userEmail}',
                    style: AppText.body(AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _dropdown(
          hint: 'Tỉnh / Thành phố',
          value: _province,
          items: _provinces,
          onChanged: _onProvince,
        ),
        const SizedBox(height: 10),
        _dropdown(
          hint: 'Quận / Huyện',
          value: _district,
          items: _districts,
          onChanged: _onDistrict,
          enabled: _province != null,
        ),
        const SizedBox(height: 10),
        _dropdown(
          hint: 'Phường / Xã',
          value: _ward,
          items: _wards,
          onChanged: _onWard,
          enabled: _district != null,
        ),
        const SizedBox(height: 10),
        TvInput(
          controller: _addressDetail,
          leading: const TvIcon('home'),
          hintText: 'Số nhà, tên đường...',
        ),
      ],
    );
  }

  Widget _dropdown({
    required String hint,
    required AddressOption? value,
    required List<AddressOption> items,
    required ValueChanged<AddressOption?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AddressOption>(
          isExpanded: true,
          value: value,
          dropdownColor: AppColors.bgElevated,
          iconEnabledColor: AppColors.textSecondary,
          style: AppText.body(),
          hint: Text(hint, style: AppText.body(AppColors.textTertiary)),
          items: enabled
              ? items
                  .map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(o.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList()
              : const [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _paymentSection() {
    // Chỉ giữ phương thức call API thật: VNPay (cổng thật) + COD (trả khi nhận).
    final methods = MockData.paymentMethods
        .where((m) => m.value == 'VNPay' || m.value == 'COD')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TvSectionHeader(
          icon: TvIcon('credit-card'),
          title: 'Phương thức thanh toán',
        ),
        const SizedBox(height: 12),
        for (final method in methods) ...[
          TvOptionRow(
            icon: TvIcon(method.iconName),
            title: method.title,
            subtitle: method.subtitle,
            selected: _payment == method.value,
            onTap: () => setState(() => _payment = method.value),
          ),
          if (method != methods.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _invoiceCard() {
    final feeText = _loadingFee
        ? 'Đang tính...'
        : (_shipFee != null ? formatVnd(_shipFee!.toDouble()) : 'Chọn địa chỉ');
    return TvCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TvSectionHeader(title: 'Tóm tắt hóa đơn'),
          const SizedBox(height: 12),
          TvSummaryRow(label: 'Tiền hàng', value: formatVnd(widget.total)),
          TvSummaryRow(label: 'Phí vận chuyển (GHN)', value: feeText),
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

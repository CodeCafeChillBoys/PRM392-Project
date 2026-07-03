import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/goong_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/place_suggestion.dart';
import '../../../data/models/shipping_quote.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/goong_service.dart';
import '../../../data/services/mock_data.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/shipping_service.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import 'payment_result_screen.dart';
import 'payment_waiting_screen.dart';

/// Checkout — nhập địa chỉ (Goong autocomplete → toạ độ), tính phí ship theo
/// khoảng cách (`POST /api/shipping/calculate`), xem bản đồ Shop→Nhà, chọn
/// thanh toán rồi đặt hàng (`POST /api/order/checkout`).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.total});

  final double total;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderService = OrderService();
  final _shippingService = ShippingService();
  final _goong = GoongService();
  final _addressCtrl = TextEditingController();
  final _mapController = MapController();

  /// Toạ độ kho gửi — khớp BE `Goong:StoreLatitude/Longitude`.
  static const LatLng _store = LatLng(10.841122, 106.809935);

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;

  LatLng? _dest; // toạ độ nhà khách đã chọn
  String _selectedAddress = ''; // địa chỉ đã chọn (gửi BE + chặn search lại)
  ShippingQuote? _quote; // kết quả tính phí
  bool _loadingFee = false;

  String _payment = 'VNPay';
  bool _confirming = false;

  double get _grand => widget.total + (_quote?.shippingFee ?? 0);

  @override
  void dispose() {
    _debounce?.cancel();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Địa chỉ: gõ → gợi ý (debounce) ───────────────────────────────────────
  void _onAddressChanged(String v) {
    _debounce?.cancel();
    // Vừa chọn xong (text == địa chỉ đã chọn) → không search lại.
    if (v.trim() == _selectedAddress.trim()) return;
    // Người dùng sửa địa chỉ → toạ độ/phí cũ không còn đúng.
    if (_dest != null || _quote != null) {
      setState(() {
        _dest = null;
        _quote = null;
      });
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
  }

  Future<void> _search(String input) async {
    if (input.trim().length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await _goong.autocomplete(input);
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ── Chọn 1 gợi ý → lấy toạ độ → tính phí ship ────────────────────────────
  Future<void> _selectPlace(PlaceSuggestion p) async {
    FocusScope.of(context).unfocus();
    _selectedAddress = p.description;
    _addressCtrl.text = p.description;
    _addressCtrl.selection =
        TextSelection.collapsed(offset: p.description.length);
    setState(() {
      _suggestions = [];
      _dest = null;
      _quote = null;
      _loadingFee = true;
    });
    try {
      final latLng = await _goong.placeLatLng(p.placeId);
      if (latLng == null) throw Exception('no-coords');
      final quote = await _shippingService.calculate(
        destinationLat: latLng.latitude,
        destinationLng: latLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _dest = latLng;
        _quote = quote;
      });
      _fitMap(latLng, quote);
    } catch (_) {
      if (mounted) {
        setState(() {
          _dest = null;
          _quote = null;
        });
        TvToast.show(context, 'Không tính được phí cho địa chỉ này.');
      }
    } finally {
      if (mounted) setState(() => _loadingFee = false);
    }
  }

  // Canh bản đồ vừa khít kho + nhà + tuyến đường.
  void _fitMap(LatLng dest, ShippingQuote quote) {
    final pts = <LatLng>[_store, dest, ...quote.decodedRoute()];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: pts,
            padding: const EdgeInsets.all(36),
          ),
        );
      } catch (_) {/* map chưa gắn xong */}
    });
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    if (_dest == null || _quote == null || _selectedAddress.isEmpty) {
      TvToast.show(context, 'Vui lòng chọn địa chỉ nhận hàng để tính phí.');
      return;
    }
    setState(() => _confirming = true);
    final cart = context.read<CartController>();
    final navigator = Navigator.of(context);
    try {
      final result = await _orderService.checkout(
        shippingAddress: _selectedAddress,
        paymentMethod: _payment,
        total: _grand,
        destinationLat: _dest!.latitude,
        destinationLng: _dest!.longitude,
        shippingFee: _quote!.shippingFee,
      );
      if (!mounted) return;

      // BE đã xoá giỏ → đồng bộ lại.
      cart.refresh();

      if (result.needsGateway && result.gatewayUrl != null) {
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
        TvInput(
          controller: _addressCtrl,
          leading: const TvIcon('search'),
          hintText: 'Nhập địa chỉ nhận hàng...',
          onChanged: _onAddressChanged,
          trailing: _searching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textAccent))
              : null,
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          _suggestionList(),
        ],
        if (_loadingFee) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textAccent)),
              const SizedBox(width: 10),
              Text('Đang tính phí giao hàng...',
                  style: AppText.sm(AppColors.textSecondary)),
            ],
          ),
        ],
        if (_dest != null && _quote != null) ...[
          const SizedBox(height: 12),
          _mapPreview(),
          const SizedBox(height: 10),
          _routeInfo(),
        ],
      ],
    );
  }

  Widget _suggestionList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _suggestions.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.borderSubtle),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectPlace(_suggestions[i]),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const TvIcon('map-pin',
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _suggestions[i].description,
                        style: AppText.sm(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mapPreview() {
    final route = _quote?.decodedRoute() ?? const <LatLng>[];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 190,
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _store,
            initialZoom: 12,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: GoongConfig.osmTileUrl,
              userAgentPackageName: 'com.techstore.tech_void',
            ),
            if (route.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                      points: route, strokeWidth: 4, color: AppColors.accent),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                    point: _store,
                    width: 38,
                    height: 38,
                    child: _pin('truck', AppColors.textSecondary)),
                if (_dest != null)
                  Marker(
                      point: _dest!,
                      width: 38,
                      height: 38,
                      child: _pin('map-pin', AppColors.accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pin(String icon, Color color) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgBase,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: TvIcon(icon, size: 18, color: color),
      );

  Widget _routeInfo() {
    final q = _quote!;
    return Row(
      children: [
        _infoChip('truck', '${q.distanceKm.toStringAsFixed(1)} km'),
        const SizedBox(width: 10),
        _infoChip('clock', '~${q.durationMinutes.round()} phút'),
      ],
    );
  }

  Widget _infoChip(String icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TvIcon(icon, size: 14, color: AppColors.textAccent),
            const SizedBox(width: 6),
            Text(text, style: AppText.sm()),
          ],
        ),
      );

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
        : (_quote != null ? formatVnd(_quote!.shippingFee) : 'Chọn địa chỉ');
    return TvCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TvSectionHeader(title: 'Tóm tắt hóa đơn'),
          const SizedBox(height: 12),
          TvSummaryRow(label: 'Tiền hàng', value: formatVnd(widget.total)),
          TvSummaryRow(label: 'Phí vận chuyển', value: feeText),
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

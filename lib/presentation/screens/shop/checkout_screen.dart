import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/place_suggestion.dart';
import '../../../data/models/saved_address.dart';
import '../../../data/models/shipping_quote.dart';
import '../../../data/services/address_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/goong_service.dart';
import '../../../data/services/mock_data.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/shipping_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import '../wallet/wallet_screen.dart';
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

  /// Số dư ví (null = chưa tải xong / lỗi tải). Dùng để hiện & pre-check khi
  /// chọn "Trả bằng Ví".
  double? _walletBalance;

  double get _grand => widget.total + (_quote?.shippingFee ?? 0);

  bool get _walletSelected => _payment == 'Wallet';

  /// Đã biết số dư và số dư < tổng đơn → không cho trả bằng ví, gợi ý nạp thêm.
  bool get _walletInsufficient =>
      _walletSelected && _walletBalance != null && _walletBalance! < _grand;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final w = await walletService.fetchWallet();
      if (mounted) setState(() => _walletBalance = w.balance);
    } catch (_) {
      // Không tải được (chưa đăng nhập / mạng) → để null, vẫn cho chọn, BE chốt.
    }
  }

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
    _addressCtrl.selection = TextSelection.collapsed(
      offset: p.description.length,
    );
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
      } catch (_) {
        /* map chưa gắn xong */
      }
    });
  }

  // ── [THÊM] Đường tắt: chọn từ Sổ địa chỉ đã lưu ──────────────────────────
  // CHỈ điền nhanh địa chỉ: mở bảng chọn, rồi set text + toạ độ (_dest) và gọi
  // ĐÚNG hàm tính phí ship hiện có (_shippingService.calculate) y như
  // _selectPlace. KHÔNG can thiệp logic đặt hàng/ví/gateway.
  Future<void> _openSavedAddressPicker() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SavedAddressPickerSheet(),
    );
    if (picked != null) await _applySavedAddress(picked);
  }

  Future<void> _applySavedAddress(SavedAddress a) async {
    _debounce?.cancel();
    _selectedAddress = a.address;
    _addressCtrl.text = a.address;
    _addressCtrl.selection = TextSelection.collapsed(offset: a.address.length);
    setState(() {
      _suggestions = [];
      _dest = null;
      _quote = null;
      _loadingFee = true;
    });
    try {
      final latLng = LatLng(a.lat, a.lng);
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

  Widget _savedAddressShortcut() {
    return PressableScale(
      onTap: _openSavedAddressPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.accentSoftLine),
        ),
        child: Row(
          children: [
            TvIcon('map-pin', size: 18, color: AppColors.textAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chọn từ sổ địa chỉ đã lưu',
                style: AppText.sm(
                  AppColors.textAccent,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TvIcon('chevron-right', size: 18, color: AppColors.textAccent),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    if (_dest == null || _quote == null || _selectedAddress.isEmpty) {
      TvToast.show(context, 'Vui lòng chọn địa chỉ nhận hàng để tính phí.');
      return;
    }
    if (_walletInsufficient) {
      TvToast.show(context, 'Số dư ví không đủ. Hãy nạp thêm rồi thử lại.');
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
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentWaitingScreen(
              orderId: result.orderId,
              gatewayUrl: result.gatewayUrl!,
            ),
          ),
        );
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                14,
                AppSpacing.gutter,
                24,
              ),
              // Các section vào màn theo stagger — logic Goong/map giữ nguyên.
              children:
                  <Widget>[
                        _addressSection(),
                        const SizedBox(height: 26),
                        _paymentSection(),
                        const SizedBox(height: 26),
                        _invoiceCard(),
                        const SizedBox(height: 26),
                        TvButton(
                          label: isVNPay
                              ? 'Thanh toán qua VNPay'
                              : _walletSelected
                              ? 'Trả bằng ví'
                              : 'Xác nhận đặt hàng',
                          size: TvButtonSize.lg,
                          fullWidth: true,
                          loading: _confirming,
                          leadingIcon: isVNPay
                              ? const TvIcon('external-link', size: 18)
                              : _walletSelected
                              ? const TvIcon('wallet', size: 18)
                              : null,
                          // Ví thiếu số dư → khoá nút, khách dùng "Nạp thêm" ở trên.
                          onPressed: _walletInsufficient ? null : _confirm,
                        ),
                        const SizedBox(height: 12),
                        // Trust line — giọng "tech data" JetBrains Mono.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TvIcon(
                              'lock',
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AES-256 ENCRYPTED CHECKOUT',
                              style: AppText.mono(
                                size: 10.5,
                                color: AppColors.textTertiary,
                              ).copyWith(letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ]
                      .animate(interval: AppEffects.staggerStep)
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
                style: AppText.body().copyWith(fontWeight: FontWeight.w700),
              ),
              if (apiClient.userEmail != null)
                TextSpan(
                  text: ' · ${apiClient.userEmail}',
                  style: AppText.body(AppColors.textSecondary),
                ),
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
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textAccent,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        _savedAddressShortcut(),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          _suggestionList(),
        ],
        if (_loadingFee) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Đang tính phí giao hàng...',
                style: AppText.sm(AppColors.textSecondary),
              ),
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
            if (i > 0) Divider(height: 1, color: AppColors.borderSubtle),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectPlace(_suggestions[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    TvIcon('map-pin', size: 16, color: AppColors.textTertiary),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 190,
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _store,
            initialZoom: 12,
            interactionOptions: InteractionOptions(
              flags:
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            const TvMapTiles(),
            if (route.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    strokeWidth: 4,
                    color: AppColors.accent,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _store,
                  width: 38,
                  height: 38,
                  child: _pin('truck', AppColors.textSecondary),
                ),
                if (_dest != null)
                  Marker(
                    point: _dest!,
                    width: 38,
                    height: 38,
                    child: _pin('map-pin', AppColors.accent),
                  ),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.goldSoft,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.goldSoftLine),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TvIcon(icon, size: 14, color: AppColors.textAccent),
        const SizedBox(width: 6),
        Text(text, style: AppText.sm(AppColors.textPrimary)),
      ],
    ),
  );

  Widget _paymentSection() {
    // Phương thức call API thật: VNPay (cổng) + Ví (trừ số dư) + COD (trả khi nhận).
    final methods = MockData.paymentMethods
        .where(
          (m) => m.value == 'VNPay' || m.value == 'Wallet' || m.value == 'COD',
        )
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
            subtitle: method.value == 'Wallet' && _walletBalance != null
                ? 'Số dư: ${formatVnd(_walletBalance!)}'
                : method.subtitle,
            selected: _payment == method.value,
            onTap: () => setState(() => _payment = method.value),
          ),
          if (method != methods.last) const SizedBox(height: 10),
        ],
        if (_walletSelected && _walletInsufficient) ...[
          const SizedBox(height: 12),
          _walletTopUpPrompt(),
        ],
      ],
    );
  }

  /// Cảnh báo thiếu số dư + lối nạp nhanh (mở màn Ví, quay lại thì làm mới số dư).
  Widget _walletTopUpPrompt() {
    final missing = _grand - (_walletBalance ?? 0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.dangerLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon('alert-circle', size: 16, color: AppColors.danger500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Số dư ví không đủ · còn thiếu ${formatVnd(missing)}',
                  style: AppText.sm(
                    AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TvButton(
            label: 'Nạp thêm vào ví',
            variant: TvButtonVariant.secondary,
            size: TvButtonSize.md,
            fullWidth: true,
            leadingIcon: const TvIcon('plus-circle', size: 18),
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
              _loadWalletBalance(); // về lại checkout → cập nhật số dư mới
            },
          ),
        ],
      ),
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
          Padding(
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

// ═══════════════════════════════════════════════════════════════════════════
// [THÊM] Bảng chọn nhanh từ Sổ địa chỉ đã lưu — chỉ trả về [SavedAddress] qua
// pop(); toàn bộ việc điền + tính phí do _applySavedAddress ở Checkout xử lý.
// ═══════════════════════════════════════════════════════════════════════════
class _SavedAddressPickerSheet extends StatefulWidget {
  const _SavedAddressPickerSheet();

  @override
  State<_SavedAddressPickerSheet> createState() =>
      _SavedAddressPickerSheetState();
}

class _SavedAddressPickerSheetState extends State<_SavedAddressPickerSheet> {
  @override
  void initState() {
    super.initState();
    AddressService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
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
          Text('Sổ địa chỉ đã lưu', style: AppText.h2().copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<SavedAddress>>(
            valueListenable: AddressService.instance.notifier,
            builder: (context, items, _) {
              if (items.isEmpty) return _emptyHint();
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _pickRow(items[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          TvIcon('map-pin', size: 30, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'Chưa có địa chỉ nào được lưu.',
            style: AppText.sm(AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm địa chỉ ở Hồ sơ → Sổ địa chỉ để chọn nhanh tại đây.',
            textAlign: TextAlign.center,
            style: AppText.xs(AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _pickRow(SavedAddress a) {
    return PressableScale(
      onTap: () => Navigator.of(context).pop(a),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            TvIcon('map-pin', size: 18, color: AppColors.textAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong().copyWith(fontSize: 14),
                        ),
                      ),
                      if (a.isDefault) ...[
                        const SizedBox(width: 8),
                        TvBadge('Mặc định', variant: TvBadgeVariant.accent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.xs(
                      AppColors.textTertiary,
                    ).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TvIcon('chevron-right', size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/goong_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';

/// Trang Staff — quản lý giao hàng:
/// - "Bắt đầu giao" = gán shipper (`assign-shipper` → Shipped).
/// - "Xem & Chạy" = đọc GPS thiết bị, gửi `tracking/location` mỗi 5s để khách
///   theo dõi realtime. (Bước "Xác nhận giao + ảnh" sẽ thêm sau.)
class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  final _service = OrderService();
  final _auth = AuthService();
  final _mapController = MapController();

  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _busyId;
  StaffTab _tab = StaffTab.toDeliver;

  // ── Trạng thái gửi GPS ────────────────────────────────────────────────────
  String? _trackingOrderId; // đơn đang "chạy" (gửi vị trí)
  Timer? _gpsTimer;
  LatLng? _lastPos;
  DateTime? _lastSentAt;

  /// Tâm bản đồ mặc định khi chưa có vị trí (kho FPT).
  static const LatLng _fallbackCenter = LatLng(10.841122, 106.809935);

  /// Tần suất gửi GPS lên BE — ĐỔI 1 CHỖ DUY NHẤT TẠI ĐÂY.
  /// DEMO: để 2s cho dễ thấy marker di chuyển khi trình diễn.
  /// THỰC TẾ: nên đổi lên 5–10s để tiết kiệm pin & băng thông.
  static const Duration _gpsInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
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

  Future<void> _startDelivery(OrderModel o) async {
    final staffId = apiClient.userId;
    if (staffId == null) {
      TvToast.show(context, 'Không xác định được nhân viên. Hãy đăng nhập lại.');
      return;
    }
    setState(() => _busyId = o.id);
    try {
      await _service.assignShipper(o.id, staffId);
      await _load();
      if (mounted) {
        TvToast.show(context, 'Đã bắt đầu giao đơn #${_shortId(o.id)}.');
      }
    } catch (_) {
      if (mounted) TvToast.show(context, 'Bắt đầu giao thất bại.');
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
    if (ok != true) return;
    setState(() => _busyId = o.id);
    try {
      await _service.updateOrderStatus(o.id, OrderStatus.cancelled);
      await _load();
    } catch (_) {
      if (mounted) TvToast.show(context, 'Huỷ đơn thất bại.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // ── GPS: bắt đầu / gửi 1 nhịp / dừng ──────────────────────────────────────
  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) TvToast.show(context, 'Hãy bật Vị trí (GPS) trên thiết bị.');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) TvToast.show(context, 'Ứng dụng cần quyền vị trí để gửi GPS.');
      return false;
    }
    return true;
  }

  Future<void> _startTracking(OrderModel o) async {
    if (_busyId == o.id) return;
    final staffId = apiClient.userId;
    if (staffId == null) {
      TvToast.show(context, 'Đăng nhập lại để lấy mã nhân viên.');
      return;
    }
    setState(() => _busyId = o.id);
    final ok = await _ensureLocationPermission();
    if (!ok) {
      if (mounted) setState(() => _busyId = null);
      return;
    }
    if (!mounted) return;
    setState(() {
      _trackingOrderId = o.id;
      _lastPos = null;
      _lastSentAt = null;
      _busyId = null;
    });
    await _sendOnce(o.id, staffId);
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(
        _gpsInterval, (_) => _sendOnce(o.id, staffId));
    if (mounted) {
      TvToast.show(context, 'Đang gửi vị trí cho đơn #${_shortId(o.id)}.');
    }
  }

  Future<void> _sendOnce(String orderId, String staffId) async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _service.sendLocation(
        shipperId: staffId,
        lat: pos.latitude,
        lng: pos.longitude,
        orderId: orderId,
      );
      if (!mounted) return;
      setState(() {
        _lastPos = LatLng(pos.latitude, pos.longitude);
        _lastSentAt = DateTime.now();
      });
      try {
        _mapController.move(_lastPos!, 15);
      } catch (_) {/* map chưa sẵn sàng */}
    } catch (_) {
      // bỏ qua 1 nhịp lỗi, vòng sau thử lại
    }
  }

  void _stopTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    setState(() {
      _trackingOrderId = null;
      _lastPos = null;
      _lastSentAt = null;
    });
  }

  // ── Xác nhận đã giao + ảnh chứng minh ─────────────────────────────────────
  Future<void> _confirmDelivery(OrderModel o) async {
    if (_busyId == o.id) return;
    final source = await _pickImageSource();
    if (source == null) return;
    final XFile? photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (photo == null || !mounted) return;
    setState(() => _busyId = o.id);
    try {
      await _service.confirmDelivery(o.id, photo.path);
      if (_trackingOrderId == o.id) _stopTracking(); // đang gửi GPS đơn này → dừng
      await _load(); // đơn chuyển sang "Xong"
      if (mounted) {
        TvToast.show(context, 'Đã giao thành công đơn #${_shortId(o.id)}.');
      }
    } catch (_) {
      if (mounted) TvToast.show(context, 'Xác nhận giao thất bại.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  /// Bottom sheet chọn nguồn ảnh: chụp mới hoặc lấy từ thư viện.
  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Ảnh xác nhận giao hàng',
                style: AppText.h3().copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            ListTile(
              leading: const TvIcon('camera', color: AppColors.textAccent),
              title: Text('Chụp ảnh', style: AppText.body()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const TvIcon('image', color: AppColors.textAccent),
              title: Text('Chọn từ thư viện', style: AppText.body()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    _gpsTimer?.cancel();
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  String _hms(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

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
            title: 'Quản lý giao hàng',
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
          child: Text('Không có đơn ở mục này',
              style: AppText.body(AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _orderCard(OrderModel o) {
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
          ..._actions(o, busy),
        ],
      ),
    );
  }

  String? _metaLine(OrderModel o) {
    final time = formatRelativeFromIso(o.orderDate);
    final parts = <String>[
      if (o.itemCount != null) '${o.itemCount} sản phẩm',
      if (time.isNotEmpty) time,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  List<Widget> _actions(OrderModel o, bool busy) {
    // Đơn chưa giao → "Bắt đầu giao" + "Huỷ".
    if (OrderFlow.staffCanStartDelivery(o.status)) {
      return [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TvButton(
                label: 'Bắt đầu giao',
                size: TvButtonSize.md,
                fullWidth: true,
                loading: busy,
                leadingIcon: const TvIcon('truck', size: 16),
                onPressed: () => _startDelivery(o),
              ),
            ),
            const SizedBox(width: 10),
            TvButton(
              label: 'Huỷ',
              variant: TvButtonVariant.ghost,
              size: TvButtonSize.md,
              onPressed: busy ? null : () => _cancel(o),
            ),
          ],
        ),
      ];
    }
    // Đơn đang giao (Shipped) → GPS.
    if (OrderFlow.isDelivering(o.status)) {
      final isThis = _trackingOrderId == o.id;
      final otherActive = _trackingOrderId != null && _trackingOrderId != o.id;
      if (isThis) {
        return [
          const SizedBox(height: 12),
          _liveMap(),
          const SizedBox(height: 8),
          Row(
            children: [
              const TvIcon('zap', size: 14, color: AppColors.success500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _lastSentAt == null
                      ? 'Đang lấy vị trí...'
                      : 'Đang gửi vị trí · ${_hms(_lastSentAt!)}',
                  style: AppText.xs(AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TvButton(
            label: 'Xác nhận đã giao',
            size: TvButtonSize.md,
            fullWidth: true,
            loading: busy,
            leadingIcon: const TvIcon('package-check', size: 16),
            onPressed: () => _confirmDelivery(o),
          ),
          const SizedBox(height: 10),
          TvButton(
            label: 'Dừng giao',
            variant: TvButtonVariant.ghost,
            size: TvButtonSize.md,
            fullWidth: true,
            onPressed: _stopTracking,
          ),
        ];
      }
      return [
        const SizedBox(height: 12),
        TvButton(
          label: otherActive ? 'Đang chạy đơn khác' : 'Xem & Chạy',
          size: TvButtonSize.md,
          fullWidth: true,
          loading: busy,
          leadingIcon: const TvIcon('zap', size: 16),
          onPressed: otherActive ? null : () => _startTracking(o),
        ),
        const SizedBox(height: 10),
        TvButton(
          label: 'Xác nhận đã giao',
          variant: TvButtonVariant.ghost,
          size: TvButtonSize.md,
          fullWidth: true,
          loading: busy,
          leadingIcon: const TvIcon('package-check', size: 16),
          onPressed: () => _confirmDelivery(o),
        ),
      ];
    }
    return const [];
  }

  Widget _liveMap() {
    final pos = _lastPos;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pos ?? _fallbackCenter,
            initialZoom: 15,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: GoongConfig.osmTileUrl,
              userAgentPackageName: 'com.techstore.tech_void',
            ),
            if (pos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: pos,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgBase,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.success500, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const TvIcon('truck',
                          size: 18, color: AppColors.success500),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

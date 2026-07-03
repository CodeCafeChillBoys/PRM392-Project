import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/goong_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/goong_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/tracking_hub_client.dart';
import '../../widgets/widgets.dart';

/// Màn KHÁCH theo dõi shipper realtime cho 1 đơn đang giao.
/// Lấy vị trí lần đầu qua REST, sau đó nghe SignalR `ReceiveLocation` để marker
/// shipper di chuyển trên bản đồ. Hiển thị pin Nhà khách + Cửa hàng + tuyến Shipper→Nhà.
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _service = OrderService();
  final _goong = GoongService();
  final _hub = TrackingHubClient();
  final _mapController = MapController();

  LatLng? _shipper;
  LatLng? _dest;
  List<LatLng> _route = [];
  Timer? _pollTimer; // lưới an toàn khi SignalR gián đoạn
  DateTime? _lastRouteAt;
  String? _updatedAt;
  bool _loading = true; // đang lấy vị trí lần đầu
  bool _live = false; // đã kết nối realtime
  bool _initialFitDone = false;
  bool _delivered = false; // đơn đã giao xong → ngừng theo dõi
  String? _error;

  /// Toạ độ kho — khớp BE `Goong:StoreLatitude/Longitude` và checkout.
  static const LatLng _store = LatLng(10.841122, 106.809935);
  static const LatLng _fallbackCenter = LatLng(10.841122, 106.809935);
  static const Duration _routeThrottle = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1) Vị trí shipper (REST) + geocode địa chỉ nhà khách (song song).
    final shipperFuture = _service.fetchShipperLocation(widget.order.id);
    final destFuture = _goong.geocodeAddress(widget.order.shippingAddress);
    final initial = await shipperFuture;
    final dest = await destFuture;
    if (!mounted) return;
    setState(() {
      _shipper = initial;
      _dest = dest;
      _loading = false;
    });
    _fitAllMarkers();
    await _updateRoute(force: true);

    // 2) Kết nối realtime (SignalR).
    try {
      await _hub.connect(widget.order.id, _onLocation);
      if (mounted) setState(() => _live = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không kết nối được theo dõi realtime.');
      }
    }

    // 3) Lưới an toàn: SignalR có thể chập chờn (rớt/reconnect) trên emulator &
    //    mạng yếu. Poll REST định kỳ để xe vẫn cập nhật dù realtime gián đoạn.
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _pollLocation());
  }

  /// Lấy vị trí shipper mới nhất qua REST (dự phòng khi SignalR không đẩy kịp)
  /// và phát hiện đơn đã giao xong để ngừng theo dõi.
  Future<void> _pollLocation() async {
    // Đơn đã giao (Staff "Xác nhận đã giao") → dừng poll + realtime, báo thành công.
    final status = await _service.fetchOrderStatus(widget.order.id);
    if (!mounted) return;
    if (status == 'Delivered') {
      _pollTimer?.cancel();
      _hub.disconnect();
      setState(() => _delivered = true);
      return;
    }
    final p = await _service.fetchShipperLocation(widget.order.id);
    if (p == null || !mounted) return;
    final cur = _shipper;
    if (cur != null && p.latitude == cur.latitude && p.longitude == cur.longitude) {
      return; // không đổi -> khỏi vẽ lại
    }
    setState(() => _shipper = p);
    _updateRoute();
  }

  void _onLocation(double lat, double lng, String? updatedAt) {
    if (!mounted) return;
    final p = LatLng(lat, lng);
    setState(() {
      _shipper = p;
      _updatedAt = updatedAt;
      _live = true;
    });
    _updateRoute();
    // Chỉ cập nhật marker shipper; không fit lại để tránh giật bản đồ.
  }

  /// Gọi Goong Direction shipper → nhà; throttle 5s để tiết kiệm quota.
  Future<void> _updateRoute({bool force = false}) async {
    final shipper = _shipper;
    final dest = _dest;
    if (shipper == null || dest == null) return;

    final now = DateTime.now();
    if (!force &&
        _lastRouteAt != null &&
        now.difference(_lastRouteAt!) < _routeThrottle) {
      return;
    }
    _lastRouteAt = now;

    final route = await _goong.directionRoute(shipper, dest);
    if (!mounted) return;
    setState(() => _route = route);
  }

  /// Canh khung bản đồ lần đầu để thấy shipper + nhà khách + cửa hàng.
  void _fitAllMarkers() {
    if (_initialFitDone) return;
    final pts = <LatLng>[
      _store,
      ?_dest,
      ?_shipper,
    ];
    if (pts.length < 2) return;
    _initialFitDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: pts,
            padding: const EdgeInsets.all(48),
          ),
        );
      } catch (_) {/* map chưa gắn xong */}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _hub.disconnect();
    super.dispose();
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  String _fmtTime(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Theo dõi đơn #${_shortId(widget.order.id)}',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: _mapView()),
        ],
      ),
    );
  }

  Widget _mapView() {
    final s = _shipper;
    final d = _dest;
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: s ?? d ?? _fallbackCenter,
              initialZoom: s != null || d != null ? 14 : 12,
              interactionOptions: const InteractionOptions(
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
              if (_route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 4,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _store,
                    width: 40,
                    height: 40,
                    child: _pin('package', AppColors.textSecondary),
                  ),
                  if (d != null)
                    Marker(
                      point: d,
                      width: 40,
                      height: 40,
                      child: _pin('map-pin', AppColors.accent),
                    ),
                  if (s != null)
                    Marker(
                      point: s,
                      width: 48,
                      height: 48,
                      child: _pin('truck', AppColors.accent),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(left: 12, right: 12, bottom: 12, child: _statusCard()),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.textAccent)),
            ),
          ),
      ],
    );
  }

  Widget _pin(String icon, Color color) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgBase,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: TvIcon(icon, size: 20, color: color),
      );

  Widget _statusCard() {
    final (String icon, String text, Color color) = _statusInfo();
    return TvCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TvIcon('map-pin', size: 16, color: AppColors.textAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.order.shippingAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sm()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TvIcon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: AppText.xs(color))),
            ],
          ),
        ],
      ),
    );
  }

  (String, String, Color) _statusInfo() {
    if (_delivered) {
      return ('package-check', 'Đơn đã giao thành công 🎉', AppColors.success500);
    }
    if (_error != null) {
      return ('x-circle', _error!, AppColors.danger500);
    }
    if (_shipper == null) {
      return (
        'clock',
        'Shipper chưa bắt đầu di chuyển. Màn hình sẽ tự cập nhật.',
        AppColors.textSecondary
      );
    }
    if (_live) {
      final when = _updatedAt != null ? ' · cập nhật ${_fmtTime(_updatedAt!)}' : '';
      return ('zap', 'Đang theo dõi realtime$when', AppColors.success500);
    }
    return ('clock', 'Đang kết nối...', AppColors.textSecondary);
  }
}

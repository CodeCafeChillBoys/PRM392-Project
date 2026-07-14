import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _service = OrderService();
  final _goong = GoongService();
  final _hub = TrackingHubClient();
  final _mapController = MapController();

  LatLng? _shipper; // vị trí mục tiêu mới nhất (dùng cho route/fit khung)
  // Nội suy marker: xe trượt mượt từ _animFrom → _animTo thay vì nhảy giật.
  late final AnimationController _moveCtrl;
  LatLng? _animFrom;
  LatLng? _animTo;
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
  static const Distance _dist = Distance(); // đo khoảng cách khi trim đường

  /// Vị trí marker đang HIỂN THỊ (nội suy giữa 2 điểm liên tiếp cho mượt).
  /// Khi không có chặng nào đang chạy, trả về vị trí mục tiêu `_shipper`.
  LatLng? get _animatedShipper {
    final a = _animFrom, b = _animTo;
    if (a == null || b == null) return _shipper;
    final t = Curves.easeInOut.transform(_moveCtrl.value);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Chiếu điểm [p] xuống đoạn [a]-[b]; trả về (chân vuông góc, t trong [0,1]).
  (LatLng, double) _projectOnSeg(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude, ay = a.latitude;
    final bx = b.longitude, by = b.latitude;
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return (a, 0);
    var t = ((p.longitude - ax) * dx + (p.latitude - ay) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    return (LatLng(ay + dy * t, ax + dx * t), t);
  }

  /// Đường polyline THỰC SỰ vẽ: bắt đầu ĐÚNG tại xe [car], rồi kéo dài theo phần
  /// tuyến còn Ở PHÍA TRƯỚC xe tới đích. Tính lại mỗi frame cùng lúc với marker
  /// nên đoạn sau lưng xe "bị ăn" đúng frame xe đi qua (kiểu Grab/Gojek).
  List<LatLng> _visibleRoute(LatLng? car) {
    final r = _route;
    if (car == null || r.length < 2) return const [];
    // Tìm đoạn gần xe nhất theo khoảng cách vuông góc (trượt liên tục, không giật đỉnh).
    var bestSeg = 0;
    var bestD = double.infinity;
    var bestFoot = r[0];
    for (var i = 0; i < r.length - 1; i++) {
      final (foot, _) = _projectOnSeg(car, r[i], r[i + 1]);
      final d = _dist.as(LengthUnit.Meter, car, foot);
      if (d < bestD) {
        bestD = d;
        bestSeg = i;
        bestFoot = foot;
      }
    }
    // Xe → chân vuông góc → các đỉnh phía trước → đích.
    final out = <LatLng>[car, bestFoot];
    for (var i = bestSeg + 1; i < r.length; i++) {
      out.add(r[i]);
    }
    // Khử điểm trùng sát nhau để không tạo polyline suy biến (1 điểm) lúc tới đích.
    final dedup = <LatLng>[];
    for (final pt in out) {
      if (dedup.isEmpty || _dist.as(LengthUnit.Meter, dedup.last, pt) > 0.5) {
        dedup.add(pt);
      }
    }
    return dedup.length >= 2 ? dedup : const [];
  }

  /// Nhận vị trí shipper mới → cho marker TRƯỢT mượt tới đó (thay vì teleport).
  /// Bắt đầu chặng mới từ vị trí đang hiển thị nên nếu điểm mới tới khi chặng
  /// cũ chưa xong vẫn liền mạch, không giật ngược.
  void _moveShipperTo(LatLng target) {
    // Bỏ qua nếu đích không đổi (tránh chạy tween thừa).
    final to = _animTo ?? _shipper;
    if (to != null &&
        target.latitude == to.latitude &&
        target.longitude == to.longitude) {
      return;
    }
    final start = _animatedShipper ?? target;
    setState(() {
      _shipper = target;
      _animFrom = start;
      _animTo = target;
    });
    _moveCtrl.forward(from: 0);
    _updateRoute();
  }

  @override
  void initState() {
    super.initState();
    // Duration 2000ms = khớp nhịp máy Staff gửi vị trí (StaffOrders _gpsInterval
    // = 2s). Marker trượt mượt từ điểm cũ → điểm mới bằng tween easeInOut.
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        if (mounted) setState(() {}); // redraw marker mỗi frame khi tween chạy
      });
    _init();
  }

  Future<void> _init() async {
    // 1) Vị trí shipper (REST) + geocode địa chỉ nhà khách (song song).
    //    BỌC try/catch: nếu Goong/REST timeout hoặc lỗi mạng, KHÔNG được để
    //    exception văng ra trước khi tắt spinner — nếu không _loading kẹt `true`
    //    → xoay mãi không phục hồi. Lỗi mạng lúc mở màn vẫn cho vào; poll/SignalR
    //    sẽ tự cập nhật vị trí + tuyến sau đó.
    LatLng? initial;
    LatLng? dest;
    try {
      final shipperFuture = _service.fetchShipperLocation(widget.order.id);
      final destFuture = _goong.geocodeAddress(widget.order.shippingAddress);
      initial = await shipperFuture;
      dest = await destFuture;
    } catch (_) {
      // Nuốt lỗi mạng lúc khởi tạo — spinner vẫn phải tắt ở dưới.
    }
    if (!mounted) return;
    setState(() {
      _shipper = initial;
      _dest = dest;
      _loading = false; // LUÔN tắt spinner dù thành công hay lỗi
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
    try {
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
      if (cur != null &&
          p.latitude == cur.latitude &&
          p.longitude == cur.longitude) {
        return; // không đổi -> khỏi vẽ lại
      }
      _moveShipperTo(p); // trượt mượt tới điểm mới (đã gọi _updateRoute bên trong)
    } catch (_) {
      // Lỗi mạng thoáng qua (reset/timeout) — bỏ qua nhịp này, vòng poll sau thử lại.
    }
  }

  void _onLocation(double lat, double lng, String? updatedAt) {
    if (!mounted) return;
    setState(() {
      _updatedAt = updatedAt;
      _live = true;
    });
    // Trượt mượt marker tới điểm mới (không fit lại để tránh giật bản đồ).
    _moveShipperTo(LatLng(lat, lng));
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
    _moveCtrl.dispose();
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
    final s = _animatedShipper; // vị trí nội suy (mượt) cho marker xe
    final d = _dest;
    // Đường vẽ lấy từ CÙNG biến s như marker → co lại đúng frame xe di chuyển.
    final visible = _visibleRoute(s);
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
              const TvMapTiles(),
              if (visible.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: visible,
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
          Positioned.fill(
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
              TvIcon('map-pin', size: 16, color: AppColors.textAccent),
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

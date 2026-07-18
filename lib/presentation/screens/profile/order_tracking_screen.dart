import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/goong_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/tracking_hub_client.dart';
import '../../widgets/widgets.dart';
import 'tracking_panel.dart';

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
    with TickerProviderStateMixin {
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

  // ── Ghost preview: xe "xem trước" chạy lặp kho→nhà TRONG LÚC ĐỢI shipper ──
  late final AnimationController _ghostCtrl;

  /// Bảng chiều dài tích luỹ của _route (mét) — rebuild khi _route đổi,
  /// KHÔNG tính lại mỗi frame.
  List<double> _cum = const [0];
  double _routeLen = 0;

  // ── ETA từ Goong Direction (duration của tuyến còn lại) ──
  int? _durationSec;
  DateTime? _routeFetchedAt;

  int? get _etaMinutes =>
      _durationSec == null ? null : (_durationSec! / 60).ceil().clamp(1, 999);
  DateTime? get _etaArrival =>
      _routeFetchedAt?.add(Duration(seconds: _durationSec ?? 0));

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

  // ── Ghost preview: toán vị trí + vòng đời ─────────────────────────────────

  /// Rebuild bảng chiều dài tích luỹ khi _route đổi (không chạy mỗi frame).
  void _rebuildCum() {
    final c = <double>[0];
    for (var i = 0; i < _route.length - 1; i++) {
      c.add(c.last + _dist.as(LengthUnit.Meter, _route[i], _route[i + 1]));
    }
    _cum = c;
    _routeLen = c.last;
  }

  /// Vị trí xe ghost trên tuyến theo tiến độ vòng lặp: t → mét → lerp segment.
  LatLng? get _ghostPos {
    if (!_ghostCtrl.isAnimating || _route.length < 2 || _routeLen <= 0) {
      return null;
    }
    final target = _ghostCtrl.value * _routeLen;
    var i = 1;
    while (i < _cum.length - 1 && _cum[i] < target) {
      i++;
    }
    final segLen = _cum[i] - _cum[i - 1];
    final t = segLen <= 0 ? 0.0 : (target - _cum[i - 1]) / segLen;
    final a = _route[i - 1], b = _route[i];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Ghost chỉ chạy khi: chưa giao xong + CHƯA có GPS thật + có tuyến +
  /// người dùng không bật giảm-chuyển-động.
  bool get _ghostShouldRun =>
      !_delivered &&
      _shipper == null &&
      _route.length >= 2 &&
      MediaQuery.maybeDisableAnimationsOf(context) != true;

  /// Điểm đồng bộ DUY NHẤT (idempotent) — gọi sau mọi thay đổi trạng thái.
  void _syncGhost() {
    if (!mounted) return;
    if (_ghostShouldRun) {
      if (!_ghostCtrl.isAnimating) _ghostCtrl.repeat();
    } else if (_ghostCtrl.isAnimating) {
      _ghostCtrl.stop();
    }
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
    _syncGhost(); // GPS thật đã về → ghost preview tắt ngay lập tức
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
    // Ghost preview: 14s một vòng kho→nhà; chỉ chạy khi _syncGhost cho phép.
    // Tại mọi thời điểm chỉ 1 trong 2 controller hoạt động (ghost lúc đợi,
    // _moveCtrl lúc live) → chi phí frame không đổi so với trước.
    _ghostCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..addListener(() {
        if (mounted) setState(() {});
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
    // Poll ngay 1 nhịp: đơn ĐÃ giao từ trước thì pin sáng đèn ngay khi mở màn,
    // không phải đợi 5s tick đầu tiên.
    _pollLocation();
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
        _syncGhost(); // dừng xe preview nếu đang chạy
        // Spotlight về ĐIỂM NHẬN: camera dồn về nhà khách (pin sáng đèn).
        final dest = _dest;
        if (dest != null) {
          try {
            _mapController.move(dest, 15);
          } catch (_) {/* map chưa gắn xong */}
        }
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

  /// Gọi Goong Direction → nhà; throttle 5s để tiết kiệm quota.
  /// Origin = vị trí shipper, hoặc KHO khi chưa có shipper (tuyến "xem trước"
  /// cho ghost + ETA toàn tuyến trong lúc khách đợi).
  Future<void> _updateRoute({bool force = false}) async {
    final origin = _shipper ?? _store;
    final dest = _dest;
    if (dest == null) return;

    final now = DateTime.now();
    if (!force &&
        _lastRouteAt != null &&
        now.difference(_lastRouteAt!) < _routeThrottle) {
      return;
    }
    _lastRouteAt = now;

    final result = await _goong.directionRouteDetailed(origin, dest);
    if (!mounted) return;
    setState(() {
      _route = result.points;
      _durationSec = result.durationSeconds;
      _routeFetchedAt = DateTime.now();
    });
    _rebuildCum();
    _syncGhost();
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
            // Đáy chừa nhiều hơn: panel liquid-glass che ~24% dưới màn.
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 170),
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
    _ghostCtrl.dispose();
    super.dispose();
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
    final waiting = _shipper == null && !_delivered;
    // Xe ghost xem-trước chỉ tồn tại lúc đợi (GPS thật về là biến mất).
    final ghost = waiting ? _ghostPos : null;

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
              // Lúc đợi: toàn tuyến kho→nhà nét ĐỨT mờ (xem trước lộ trình).
              if (waiting && _route.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 3,
                      color: AppColors.accent.withValues(alpha: 0.45),
                      pattern: StrokePattern.dashed(segments: const [10, 8]),
                    ),
                  ],
                ),
              // Live: tuyến còn lại phía trước xe thật (trim theo frame).
              // Đã giao → ẩn (hành trình kết thúc, spotlight về pin nhận).
              if (!_delivered && visible.length >= 2)
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
                  // Kho: sau khi giao xong thì MỜ đi — điểm xuất phát đã hoàn
                  // thành vai trò, nhường spotlight cho điểm nhận.
                  Marker(
                    point: _store,
                    width: 40,
                    height: 40,
                    child: AnimatedOpacity(
                      duration: AppEffects.durSlow,
                      opacity: _delivered ? 0.3 : 1,
                      child: _pin('package', AppColors.textSecondary),
                    ),
                  ),
                  if (d != null)
                    Marker(
                      point: d,
                      width: _delivered ? 72 : 40,
                      height: _delivered ? 72 : 40,
                      child: _delivered ? _deliveredPin(context) : _pin('map-pin', AppColors.accent),
                    ),
                  // Ghost: xe mờ 55% + chip "XEM TRƯỚC" — không thể nhầm với xe thật.
                  if (ghost != null)
                    Marker(
                      point: ghost,
                      width: 78,
                      height: 74,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: 0.55,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: _pin('truck', AppColors.accent),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: AppColors.accentSoftLine),
                            ),
                            child: Text(
                              'XEM TRƯỚC',
                              style: AppText.label(AppColors.textAccent)
                                  .copyWith(fontSize: 7.5, letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Xe thật — ẩn sau khi giao xong (hành trình đã kết thúc).
                  if (s != null && !_delivered)
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
        // Panel liquid-glass kéo được: thông tin tài xế/ETA/timeline/sản phẩm.
        Positioned.fill(
          child: DraggableScrollableSheet(
            initialChildSize: 0.24,
            minChildSize: 0.18,
            maxChildSize: 0.82,
            snap: true,
            snapSizes: const [0.24, 0.55],
            builder: (context, scrollCtrl) => LiquidGlassPanel(
              child: TrackingPanel(
                order: widget.order,
                scrollController: scrollCtrl,
                waiting: waiting,
                live: _live,
                delivered: _delivered,
                error: _error,
                updatedAtIso: _updatedAt,
                etaMinutes: _etaMinutes,
                etaArrival: _etaArrival,
              ),
            ),
          ),
        ),
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

  /// Pin "SÁNG ĐÈN" tại nhà khách khi ĐÃ GIAO: lõi success phát sáng + quầng
  /// pulse lan toả lặp — spotlight của bản đồ dồn về điểm nhận hàng
  /// (đối lập với pin kho bị mờ đi). Tôn trọng reduce-motion (quầng đứng yên).
  Widget _deliveredPin(BuildContext context) {
    final halo = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success500.withValues(alpha: 0.22),
      ),
      child: const SizedBox.expand(),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: AppEffects.motionScale(context) > 0
              ? halo
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(
                    begin: 0.4,
                    end: 1,
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                  )
                  .fadeOut(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                  )
              : Opacity(opacity: 0.3, child: halo),
        ),
        // Lõi pin phát sáng.
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgBase,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success500, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.success500.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TvIcon('package-check', size: 20, color: AppColors.success500),
        ),
      ],
    );
  }

}

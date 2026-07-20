import 'package:signalr_netcore/signalr_client.dart';

import '../../core/config/api_config.dart';

/// Callback nhận vị trí shipper realtime.
typedef LocationCallback =
    void Function(double lat, double lng, String? updatedAt);

/// Kết nối SignalR tới `/trackingHub`, tham gia group của 1 đơn và nhận sự kiện
/// `ReceiveLocation` (BE bắn mỗi khi shipper gửi GPS).
class TrackingHubClient {
  HubConnection? _hub;
  String? _orderId;

  /// Kết nối + JoinOrderGroup(orderId) + lắng nghe vị trí.
  ///
  /// [onLive] (tuỳ chọn) báo trạng thái kết nối realtime: `true` khi đang kết
  /// nối trực tiếp, `false` khi đang nối lại / đã đóng — để UI hạ badge "Trực
  /// tiếp" xuống "Đang kết nối lại" thay vì báo live sai trong lúc mạng rớt.
  Future<void> connect(
    String orderId,
    LocationCallback onLocation, {
    void Function(bool live)? onLive,
  }) async {
    final hub = HubConnectionBuilder()
        .withUrl('${ApiConfig.baseUrl}${ApiConfig.trackingHub}')
        .withAutomaticReconnect()
        .build();

    hub.on('ReceiveLocation', (List<Object?>? args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          onLocation(lat, lng, data['updatedAt']?.toString());
        }
      }
    });

    // Mạng rớt → SignalR đang thử nối lại: hạ live để UI phản ánh đúng.
    hub.onreconnecting(({error}) => onLive?.call(false));

    // QUAN TRỌNG: group SignalR gắn theo connectionId. Khi rớt mạng và
    // `withAutomaticReconnect` nối lại, connectionId mới KHÔNG còn trong group
    // của đơn nên ngừng nhận `ReceiveLocation` (xe đứng yên cho tới khi mở lại
    // màn). Phải tham gia lại group sau mỗi lần reconnect.
    hub.onreconnected(({connectionId}) async {
      onLive?.call(true);
      try {
        await hub.invoke('JoinOrderGroup', args: [orderId]);
      } catch (_) {
        /* lần poll/nhịp sau sẽ bù */
      }
    });

    // Đóng hẳn (hết lượt reconnect) → live=false; poll REST 5s vẫn bù dữ liệu.
    hub.onclose(({error}) => onLive?.call(false));

    await hub.start();
    await hub.invoke('JoinOrderGroup', args: [orderId]);
    onLive?.call(true);
    _hub = hub;
    _orderId = orderId;
  }

  /// Rời group + ngắt kết nối (gọi khi đóng màn theo dõi).
  Future<void> disconnect() async {
    final hub = _hub;
    final orderId = _orderId;
    _hub = null;
    _orderId = null;
    if (hub == null) return;
    try {
      if (orderId != null) {
        await hub.invoke('LeaveOrderGroup', args: [orderId]);
      }
    } catch (_) {}
    try {
      await hub.stop();
    } catch (_) {}
  }
}

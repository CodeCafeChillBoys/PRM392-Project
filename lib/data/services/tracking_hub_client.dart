import 'package:signalr_netcore/signalr_client.dart';

import '../../core/config/api_config.dart';

/// Callback nhận vị trí shipper realtime.
typedef LocationCallback = void Function(
    double lat, double lng, String? updatedAt);

/// Kết nối SignalR tới `/trackingHub`, tham gia group của 1 đơn và nhận sự kiện
/// `ReceiveLocation` (BE bắn mỗi khi shipper gửi GPS).
class TrackingHubClient {
  HubConnection? _hub;
  String? _orderId;

  /// Kết nối + JoinOrderGroup(orderId) + lắng nghe vị trí.
  Future<void> connect(String orderId, LocationCallback onLocation) async {
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

    await hub.start();
    await hub.invoke('JoinOrderGroup', args: [orderId]);
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

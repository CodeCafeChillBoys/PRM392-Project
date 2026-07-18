/// Thiết bị của người dùng cho khu giám sát vận hành (Admin) — khớp BE
/// `DeviceInfoDTO`. KHÔNG chứa FcmToken.
class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.userId,
    this.deviceId = '',
    this.deviceName = '',
    this.deviceType = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String createdAt;
  final String updatedAt;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        id: '${json['id'] ?? ''}',
        userId: '${json['userId'] ?? ''}',
        deviceId: '${json['deviceId'] ?? ''}',
        deviceName: '${json['deviceName'] ?? ''}',
        deviceType: '${json['deviceType'] ?? ''}',
        createdAt: '${json['createdAt'] ?? ''}',
        updatedAt: '${json['updatedAt'] ?? ''}',
      );
}

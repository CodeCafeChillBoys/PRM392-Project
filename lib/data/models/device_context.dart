class DeviceContext {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String fcmToken;

  const DeviceContext({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.fcmToken,
  });
}

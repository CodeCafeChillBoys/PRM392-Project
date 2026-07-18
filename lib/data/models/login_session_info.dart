/// Phiên đăng nhập cho khu giám sát vận hành (Admin) — khớp BE
/// `LoginSessionInfoDTO`. KHÔNG chứa OtpCode/AccessToken/RefreshToken/FcmToken.
class LoginSessionInfo {
  const LoginSessionInfo({
    required this.id,
    required this.userId,
    this.customerName = '',
    this.customerEmail = '',
    this.status = '',
    this.isOtpSent = false,
    this.deviceName = '',
    this.deviceType = '',
    this.createdAt = '',
    this.expiredAt = '',
  });

  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;

  /// Trạng thái phiên: 'Approved' | 'Pending' | 'Expired' | ...
  final String status;
  final bool isOtpSent;
  final String deviceName;
  final String deviceType;
  final String createdAt;
  final String expiredAt;

  /// Phiên đã hết hạn theo mốc thời gian (client-side, so với hiện tại).
  bool get isExpired {
    final exp = DateTime.tryParse(expiredAt);
    return exp != null && exp.isBefore(DateTime.now());
  }

  factory LoginSessionInfo.fromJson(Map<String, dynamic> json) =>
      LoginSessionInfo(
        id: '${json['id'] ?? ''}',
        userId: '${json['userId'] ?? ''}',
        customerName:
            json['customerName'] as String? ?? json['fullName'] as String? ?? '',
        customerEmail: json['customerEmail'] as String? ??
            json['email'] as String? ??
            '',
        status: json['status'] as String? ?? '',
        isOtpSent: json['isOtpSent'] as bool? ?? false,
        deviceName: '${json['deviceName'] ?? ''}',
        deviceType: '${json['deviceType'] ?? ''}',
        createdAt: '${json['createdAt'] ?? ''}',
        expiredAt: '${json['expiredAt'] ?? ''}',
      );
}

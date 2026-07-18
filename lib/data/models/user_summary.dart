/// Người dùng tóm tắt cho khu Admin — khớp BE `UserSummaryDTO`
/// (KHÔNG bao giờ chứa passwordHash). Parse tolerant nhiều tên key.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.address = '',
    this.role = 'Customer',
    this.createdAt = '',
  });

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;

  /// 'Customer' | 'Staff' | 'Admin'.
  final String role;
  final String createdAt;

  bool get isAdmin => role == 'Admin';
  bool get isStaff => role == 'Staff';

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        id: '${json['id'] ?? json['userId'] ?? ''}',
        fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber:
            '${json['phoneNumber'] ?? json['phone'] ?? ''}',
        address: '${json['address'] ?? ''}',
        role: json['role'] as String? ?? 'Customer',
        createdAt: '${json['createdAt'] ?? ''}',
      );
}

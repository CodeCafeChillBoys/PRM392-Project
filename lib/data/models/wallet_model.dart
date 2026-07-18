/// Ví TechStore của user hiện tại — khớp BE `GET /api/wallet`
/// (`{success,data:{id,userId,balance,updatedAt}}`).
class WalletModel {
  const WalletModel({required this.balance, this.updatedAt});

  final double balance;
  final DateTime? updatedAt;

  /// Tolerant: chấp nhận cả `{data:{...}}` (response gốc) lẫn `{...}` (đã unwrap sẵn).
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return WalletModel(
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse('${data['updatedAt'] ?? ''}'),
    );
  }
}

/// Một giao dịch Ví — khớp BE `GET /api/wallet/transactions`
/// (`{id,type,status,amount,balanceBefore?,balanceAfter?,description?,
/// vnpayTransactionId?,orderId?,createdAt,processedAt?}`).
///
/// [type]: `TopUp | Payment | Withdrawal | Refund`.
/// [status]: `Pending | Completed | Failed` (BE trả chuỗi, không phải enum số).
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    this.balanceAfter,
    this.description,
    this.orderId,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final double amount;
  final double? balanceAfter;
  final String? description;
  final String? orderId;

  /// Chuỗi ISO — format qua [formatRelativeFromIso] ở UI (giống OrderModel.orderDate).
  final String createdAt;

  /// Tiền CỘNG vào ví (nạp tiền / hoàn tiền) — false = tiền TRỪ (thanh toán / rút tiền).
  bool get isCredit => type == 'TopUp' || type == 'Refund';

  String get typeLabel => switch (type) {
        'TopUp' => 'Nạp tiền',
        'Payment' => 'Thanh toán đơn',
        'Refund' => 'Hoàn tiền',
        'Withdrawal' => 'Rút tiền',
        _ => type,
      };

  String get statusLabel => switch (status) {
        'Pending' => 'Đang xử lý',
        'Completed' => 'Thành công',
        'Failed' => 'Thất bại',
        _ => status,
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: '${json['id'] ?? ''}',
        type: json['type'] as String? ?? '',
        status: json['status'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
        description: json['description'] as String?,
        orderId: json['orderId'] as String?,
        createdAt: '${json['createdAt'] ?? ''}',
      );
}

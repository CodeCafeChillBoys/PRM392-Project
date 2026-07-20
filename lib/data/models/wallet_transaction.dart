/// Loại giao dịch ví — khớp BE enum `WalletTransactionType`.
enum WalletTxnType { topUp, payment, withdrawal, refund, unknown }

WalletTxnType parseWalletTxnType(dynamic raw) {
  switch ('${raw ?? ''}'.toLowerCase()) {
    case 'topup':
    case '0':
      return WalletTxnType.topUp;
    case 'payment':
    case '1':
      return WalletTxnType.payment;
    case 'withdrawal':
    case '2':
      return WalletTxnType.withdrawal;
    case 'refund':
    case '3':
      return WalletTxnType.refund;
    default:
      return WalletTxnType.unknown;
  }
}

/// Một dòng lịch sử ví — khớp BE `WalletTransactionResponseDTO`.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.balanceBefore,
    this.balanceAfter,
    this.description,
    this.orderId,
    this.bankName,
    this.bankAccountNumber,
    this.accountHolderName,
    this.processedAt,
  });

  final String id;
  final WalletTxnType type;
  final String status; // Pending / Completed / Failed ...
  final double amount;
  final double? balanceBefore;
  final double? balanceAfter;
  final String? description;
  final String? orderId;
  final String? bankName;
  final String? bankAccountNumber;
  final String? accountHolderName;
  final DateTime createdAt;
  final DateTime? processedAt;

  /// Cộng tiền vào ví: nạp + hoàn. Trừ: thanh toán + rút.
  bool get isCredit =>
      type == WalletTxnType.topUp || type == WalletTxnType.refund;

  String get typeLabel {
    switch (type) {
      case WalletTxnType.topUp:
        return 'Nạp tiền';
      case WalletTxnType.payment:
        return 'Thanh toán đơn';
      case WalletTxnType.withdrawal:
        return 'Rút tiền';
      case WalletTxnType.refund:
        return 'Hoàn tiền';
      case WalletTxnType.unknown:
        return 'Giao dịch';
    }
  }

  /// Tên icon design-system (Lucide) theo loại giao dịch.
  String get iconKey {
    switch (type) {
      case WalletTxnType.topUp:
        return 'plus-circle';
      case WalletTxnType.payment:
        return 'shopping-bag';
      case WalletTxnType.withdrawal:
        return 'arrow-up-right';
      case WalletTxnType.refund:
        return 'rotate-ccw';
      case WalletTxnType.unknown:
        return 'circle';
    }
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: '${json['id'] ?? ''}',
        type: parseWalletTxnType(json['type']),
        status: '${json['status'] ?? ''}',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        balanceBefore: (json['balanceBefore'] as num?)?.toDouble(),
        balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
        description: json['description'] as String?,
        orderId: json['orderId'] as String?,
        bankName: json['bankName'] as String?,
        bankAccountNumber: json['bankAccountNumber'] as String?,
        accountHolderName: json['accountHolderName'] as String?,
        createdAt:
            DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        processedAt: DateTime.tryParse(
          '${json['processedAt'] ?? ''}',
        )?.toLocal(),
      );
}

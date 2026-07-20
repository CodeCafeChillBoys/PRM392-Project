/// Số dư ví — khớp BE `WalletResponseDTO { id, userId, balance, updatedAt }`.
class Wallet {
  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final double balance;
  final DateTime? updatedAt;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: '${json['id'] ?? ''}',
    userId: '${json['userId'] ?? ''}',
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}')?.toLocal(),
  );

  static const Wallet empty = Wallet(id: '', userId: '', balance: 0);
}

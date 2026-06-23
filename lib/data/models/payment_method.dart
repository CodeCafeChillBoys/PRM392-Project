/// A payment method accepted by `POST /api/order/checkout`.
///
/// [value] is the exact string the backend expects:
/// one of `VNPay`, `CreditCard`, `BankTransfer`, `COD`.
class PaymentMethod {
  const PaymentMethod({
    required this.value,
    required this.iconName,
    required this.title,
    required this.subtitle,
  });

  final String value;
  final String iconName; // design-system (Lucide) icon name
  final String title;
  final String subtitle;

  /// VNPay routes through an external payment-gateway step.
  bool get isGateway => value == 'VNPay';

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        value: json['value'] as String? ?? '',
        iconName: json['icon'] as String? ?? 'credit-card',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
      );
}

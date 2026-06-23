/// A shipping method shown on checkout (Hỏa tốc / Tiêu chuẩn).
class ShippingOption {
  const ShippingOption({
    required this.value,
    required this.iconName,
    required this.title,
    required this.subtitle,
    required this.fee,
  });

  final String value;
  final String iconName;
  final String title;
  final String subtitle;
  final double fee;
}

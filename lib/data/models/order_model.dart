/// Một đơn hàng — khớp BE `OrderResponseDTO`.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerName,
    required this.shippingAddress,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderDate,
    required this.shippingFee,
    required this.staffId,
    this.itemCount,
  });

  final String id;
  final String customerName;
  final String shippingAddress;
  final double totalAmount;
  final String status; // Pending / PendingPayment / Confirmed / Shipped / Delivered / Cancelled
  final String paymentMethod;
  final String paymentStatus; // Pending / Paid / Failed
  final String orderDate;

  /// Phí ship của đơn — đơn cũ (trước migration BE) chưa có cột này → 0.
  final double shippingFee;

  /// Mã nhân viên (shipper) được gán giao đơn — rỗng nếu chưa gán.
  final String staffId;

  /// Số sản phẩm trong đơn — chỉ có khi BE trả về; null thì UI ẩn dòng này.
  final int? itemCount;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: '${json['id'] ?? ''}',
        customerName: json['customerName'] as String? ?? '',
        shippingAddress: json['shippingAddress'] as String? ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? '',
        paymentMethod: json['paymentMethod'] as String? ?? '',
        paymentStatus: json['paymentStatus'] as String? ?? '',
        orderDate: '${json['orderDate'] ?? ''}',
        shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
        staffId: '${json['staffId'] ?? ''}',
        itemCount: _parseItemCount(json),
      );

  /// Ưu tiên field đếm sẵn; nếu không có thì suy ra từ độ dài mảng chi tiết đơn.
  static int? _parseItemCount(Map<String, dynamic> json) {
    final direct = json['itemCount'] ?? json['totalItems'] ?? json['itemsCount'];
    if (direct is num) return direct.toInt();
    final items = json['items'] ?? json['orderDetails'] ?? json['orderItems'];
    if (items is List) return items.length;
    return null;
  }
}

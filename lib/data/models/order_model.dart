/// Một dòng sản phẩm trong đơn — khớp BE `OrderDetailResponseDTO`
/// (`orderDetails[]` với productName/brand/imageUrl/quantity/unitPrice).
/// Parse tolerant nhiều tên key để chịu được thay đổi nhỏ phía BE.
class OrderLine {
  const OrderLine({
    required this.productName,
    this.brand = '',
    this.imageUrl = '',
    this.quantity = 1,
    this.unitPrice = 0,
  });

  final String productName;
  final String brand;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productName: '${json['productName'] ?? json['name'] ?? ''}',
        brand: '${json['brand'] ?? ''}',
        imageUrl:
            '${json['imageUrl'] ?? json['image'] ?? json['productImage'] ?? ''}',
        quantity: (json['quantity'] as num?)?.toInt() ??
            (json['qty'] as num?)?.toInt() ??
            1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ??
            (json['price'] as num?)?.toDouble() ??
            0,
      );
}

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
    this.lines = const [],
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

  /// Chi tiết sản phẩm trong đơn (tên/ảnh/số lượng/đơn giá) — rỗng nếu BE
  /// không trả mảng chi tiết. Dùng cho panel theo dõi đơn "đang giao gì".
  final List<OrderLine> lines;

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
        lines: _parseLines(json),
      );

  /// Ưu tiên field đếm sẵn; nếu không có thì suy ra từ độ dài mảng chi tiết đơn.
  static int? _parseItemCount(Map<String, dynamic> json) {
    final direct = json['itemCount'] ?? json['totalItems'] ?? json['itemsCount'];
    if (direct is num) return direct.toInt();
    final items = json['items'] ?? json['orderDetails'] ?? json['orderItems'];
    if (items is List) return items.length;
    return null;
  }

  /// Cùng thứ tự ưu tiên key với [_parseItemCount] để 2 field luôn nhất quán.
  static List<OrderLine> _parseLines(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['orderDetails'] ?? json['orderItems'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderLine.fromJson)
        .toList();
  }
}

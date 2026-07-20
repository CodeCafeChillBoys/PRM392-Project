/// Một dòng sản phẩm trong đơn — khớp BE `OrderDetailResponseDTO`
/// (`orderDetails[]` với productName/brand/imageUrl/quantity/unitPrice).
/// Parse tolerant nhiều tên key để chịu được thay đổi nhỏ phía BE.
class OrderLine {
  const OrderLine({
    this.id = '',
    required this.productName,
    this.brand = '',
    this.imageUrl = '',
    this.quantity = 1,
    this.unitPrice = 0,
  });

  /// Id của dòng đơn (OrderDetail.Id) — dùng để chọn món hoàn 1 phần.
  final String id;
  final String productName;
  final String brand;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        id: '${json['id'] ?? ''}',
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
    this.refundReason = '',
    this.refundImageUrl = '',
    this.refundRequestedAt,
    this.deliveredAt,
    this.cancelReason = '',
    this.cancelledAt,
    this.refundedAmount = 0,
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

  /// Lý do khách yêu cầu hoàn tiền — rỗng nếu chưa yêu cầu (luồng refund).
  final String refundReason;

  /// Ảnh đính kèm yêu cầu hoàn (URL tương đối `/uploads/...`) — rỗng nếu không có.
  final String refundImageUrl;

  /// Thời điểm khách gửi yêu cầu hoàn (ISO) — null nếu chưa yêu cầu.
  final String? refundRequestedAt;

  /// Thời điểm giao hàng thành công (ISO) — null nếu chưa giao/đơn cũ.
  final String? deliveredAt;

  /// Lý do huỷ đơn (khách/staff) — rỗng nếu chưa huỷ.
  final String cancelReason;

  /// Thời điểm đơn bị huỷ (ISO) — null nếu chưa huỷ.
  final String? cancelledAt;

  /// Số tiền đã hoàn cho đơn (>0 nếu đã hoàn 1 phần hoặc toàn bộ) — cho badge.
  final double refundedAmount;

  /// Còn trong cửa sổ yêu cầu hoàn tiền (1 ngày kể từ khi nhận hàng).
  /// Đơn cũ chưa có `deliveredAt` → false (không cho hoàn, khớp guard BE).
  bool get refundWindowOpen {
    final d = DateTime.tryParse(deliveredAt ?? '')?.toLocal();
    if (d == null) return false;
    return DateTime.now().difference(d) <= const Duration(days: 1);
  }

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
        refundReason: json['refundReason'] as String? ?? '',
        refundImageUrl: json['refundImageUrl'] as String? ?? '',
        refundRequestedAt: json['refundRequestedAt'] as String?,
        deliveredAt: json['deliveredAt'] as String?,
        cancelReason: json['cancelReason'] as String? ?? '',
        cancelledAt: json['cancelledAt'] as String?,
        refundedAmount: (json['refundedAmount'] as num?)?.toDouble() ?? 0,
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

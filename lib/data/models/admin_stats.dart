/// Thống kê tổng hợp cho dashboard Admin — khớp BE `AdminStatsResponse`.
/// Doanh thu "counted" đã theo đúng luật màn Doanh thu của Staff (BE lọc sẵn),
/// nên FE chỉ hiển thị, không tính lại. Parse tolerant giống `OrderModel`.
class AdminStats {
  const AdminStats({
    this.from = '',
    this.to = '',
    this.totalRevenue = 0,
    this.orderCount = 0,
    this.shippingFeeTotal = 0,
    this.newCustomers = 0,
    this.lowStockCount = 0,
    this.statusCounts = const [],
    this.paymentSplit = const [],
    this.revenueSeries = const [],
  });

  final String from;
  final String to;
  final double totalRevenue;
  final int orderCount;
  final double shippingFeeTotal;
  final int newCustomers;
  final int lowStockCount;
  final List<StatusCount> statusCounts;
  final List<PaymentSplit> paymentSplit;
  final List<RevenuePoint> revenueSeries;

  /// Tổng số đơn theo mọi trạng thái (mẫu số cho thanh tỉ lệ breakdown).
  int get statusTotal =>
      statusCounts.fold<int>(0, (s, e) => s + e.count);

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        from: '${json['from'] ?? ''}',
        to: '${json['to'] ?? ''}',
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        shippingFeeTotal:
            (json['shippingFeeTotal'] as num?)?.toDouble() ?? 0,
        newCustomers: (json['newCustomers'] as num?)?.toInt() ?? 0,
        lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
        statusCounts: _list(json['statusCounts'], StatusCount.fromJson),
        paymentSplit: _list(json['paymentSplit'], PaymentSplit.fromJson),
        revenueSeries: _list(json['revenueSeries'], RevenuePoint.fromJson),
      );

  static List<T> _list<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}

/// Số đơn theo một trạng thái (Pending / Confirmed / Delivered / ...).
class StatusCount {
  const StatusCount({required this.status, required this.count});

  final String status;
  final int count;

  factory StatusCount.fromJson(Map<String, dynamic> json) => StatusCount(
        status: json['status'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// Doanh thu + số đơn theo phương thức thanh toán (VNPay / COD).
class PaymentSplit {
  const PaymentSplit({
    required this.method,
    required this.count,
    required this.revenue,
  });

  final String method;
  final int count;
  final double revenue;

  factory PaymentSplit.fromJson(Map<String, dynamic> json) => PaymentSplit(
        method: json['method'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      );
}

/// Một điểm trên đường doanh thu theo ngày (cho biểu đồ cột).
class RevenuePoint {
  const RevenuePoint({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  /// Ngày (UTC-day do BE group theo `OrderDate.Date`); null nếu không parse được.
  final DateTime? date;
  final double revenue;
  final int orders;

  /// Nhãn trục X ngắn `dd/MM` — rỗng nếu thiếu ngày.
  String get shortLabel {
    final d = date;
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
        date: DateTime.tryParse('${json['date'] ?? ''}'),
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
      );
}

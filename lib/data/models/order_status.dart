/// Hằng số trạng thái đơn (khớp enum BE) + logic luồng đơn (thuần, không UI/IO).
///
/// Luồng GIAO HÀNG mới: Staff gán shipper (assign-shipper → Shipped) → giao
/// xong chụp ảnh (confirm-delivery → Delivered). Khách chỉ theo dõi shipper
/// trên bản đồ realtime, KHÔNG tự bấm "đã nhận".
class OrderStatus {
  OrderStatus._();

  static const String pending = 'Pending';
  static const String pendingPayment = 'PendingPayment';
  static const String confirmed = 'Confirmed';
  static const String shipped = 'Shipped';
  static const String delivered = 'Delivered';
  static const String cancelled = 'Cancelled';
}

/// Logic luồng đơn (thuần) — nguồn sự thật chung cho các màn.
class OrderFlow {
  OrderFlow._();

  /// Staff được "Bắt đầu giao" (gán shipper) khi đơn đã đặt/đã thanh toán nhưng
  /// chưa giao: COD (Pending) hoặc VNPay đã trả (Confirmed).
  /// PendingPayment (VNPay chưa trả) KHÔNG cho giao.
  static bool staffCanStartDelivery(String status) =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Đơn đang giao (đã gán shipper) — staff theo dõi GPS + xác nhận giao.
  static bool isDelivering(String status) => status == OrderStatus.shipped;

  /// Staff được huỷ khi đơn chưa rời kho (chưa Shipped/Delivered/Cancelled).
  static bool staffCanCancel(String status) =>
      status == OrderStatus.pending ||
      status == OrderStatus.pendingPayment ||
      status == OrderStatus.confirmed;
}

/// Tab của màn Staff; mỗi tab nhận một nhóm trạng thái.
enum StaffTab {
  all('Tất cả'),
  toDeliver('Cần giao'),
  delivering('Đang giao'),
  done('Xong');

  const StaffTab(this.label);
  final String label;

  bool accepts(String status) {
    switch (this) {
      case StaffTab.all:
        return true;
      case StaffTab.toDeliver:
        return status == OrderStatus.pending ||
            status == OrderStatus.confirmed;
      case StaffTab.delivering:
        return status == OrderStatus.shipped;
      case StaffTab.done:
        return status == OrderStatus.delivered ||
            status == OrderStatus.cancelled;
    }
  }
}

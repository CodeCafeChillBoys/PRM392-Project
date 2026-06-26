/// Hằng số trạng thái đơn (khớp enum BE) và state-machine luồng đơn.
///
/// Tách logic quyết định ra hàm THUẦN (không phụ thuộc UI/IO) để:
///  * test được nhanh bằng `flutter test`;
///  * màn Staff và "Đơn của tôi" dùng chung MỘT nguồn sự thật, tránh lệch luồng.
class OrderStatus {
  OrderStatus._();

  static const String pending = 'Pending';
  static const String pendingPayment = 'PendingPayment';
  static const String confirmed = 'Confirmed';
  static const String shipped = 'Shipped';
  static const String delivered = 'Delivered';
  static const String cancelled = 'Cancelled';
}

/// Một hành động chuyển trạng thái mà Staff có thể bấm.
class StaffAction {
  const StaffAction(this.nextStatus, this.label);
  final String nextStatus;
  final String label;
}

/// Logic luồng đơn (thuần).
class OrderFlow {
  OrderFlow._();

  /// Hành động CHÍNH của staff cho [status] (null = không có hành động).
  ///
  /// LƯU Ý quan trọng: `Shipped` trả về null — staff KHÔNG tự đánh dấu "Đã giao".
  /// Đơn chỉ chuyển sang `Delivered` khi KHÁCH bấm "Đã nhận hàng".
  static StaffAction? staffPrimaryAction(String status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.pendingPayment:
        return const StaffAction(OrderStatus.confirmed, 'Xác nhận đơn');
      case OrderStatus.confirmed:
        return const StaffAction(OrderStatus.shipped, 'Bắt đầu giao');
      default:
        return null;
    }
  }

  /// Staff được huỷ khi đơn chưa rời kho (chưa Shipped/Delivered/Cancelled).
  static bool staffCanCancel(String status) =>
      status == OrderStatus.pending ||
      status == OrderStatus.pendingPayment ||
      status == OrderStatus.confirmed;

  /// Đơn đang chờ KHÁCH xác nhận đã nhận hàng (staff chỉ chờ, không thao tác).
  static bool isAwaitingCustomer(String status) => status == OrderStatus.shipped;

  /// Khách được bấm "Đã nhận hàng" (→ Delivered).
  static bool customerCanConfirmReceipt(String status) =>
      status == OrderStatus.shipped;
}

/// 4 tab của màn Staff; mỗi tab nhận một nhóm trạng thái.
enum StaffTab {
  all('Tất cả'),
  pending('Chờ XN'),
  shipping('Đang giao'),
  done('Xong');

  const StaffTab(this.label);
  final String label;

  /// [status] có thuộc tab này không.
  bool accepts(String status) {
    switch (this) {
      case StaffTab.all:
        return true;
      case StaffTab.pending:
        return status == OrderStatus.pending ||
            status == OrderStatus.pendingPayment;
      case StaffTab.shipping:
        return status == OrderStatus.confirmed || status == OrderStatus.shipped;
      case StaffTab.done:
        return status == OrderStatus.delivered ||
            status == OrderStatus.cancelled;
    }
  }
}

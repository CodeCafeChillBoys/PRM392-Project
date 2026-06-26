import 'package:flutter/material.dart';

import '../../data/models/order_status.dart';
import 'tv_badge.dart';

/// (nhãn tiếng Việt, biến thể badge) cho một trạng thái đơn — NGUỒN SỰ THẬT
/// chung cho màn Staff và "Đơn của tôi". Tách hàm thuần để test được.
(String, TvBadgeVariant) orderStatusBadgeData(String status) {
  switch (status) {
    case OrderStatus.pending:
      return ('Chờ xác nhận', TvBadgeVariant.neutral);
    case OrderStatus.pendingPayment:
      return ('Chờ thanh toán', TvBadgeVariant.neutral);
    case OrderStatus.confirmed:
      return ('Đã xác nhận', TvBadgeVariant.glass);
    case OrderStatus.shipped:
      return ('Đang giao', TvBadgeVariant.glass);
    case OrderStatus.delivered:
      return ('Đã giao', TvBadgeVariant.success);
    case OrderStatus.cancelled:
      return ('Đã huỷ', TvBadgeVariant.danger);
    default:
      return (status, TvBadgeVariant.neutral);
  }
}

/// Pill trạng thái đơn dùng chung.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = orderStatusBadgeData(status);
    return TvBadge(label, variant: variant);
  }
}

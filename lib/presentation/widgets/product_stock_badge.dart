import 'package:flutter/material.dart';

import 'tv_badge.dart';

/// (nhãn tiếng Việt, biến thể badge) cho tồn kho sản phẩm — NGUỒN SỰ THẬT
/// chung cho danh sách + chi tiết ở khu Staff. Ngưỡng khớp getter của
/// `Product`: `isSoldOut` (<= 0), `isLowStock` (<= 10). Bộ variant không có
/// `warning` nên "sắp hết" dùng `accent` để gây chú ý. Tách hàm thuần để test.
(String, TvBadgeVariant) productStockBadgeData(int stockQuantity) {
  if (stockQuantity <= 0) return ('Hết hàng', TvBadgeVariant.danger);
  if (stockQuantity <= 10) {
    return ('Còn $stockQuantity', TvBadgeVariant.accent);
  }
  return ('Kho: $stockQuantity', TvBadgeVariant.neutral);
}

/// Pill tồn kho dùng chung cho khu Staff.
class ProductStockBadge extends StatelessWidget {
  const ProductStockBadge(this.stockQuantity, {super.key});

  final int stockQuantity;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = productStockBadgeData(stockQuantity);
    return TvBadge(label, variant: variant);
  }
}

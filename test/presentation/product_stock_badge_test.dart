import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/presentation/widgets/product_stock_badge.dart';
import 'package:tech_void/presentation/widgets/tv_badge.dart';

void main() {
  group('productStockBadgeData', () {
    test('hết hàng (<= 0) → danger', () {
      expect(productStockBadgeData(0), ('Hết hàng', TvBadgeVariant.danger));
      expect(productStockBadgeData(-1), ('Hết hàng', TvBadgeVariant.danger));
    });

    test('sắp hết (1..10) → accent, nhãn "Còn n"', () {
      expect(productStockBadgeData(1), ('Còn 1', TvBadgeVariant.accent));
      expect(productStockBadgeData(10), ('Còn 10', TvBadgeVariant.accent));
    });

    test('còn nhiều (> 10) → neutral, nhãn "Kho: n"', () {
      expect(productStockBadgeData(11), ('Kho: 11', TvBadgeVariant.neutral));
      expect(productStockBadgeData(240), ('Kho: 240', TvBadgeVariant.neutral));
    });
  });
}

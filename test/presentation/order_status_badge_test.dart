import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/order_status.dart';
import 'package:tech_void/presentation/widgets/order_status_badge.dart';
import 'package:tech_void/presentation/widgets/tv_badge.dart';

void main() {
  group('orderStatusBadgeData', () {
    test('nhãn tiếng Việt đúng theo trạng thái', () {
      expect(orderStatusBadgeData(OrderStatus.pending).$1, 'Chờ xác nhận');
      expect(
        orderStatusBadgeData(OrderStatus.pendingPayment).$1,
        'Chờ thanh toán',
      );
      expect(orderStatusBadgeData(OrderStatus.confirmed).$1, 'Đã xác nhận');
      expect(orderStatusBadgeData(OrderStatus.shipped).$1, 'Đang giao');
      expect(orderStatusBadgeData(OrderStatus.delivered).$1, 'Đã giao');
      expect(orderStatusBadgeData(OrderStatus.cancelled).$1, 'Đã huỷ');
    });
    test('biến thể badge đúng', () {
      expect(
        orderStatusBadgeData(OrderStatus.pending).$2,
        TvBadgeVariant.neutral,
      );
      expect(
        orderStatusBadgeData(OrderStatus.confirmed).$2,
        TvBadgeVariant.glass,
      );
      expect(
        orderStatusBadgeData(OrderStatus.delivered).$2,
        TvBadgeVariant.success,
      );
      expect(
        orderStatusBadgeData(OrderStatus.cancelled).$2,
        TvBadgeVariant.danger,
      );
    });
    test('trạng thái lạ → hiển thị nguyên văn, neutral', () {
      expect(orderStatusBadgeData('Weird'), ('Weird', TvBadgeVariant.neutral));
    });
  });
}

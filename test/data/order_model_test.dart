import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/order_model.dart';

void main() {
  group('OrderModel.itemCount', () {
    test('đọc trực tiếp itemCount', () {
      final o = OrderModel.fromJson({'id': '1', 'itemCount': 3});
      expect(o.itemCount, 3);
    });
    test('suy ra từ độ dài mảng items/orderDetails', () {
      final o = OrderModel.fromJson({
        'id': '1',
        'orderDetails': [
          {'x': 1},
          {'x': 2}
        ],
      });
      expect(o.itemCount, 2);
    });
    test('không có dữ liệu → null (không bịa)', () {
      final o = OrderModel.fromJson({'id': '1'});
      expect(o.itemCount, isNull);
    });
    test('các field cũ vẫn parse như trước', () {
      final o = OrderModel.fromJson({
        'id': '7',
        'customerName': 'An',
        'totalAmount': 12000,
        'status': 'Pending',
      });
      expect(o.id, '7');
      expect(o.customerName, 'An');
      expect(o.totalAmount, 12000);
      expect(o.status, 'Pending');
    });
  });
}

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

  group('OrderModel.lines (OrderLine)', () {
    test('parse orderDetails camelCase chuẩn BE', () {
      final o = OrderModel.fromJson({
        'id': '1',
        'orderDetails': [
          {
            'productName': 'VGA RTX 4070',
            'brand': 'GIGABYTE',
            'imageUrl': '/uploads/vga.png',
            'quantity': 2,
            'unitPrice': 11500000,
          },
        ],
      });
      expect(o.lines, hasLength(1));
      expect(o.lines.first.productName, 'VGA RTX 4070');
      expect(o.lines.first.brand, 'GIGABYTE');
      expect(o.lines.first.imageUrl, '/uploads/vga.png');
      expect(o.lines.first.quantity, 2);
      expect(o.lines.first.unitPrice, 11500000);
      // itemCount và lines phải nhất quán (cùng nguồn mảng).
      expect(o.itemCount, o.lines.length);
    });
    test('key fallback name/image/qty/price vẫn đọc được', () {
      final o = OrderModel.fromJson({
        'id': '1',
        'items': [
          {'name': 'RAM 32GB', 'image': 'ram.png', 'qty': 3, 'price': 2500000},
        ],
      });
      expect(o.lines.first.productName, 'RAM 32GB');
      expect(o.lines.first.imageUrl, 'ram.png');
      expect(o.lines.first.quantity, 3);
      expect(o.lines.first.unitPrice, 2500000);
    });
    test('không có mảng chi tiết → lines rỗng, không crash', () {
      final o = OrderModel.fromJson({'id': '1', 'itemCount': 5});
      expect(o.lines, isEmpty);
      expect(o.itemCount, 5);
    });
    test('phần tử rác trong mảng bị bỏ qua an toàn', () {
      final o = OrderModel.fromJson({
        'id': '1',
        'orderDetails': [
          'rác',
          {'productName': 'Chuột'},
        ],
      });
      expect(o.lines, hasLength(1));
      expect(o.lines.first.productName, 'Chuột');
      expect(o.lines.first.quantity, 1); // default
    });
  });
}

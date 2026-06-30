import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/order_status.dart';

void main() {
  group('OrderFlow.staffCanStartDelivery', () {
    test('Pending hoặc Confirmed → cho "Bắt đầu giao"', () {
      expect(OrderFlow.staffCanStartDelivery(OrderStatus.pending), isTrue);
      expect(OrderFlow.staffCanStartDelivery(OrderStatus.confirmed), isTrue);
    });
    test('PendingPayment/Shipped/Delivered/Cancelled → không', () {
      expect(
          OrderFlow.staffCanStartDelivery(OrderStatus.pendingPayment), isFalse);
      expect(OrderFlow.staffCanStartDelivery(OrderStatus.shipped), isFalse);
      expect(OrderFlow.staffCanStartDelivery(OrderStatus.delivered), isFalse);
      expect(OrderFlow.staffCanStartDelivery(OrderStatus.cancelled), isFalse);
    });
  });

  group('OrderFlow.isDelivering', () {
    test('chỉ Shipped', () {
      expect(OrderFlow.isDelivering(OrderStatus.shipped), isTrue);
      expect(OrderFlow.isDelivering(OrderStatus.confirmed), isFalse);
      expect(OrderFlow.isDelivering(OrderStatus.delivered), isFalse);
    });
  });

  group('OrderFlow.staffCanCancel', () {
    test('chỉ khi đơn chưa rời kho', () {
      expect(OrderFlow.staffCanCancel(OrderStatus.pending), isTrue);
      expect(OrderFlow.staffCanCancel(OrderStatus.pendingPayment), isTrue);
      expect(OrderFlow.staffCanCancel(OrderStatus.confirmed), isTrue);
      expect(OrderFlow.staffCanCancel(OrderStatus.shipped), isFalse);
      expect(OrderFlow.staffCanCancel(OrderStatus.delivered), isFalse);
      expect(OrderFlow.staffCanCancel(OrderStatus.cancelled), isFalse);
    });
  });

  group('StaffTab.accepts', () {
    test('toDeliver = Pending + Confirmed', () {
      expect(StaffTab.toDeliver.accepts(OrderStatus.pending), isTrue);
      expect(StaffTab.toDeliver.accepts(OrderStatus.confirmed), isTrue);
      expect(StaffTab.toDeliver.accepts(OrderStatus.pendingPayment), isFalse);
      expect(StaffTab.toDeliver.accepts(OrderStatus.shipped), isFalse);
    });
    test('delivering = Shipped', () {
      expect(StaffTab.delivering.accepts(OrderStatus.shipped), isTrue);
      expect(StaffTab.delivering.accepts(OrderStatus.confirmed), isFalse);
    });
    test('done = Delivered + Cancelled', () {
      expect(StaffTab.done.accepts(OrderStatus.delivered), isTrue);
      expect(StaffTab.done.accepts(OrderStatus.cancelled), isTrue);
      expect(StaffTab.done.accepts(OrderStatus.shipped), isFalse);
    });
    test('all nhận mọi trạng thái', () {
      expect(StaffTab.all.accepts(OrderStatus.pending), isTrue);
      expect(StaffTab.all.accepts(OrderStatus.delivered), isTrue);
    });
  });
}

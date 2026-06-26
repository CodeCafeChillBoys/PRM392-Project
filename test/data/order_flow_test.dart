import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/order_status.dart';

void main() {
  group('OrderFlow.staffPrimaryAction', () {
    test('Pending/PendingPayment → Xác nhận đơn (Confirmed)', () {
      for (final s in [OrderStatus.pending, OrderStatus.pendingPayment]) {
        final a = OrderFlow.staffPrimaryAction(s);
        expect(a?.nextStatus, OrderStatus.confirmed);
        expect(a?.label, 'Xác nhận đơn');
      }
    });
    test('Confirmed → Bắt đầu giao (Shipped)', () {
      final a = OrderFlow.staffPrimaryAction(OrderStatus.confirmed);
      expect(a?.nextStatus, OrderStatus.shipped);
      expect(a?.label, 'Bắt đầu giao');
    });
    test('Shipped → KHÔNG có hành động staff (chờ khách) [bug fix]', () {
      expect(OrderFlow.staffPrimaryAction(OrderStatus.shipped), isNull);
    });
    test('Delivered/Cancelled → null', () {
      expect(OrderFlow.staffPrimaryAction(OrderStatus.delivered), isNull);
      expect(OrderFlow.staffPrimaryAction(OrderStatus.cancelled), isNull);
    });
  });

  group('OrderFlow gates', () {
    test('staffCanCancel chỉ khi chưa giao', () {
      expect(OrderFlow.staffCanCancel(OrderStatus.pending), isTrue);
      expect(OrderFlow.staffCanCancel(OrderStatus.pendingPayment), isTrue);
      expect(OrderFlow.staffCanCancel(OrderStatus.confirmed), isTrue);
      expect(OrderFlow.staffCanCancel(OrderStatus.shipped), isFalse);
      expect(OrderFlow.staffCanCancel(OrderStatus.delivered), isFalse);
      expect(OrderFlow.staffCanCancel(OrderStatus.cancelled), isFalse);
    });
    test('isAwaitingCustomer chỉ khi Shipped', () {
      expect(OrderFlow.isAwaitingCustomer(OrderStatus.shipped), isTrue);
      expect(OrderFlow.isAwaitingCustomer(OrderStatus.confirmed), isFalse);
    });
    test('customerCanConfirmReceipt chỉ khi Shipped', () {
      expect(OrderFlow.customerCanConfirmReceipt(OrderStatus.shipped), isTrue);
      expect(OrderFlow.customerCanConfirmReceipt(OrderStatus.delivered), isFalse);
      expect(OrderFlow.customerCanConfirmReceipt(OrderStatus.confirmed), isFalse);
    });
  });

  group('StaffTab.accepts', () {
    test('pending = Pending + PendingPayment', () {
      expect(StaffTab.pending.accepts(OrderStatus.pending), isTrue);
      expect(StaffTab.pending.accepts(OrderStatus.pendingPayment), isTrue);
      expect(StaffTab.pending.accepts(OrderStatus.confirmed), isFalse);
    });
    test('shipping = Confirmed + Shipped', () {
      expect(StaffTab.shipping.accepts(OrderStatus.confirmed), isTrue);
      expect(StaffTab.shipping.accepts(OrderStatus.shipped), isTrue);
      expect(StaffTab.shipping.accepts(OrderStatus.delivered), isFalse);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/order_model.dart';
import 'package:tech_void/data/models/wallet.dart';
import 'package:tech_void/data/models/wallet_transaction.dart';

void main() {
  group('Wallet', () {
    test('fromJson đọc balance dạng số + updatedAt', () {
      final w = Wallet.fromJson({
        'id': 'w1',
        'userId': 'u1',
        'balance': 150000,
        'updatedAt': '2026-07-20T10:00:00Z',
      });
      expect(w.id, 'w1');
      expect(w.userId, 'u1');
      expect(w.balance, 150000.0);
      expect(w.updatedAt, isNotNull);
    });

    test('fromJson chịu được thiếu field', () {
      final w = Wallet.fromJson({});
      expect(w.id, '');
      expect(w.balance, 0.0);
      expect(w.updatedAt, isNull);
    });
  });

  group('WalletTransaction', () {
    WalletTransaction txn(String type) => WalletTransaction.fromJson({
      'id': 't',
      'type': type,
      'status': 'Completed',
      'amount': 50000,
      'createdAt': '2026-07-20T10:00:00Z',
    });

    test('phân loại type + dấu tiền (nạp/hoàn = cộng)', () {
      expect(txn('TopUp').type, WalletTxnType.topUp);
      expect(txn('TopUp').isCredit, true);
      expect(txn('Refund').type, WalletTxnType.refund);
      expect(txn('Refund').isCredit, true);
      expect(txn('Payment').type, WalletTxnType.payment);
      expect(txn('Payment').isCredit, false);
      expect(txn('Withdrawal').type, WalletTxnType.withdrawal);
      expect(txn('Withdrawal').isCredit, false);
    });

    test('type dạng số (enum index) vẫn parse', () {
      expect(txn('0').type, WalletTxnType.topUp);
      expect(txn('3').type, WalletTxnType.refund);
    });

    test('type lạ / thiếu field → unknown, không crash', () {
      final t = WalletTransaction.fromJson({
        'id': 't',
        'type': 'Foo',
        'amount': 1,
      });
      expect(t.type, WalletTxnType.unknown);
      expect(t.isCredit, false);
      expect(t.typeLabel, 'Giao dịch');
    });

    test('mang thông tin ngân hàng khi rút', () {
      final t = WalletTransaction.fromJson({
        'id': 't',
        'type': 'Withdrawal',
        'amount': 100000,
        'bankName': 'Vietcombank',
        'bankAccountNumber': '001234567',
        'accountHolderName': 'NGUYEN VAN A',
        'createdAt': '2026-07-20T10:00:00Z',
      });
      expect(t.bankName, 'Vietcombank');
      expect(t.accountHolderName, 'NGUYEN VAN A');
    });
  });

  group('OrderModel refund', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {
      'id': 'o1',
      'status': 'Delivered',
      'paymentStatus': 'Paid',
      'totalAmount': 100000,
      ...extra,
    };

    test('canRequestRefund true khi giao trong vòng 1 ngày', () {
      final justNow = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final o = OrderModel.fromJson(
        base({'deliveredAt': justNow.toIso8601String()}),
      );
      expect(o.canRequestRefund, true);
      expect(o.refundState, RefundState.none);
    });

    test('canRequestRefund false khi quá 1 ngày', () {
      final old = DateTime.now().toUtc().subtract(const Duration(days: 2));
      final o = OrderModel.fromJson(
        base({'deliveredAt': old.toIso8601String()}),
      );
      expect(o.canRequestRefund, false);
    });

    test('canRequestRefund false khi chưa giao / thiếu deliveredAt', () {
      final o = OrderModel.fromJson(base({'status': 'Shipped'}));
      expect(o.canRequestRefund, false);
    });

    test('refundState suy từ paymentStatus', () {
      final now = DateTime.now().toUtc().toIso8601String();
      final req = OrderModel.fromJson(
        base({'paymentStatus': 'RefundRequested', 'deliveredAt': now}),
      );
      expect(req.refundState, RefundState.requested);
      expect(req.canRequestRefund, false); // đã yêu cầu → không xin lại
      final done = OrderModel.fromJson(base({'paymentStatus': 'Refunded'}));
      expect(done.refundState, RefundState.refunded);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/review.dart';
import 'package:tech_void/data/models/product.dart';

void main() {
  group('Review.fromJson', () {
    test('đọc đủ trường + isMine', () {
      final r = Review.fromJson({
        'id': 'r1',
        'productId': 'p1',
        'customerName': 'Khang',
        'rating': 4,
        'comment': 'Ổn',
        'createdAt': '2026-07-20T00:00:00Z',
        'isMine': true,
      });
      expect(r.id, 'r1');
      expect(r.productId, 'p1');
      expect(r.rating, 4);
      expect(r.customerName, 'Khang');
      expect(r.comment, 'Ổn');
      expect(r.isMine, true);
    });

    test(
      'thiếu comment -> rỗng; isMine mặc định false; tên rỗng -> "Khách"',
      () {
        final r = Review.fromJson({'id': 'r2', 'rating': 5});
        expect(r.comment, '');
        expect(r.isMine, false);
        expect(r.rating, 5);
        expect(r.customerName, 'Khách');
      },
    );
  });

  group('Product rating', () {
    test('đọc averageRating/reviewCount + hasReviews', () {
      final p = Product.fromJson({
        'id': 'p1',
        'name': 'X',
        'brand': 'B',
        'price': 1000,
        'averageRating': 4.5,
        'reviewCount': 8,
      });
      expect(p.averageRating, 4.5);
      expect(p.reviewCount, 8);
      expect(p.hasReviews, true);
    });

    test('thiếu rating -> 0, hasReviews false', () {
      final p = Product.fromJson({'id': 'p2', 'name': 'Y'});
      expect(p.averageRating, 0);
      expect(p.reviewCount, 0);
      expect(p.hasReviews, false);
    });
  });
}

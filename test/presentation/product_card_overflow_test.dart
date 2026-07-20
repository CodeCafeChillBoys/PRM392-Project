import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/product.dart';
import 'package:tech_void/presentation/widgets/product_card.dart';

/// Lưới sản phẩm (`product_list_screen`) dùng ô 2 cột, gutter 20, spacing 14,
/// và `mainAxisExtent` CỐ ĐỊNH (chiều cao ô không co theo bề rộng). Thẻ có thêm
/// DÒNG ĐÁNH GIÁ (sao / "Chưa có đánh giá") nên phải bảo đảm nội dung KHÔNG tràn
/// ô ở mọi bề rộng máy phổ biến — nếu tràn, debug hiện "BOTTOM OVERFLOWED", còn
/// release thì cắt mất phần giá/nút.
void main() {
  const gutter = 20.0; // AppSpacing.gutter
  const crossSpacing = 14.0;
  const mainAxisExtent = 322.0; // PHẢI khớp product_list_screen.dart

  Product product({int reviews = 0}) => Product(
    id: 'p1',
    name: 'Card màn hình ASUS TUF Gaming GeForce RTX 4070 Ti OC 12GB',
    brand: 'ASUS',
    categoryName: 'VGA',
    price: 25990000,
    stockQuantity: 20,
    imageUrl: '', // rỗng → placeholder tĩnh, KHÔNG gọi mạng trong test
    description: '',
    reviewCount: reviews,
    averageRating: reviews > 0 ? 4.5 : 0,
  );

  Future<void> pumpInCell(
    WidgetTester tester,
    double screenWidthDp,
    Product p,
  ) async {
    // Bề rộng ô đúng như GridView tính ra; chiều cao ô = mainAxisExtent (cố định).
    final cardW = (screenWidthDp - 2 * gutter - crossSpacing) / 2;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: cardW,
              height: mainAxisExtent,
              child: ProductCard(product: p, onTap: () {}, onAdd: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Từ máy hẹp (360dp) đến rộng như emulator demo (~427dp). Card cao nhất ở máy
  // rộng nhất (ảnh vuông to nhất) — nên đây là biên trên cần phủ.
  for (final width in [360.0, 390.0, 411.0, 427.0]) {
    final w = width.toInt();
    testWidgets('không tràn ô ở ${w}dp — chưa có đánh giá', (tester) async {
      await pumpInCell(tester, width, product(reviews: 0));
      expect(
        tester.takeException(),
        isNull,
        reason: 'ProductCard tràn ô lưới ở ${w}dp (chưa đánh giá)',
      );
    });

    testWidgets('không tràn ô ở ${w}dp — có đánh giá', (tester) async {
      await pumpInCell(tester, width, product(reviews: 128));
      expect(
        tester.takeException(),
        isNull,
        reason: 'ProductCard tràn ô lưới ở ${w}dp (có đánh giá)',
      );
    });
  }
}

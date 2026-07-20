import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/presentation/screens/auth/login_screen.dart';

/// Màn Login (hero hoà nền + card trắng kéo tới đáy) phải:
/// - KHÔNG overflow ở màn nhỏ / khi nội dung cao hơn viewport (card cuộn);
/// - Trên màn cao: card phủ hết phần còn lại và "Đăng ký ngay" được Spacer
///   đẩy xuống sát đáy card (cách đáy ≈ padding 24, test không có safe-area).
void main() {
  Future<void> pumpAt(WidgetTester tester, Size logical) async {
    tester.view.physicalSize = logical;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump(const Duration(milliseconds: 400)); // fadeIn settle
  }

  testWidgets('không overflow ở màn nhỏ 320x520', (tester) async {
    await pumpAt(tester, const Size(320, 520));
    expect(tester.takeException(), isNull);
  });

  testWidgets('không overflow ở màn 360x640', (tester) async {
    await pumpAt(tester, const Size(360, 640));
    expect(tester.takeException(), isNull);
    // Nội dung cao hơn viewport → Spacer co về 0, card cuộn được tới cuối.
    // (chỉ định scrollable ngoài cùng — mỗi TextField cũng có Scrollable riêng)
    await tester.scrollUntilVisible(
      find.text('Đăng ký ngay'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đăng ký ngay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('màn cao (emulator ~427x952): Đăng ký ngay nằm sát đáy card', (
    tester,
  ) async {
    await pumpAt(tester, const Size(427, 952));
    expect(tester.takeException(), isNull);
    final bottom = tester.getBottomLeft(find.text('Đăng ký ngay')).dy;
    // Card kéo tới đáy màn, dòng đăng ký cách đáy ≈ 24dp → nằm trong 60dp cuối.
    expect(
      bottom,
      greaterThan(952 - 60),
      reason: 'Spacer phải đẩy "Đăng ký ngay" xuống sát đáy card',
    );
  });

  testWidgets('có đủ thành phần đăng nhập', (tester) async {
    await pumpAt(tester, const Size(390, 800));
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    // TvButton in HOA nhãn (label.toUpperCase()).
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP BẰNG GOOGLE'), findsOneWidget);
    expect(find.text('HOẶC'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

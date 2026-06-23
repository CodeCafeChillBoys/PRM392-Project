// Smoke test: the app boots to the login screen without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/main.dart';
import 'package:tech_void/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TechVoidApp());
    // Let the cart controller's mock fetch (and its timer) settle.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TechVoidApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

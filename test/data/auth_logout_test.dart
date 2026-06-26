import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/services/api_client.dart';
import 'package:tech_void/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout xoá toàn bộ session trên client', () async {
    final client = ApiClient()
      ..authToken = 'tok'
      ..userId = '42'
      ..userName = 'An'
      ..userEmail = 'an@techstore.vn'
      ..userRole = 'Staff';
    final auth = AuthService(client: client);

    await auth.logout();

    expect(client.authToken, isNull);
    expect(client.userId, isNull);
    expect(client.userName, isNull);
    expect(client.userEmail, isNull);
    expect(client.userRole, isNull);
  });
}

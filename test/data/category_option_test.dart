import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/data/models/category_option.dart';

void main() {
  group('CategoryOption.fromJson', () {
    test('parse id + name theo CategoryResponseDTO', () {
      final c = CategoryOption.fromJson({
        'id': '7b2e9d3a-1111-2222-3333-444455556666',
        'name': 'Điện thoại',
        'description': 'Smartphone các hãng',
      });
      expect(c.id, '7b2e9d3a-1111-2222-3333-444455556666');
      expect(c.name, 'Điện thoại');
    });

    test('thiếu field → chuỗi rỗng, không crash', () {
      final c = CategoryOption.fromJson(const {});
      expect(c.id, '');
      expect(c.name, '');
    });

    test('id dạng số (phòng BE đổi kiểu) → vẫn thành chuỗi', () {
      final c = CategoryOption.fromJson(const {'id': 5, 'name': 'Laptop'});
      expect(c.id, '5');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/core/utils/formatters.dart';

void main() {
  final now = DateTime(2026, 6, 27, 12, 0, 0);

  group('formatRelativeTime', () {
    test('dưới 1 phút → Vừa xong', () {
      expect(
          formatRelativeTime(now.subtract(const Duration(seconds: 30)),
              now: now),
          'Vừa xong');
    });
    test('phút', () {
      expect(
          formatRelativeTime(now.subtract(const Duration(minutes: 5)),
              now: now),
          '5 phút trước');
    });
    test('giờ', () {
      expect(
          formatRelativeTime(now.subtract(const Duration(hours: 2)), now: now),
          '2 giờ trước');
    });
    test('ngày', () {
      expect(
          formatRelativeTime(now.subtract(const Duration(days: 3)), now: now),
          '3 ngày trước');
    });
    test('quá 7 ngày → dd/MM/yyyy', () {
      expect(formatRelativeTime(DateTime(2026, 6, 1), now: now), '01/06/2026');
    });
    test('thời gian tương lai/âm → Vừa xong', () {
      expect(
          formatRelativeTime(now.add(const Duration(minutes: 5)), now: now),
          'Vừa xong');
    });
  });

  group('formatRelativeFromIso', () {
    test('iso hợp lệ → delegate sang formatRelativeTime', () {
      expect(formatRelativeFromIso('2026-06-27T11:58:00', now: now),
          '2 phút trước');
      expect(formatRelativeFromIso('2026-06-27T11:59:40', now: now), 'Vừa xong');
    });
    test('iso rác → rỗng', () {
      expect(formatRelativeFromIso('not-a-date', now: now), '');
      expect(formatRelativeFromIso('', now: now), '');
    });
  });
}

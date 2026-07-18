import 'package:flutter_test/flutter_test.dart';
import 'package:tech_void/core/utils/formatters.dart';

void main() {
  group('readVietnameseNumber', () {
    final cases = <int, String>{
      0: 'không',
      5: 'năm',
      10: 'mười',
      11: 'mười một',
      15: 'mười lăm',
      20: 'hai mươi',
      21: 'hai mươi mốt',
      25: 'hai mươi lăm',
      100: 'một trăm',
      101: 'một trăm lẻ một',
      105: 'một trăm lẻ năm',
      115: 'một trăm mười lăm',
      121: 'một trăm hai mươi mốt',
      1000: 'một nghìn',
      1005: 'một nghìn không trăm lẻ năm',
      1205: 'một nghìn hai trăm lẻ năm',
      30000: 'ba mươi nghìn',
      100000: 'một trăm nghìn',
      1000000: 'một triệu',
      1000005: 'một triệu không trăm lẻ năm',
      21000000: 'hai mươi mốt triệu',
      30000000: 'ba mươi triệu',
      123456789:
          'một trăm hai mươi ba triệu bốn trăm năm mươi sáu nghìn bảy trăm tám mươi chín',
      1000000000: 'một tỷ',
    };

    cases.forEach((number, expected) {
      test('$number → "$expected"', () {
        expect(readVietnameseNumber(number), expected);
      });
    });

    test('số âm có tiền tố "âm"', () {
      expect(readVietnameseNumber(-5000), 'âm năm nghìn');
    });
  });
}

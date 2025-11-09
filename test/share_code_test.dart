import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/utils/share_code.dart';

void main() {
  group('decodeShareCode', () {
    test('accepts lowercase prefix and dashes', () {
      final s = 'csgo-AAAA-AAAA-AAAA';
      final sc = decodeShareCode(s);
      expect(sc.matchId, BigInt.zero);
      expect(sc.outcomeId, BigInt.zero);
      expect(sc.token, 0);
    });

    test('rejects invalid characters (0 or 1)', () {
      expect(() => decodeShareCode('CSGO-1AAAA-AAAAA'), throwsFormatException);
      expect(() => decodeShareCode('CSGO-0AAAA-AAAAA'), throwsFormatException);
    });
  });
}


class ShareCode {
  final BigInt matchId;
  final BigInt outcomeId;
  final int token; // 16-bit
  const ShareCode({required this.matchId, required this.outcomeId, required this.token});
}

/// Decodes CS:GO/CS2 share codes like `CSGO-XXXX-XXXX-XXXX-XXXX-XXXX`.
/// Returns [ShareCode] with matchId, outcomeId and 16-bit token.
/// Throws [FormatException] if input is invalid.
ShareCode decodeShareCode(String input) {
  if (input.isEmpty) throw const FormatException('Empty share code');
  final alphabet = 'ABCDEFGHJKLMNOPQRSTUVWXYZabcdefhijkmnopqrstuvwxyz23456789';
  final map = {for (var i = 0; i < alphabet.length; i++) alphabet[i]: i};

  var s = input.trim();
  // Be case-insensitive for common prefixes and then strip dashes
  final su = s.toUpperCase();
  if (su.startsWith('CSGO-')) {
    s = s.substring(5);
  } else if (su.startsWith('CS2-')) {
    s = s.substring(4);
  }
  s = s.replaceAll('-', '');
  if (s.isEmpty) throw const FormatException('Invalid share code');

  BigInt acc = BigInt.zero;
  for (final ch in s.split('')) {
    final v = map[ch];
    if (v == null) {
      throw FormatException('Invalid character: $ch');
    }
    acc = acc * BigInt.from(57) + BigInt.from(v);
  }

  // Build 18 bytes (8 + 8 + 2) little-endian buffer
  final bytes = List<int>.filled(18, 0);
  for (int i = 17; i >= 0; i--) {
    bytes[i] = (acc & BigInt.from(0xff)).toInt();
    acc = acc >> 8;
  }

  BigInt readLE64(int offset) {
    BigInt v = BigInt.zero;
    for (int i = 0; i < 8; i++) {
      v |= BigInt.from(bytes[offset + i]) << (8 * i);
    }
    return v;
  }

  int readLE16(int offset) {
    int v = 0;
    for (int i = 0; i < 2; i++) {
      v |= (bytes[offset + i] & 0xff) << (8 * i);
    }
    return v;
  }

  final matchId = readLE64(0);
  final outcomeId = readLE64(8);
  final token = readLE16(16);
  return ShareCode(matchId: matchId, outcomeId: outcomeId, token: token);
}

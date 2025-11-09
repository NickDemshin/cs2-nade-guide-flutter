import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/utils/color_compat.dart'; // ignore: unused_import
import 'package:flutter/material.dart';

void main() {
  test('withValues(alpha) adjusts color alpha channel', () {
    const c = Color(0xFF112233);
    final c2 = c.withValues(alpha: 0.5);
    // Expect alpha ~ 0x80 using non-deprecated channels
    int to8(double v) => (v * 255.0).round() & 0xff;
    expect(to8(c2.a), inInclusiveRange(127, 128));
    expect(to8(c2.r), 0x11);
    expect(to8(c2.g), 0x22);
    expect(to8(c2.b), 0x33);
  });
}

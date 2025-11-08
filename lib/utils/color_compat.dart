import 'package:flutter/material.dart';

// Polyfill for Color.withValues on older Flutter SDKs.
// On newer SDKs, the built-in withValues exists; this extension is unused.
// On older SDKs, we emulate alpha handling via withAlpha to avoid deprecated withOpacity.
extension ColorCompat on Color {
  Color withValues({double? alpha, double? red, double? green, double? blue}) {
    if (alpha != null) {
      final a = (alpha.clamp(0.0, 1.0) * 255).round();
      return withAlpha(a);
    }
    return this;
  }
}

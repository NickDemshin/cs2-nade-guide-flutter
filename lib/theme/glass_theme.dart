import 'package:flutter/material.dart';

class Glass extends ThemeExtension<Glass> {
  final double radius;
  final double blurSigma;
  final Color background;
  final Color border;

  const Glass({
    required this.radius,
    required this.blurSigma,
    required this.background,
    required this.border,
  });

  @override
  ThemeExtension<Glass> copyWith({
    double? radius,
    double? blurSigma,
    Color? background,
    Color? border,
  }) => Glass(
        radius: radius ?? this.radius,
        blurSigma: blurSigma ?? this.blurSigma,
        background: background ?? this.background,
        border: border ?? this.border,
      );

  @override
  ThemeExtension<Glass> lerp(ThemeExtension<Glass>? other, double t) {
    if (other is! Glass) return this;
    return Glass(
      radius: lerpDouble(radius, other.radius, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}


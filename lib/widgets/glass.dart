import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';
import '../utils/color_compat.dart'; // ignore: unused_import

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  const GlassContainer({super.key, required this.child, this.radius = 16, this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<Glass>();
    final r = radius == 16 && ext != null ? ext.radius : radius;
    final bg = ext?.background ?? Colors.white.withValues(alpha: 0.06);
    final border = ext?.border ?? Colors.white.withValues(alpha: 0.12);
    final blur = ext?.blurSigma ?? 14.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassSearchField extends StatelessWidget {
  final String hint;
  final String? initial;
  final ValueChanged<String> onChanged;

  const GlassSearchField({super.key, required this.hint, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initial);
    return GlassContainer(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

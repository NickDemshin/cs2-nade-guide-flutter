import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  const GlassContainer({super.key, required this.child, this.radius = 16, this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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


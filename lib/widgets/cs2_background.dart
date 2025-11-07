import 'package:flutter/material.dart';

// A reusable Counter‑Strike 2 inspired dark background with subtle colored glows
// and vignette. Meant to be placed above MaterialApp via the `builder` so all
// pages inherit the background. Touch events pass through via IgnorePointer.
class Cs2Background extends StatelessWidget {
  final Widget child;
  const Cs2Background({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0F14),
                  Color(0xFF0D1218),
                  Color(0xFF0A0E14),
                ],
              ),
            ),
          ),
        ),
        // Teal glow (CT vibe) from top-left
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF00E5A8).withValues(alpha: 0.18),
                    const Color(0xFF00E5A8).withValues(alpha: 0.00),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Amber glow (T vibe) from bottom-right
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.95, 1.0),
                  radius: 1.2,
                  colors: [
                    const Color(0xFFE6A500).withValues(alpha: 0.16),
                    const Color(0xFFE6A500).withValues(alpha: 0.00),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Soft vignette to darken edges
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.65, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}


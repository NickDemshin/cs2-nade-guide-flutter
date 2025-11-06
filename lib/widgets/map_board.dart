import 'package:flutter/material.dart';

import '../models/nade.dart';

class MapBoard extends StatelessWidget {
  final List<Nade> nades;
  final Nade? selected;
  final ValueChanged<Nade> onSelect;
  final bool showGrid;
  final String? imageAsset; // фоновое изображение карты
  final Set<String>? favoriteIds; // набор избранных ID для визуальной пометки

  const MapBoard({
    super.key,
    required this.nades,
    required this.onSelect,
    this.selected,
    this.showGrid = true,
    this.imageAsset,
    this.favoriteIds,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Фон: изображение карты если задано, иначе тёмный фон
              Positioned.fill(
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(color: const Color(0xFF1E1E1E)),
                      )
                    : Container(color: const Color(0xFF1E1E1E)),
              ),
              // Лёгкая сетка поверх фона (для ориентира)
              if (showGrid) CustomPaint(painter: _GridPainter()),

              // Линия от from -> to для выбранной гранаты
              if (selected != null)
                CustomPaint(
                  painter: _LinePainter(
                    from: Offset(selected!.fromX * w, selected!.fromY * h),
                    to: Offset(selected!.toX * w, selected!.toY * h),
                  ),
                ),

              // Все точки приземления (to)
              ...nades.map((n) {
                final x = n.toX * w;
                final y = n.toY * h;
                final isSel = n.id == selected?.id;
                final isFav = favoriteIds?.contains(n.id) ?? false;
                return Positioned(
                  left: x - 10,
                  top: y - 10,
                  child: _Marker(
                    color: _typeColor(n.type),
                    label: nadeTypeLabel(n.type)[0],
                    selected: isSel,
                    favorite: isFav,
                    onTap: () => onSelect(n),
                  ),
                );
              }),

              // Точка старта броска для выбранной
              if (selected != null)
                Positioned(
                  left: selected!.fromX * w - 10,
                  top: selected!.fromY * h - 10,
                  child: _Marker(
                    color: Colors.amber,
                    label: 'S',
                    selected: true,
                    onTap: () {},
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _typeColor(NadeType t) {
    switch (t) {
      case NadeType.smoke:
        return Colors.grey;
      case NadeType.flash:
        return Colors.lightBlue;
      case NadeType.molotov:
        return Colors.deepOrange;
      case NadeType.he:
        return Colors.green;
    }
  }
}

class _Marker extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool favorite;

  const _Marker({
    required this.color,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.favorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = favorite ? Colors.pinkAccent : Colors.white;
    final borderWidth = favorite ? 3.0 : 2.0;
    final size = selected ? 24.0 : 20.0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (favorite)
            const Positioned(
              right: -6,
              top: -6,
              child: Icon(Icons.star, color: Colors.pinkAccent, size: 12),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Offset.zero & size, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinePainter extends CustomPainter {
  final Offset from;
  final Offset to;

  _LinePainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, line);

    final dot = Paint()..color = Colors.amber;
    canvas.drawCircle(from, 4, dot);
    canvas.drawCircle(to, 4, dot);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.from != from || old.to != to;
}

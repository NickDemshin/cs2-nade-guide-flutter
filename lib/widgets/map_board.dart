import 'package:flutter/material.dart';

import '../models/nade.dart';

class MapBoard extends StatefulWidget {
  final List<Nade> nades;
  final Nade? selected;
  final ValueChanged<Nade> onSelect;
  final bool showGrid;
  final String? imageAsset; // фоновое изображение карты
  final Set<String>? favoriteIds; // набор избранных ID для визуальной пометки
  final ValueChanged<Offset>? onLongPressRelative; // нормированные координаты 0..1
  final ValueChanged<Offset>? onDoubleTapLocal; // локальная позиция double-tap

  const MapBoard({
    super.key,
    required this.nades,
    required this.onSelect,
    this.selected,
    this.showGrid = true,
    this.imageAsset,
    this.favoriteIds,
    this.onLongPressRelative,
    this.onDoubleTapLocal,
  });

  @override
  State<MapBoard> createState() => _MapBoardState();
}

class _MapBoardState extends State<MapBoard> {
  Size? _imageSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant MapBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset != widget.imageAsset) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    _imageSize = null;
    _removeImageListener();
    if (widget.imageAsset == null) return;
    final provider = AssetImage(widget.imageAsset!);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    });
    stream.addListener(_listener!);
    _stream = stream;
  }

  void _removeImageListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasImage = widget.imageAsset != null;
        final aspect = (_imageSize != null && _imageSize!.height != 0)
            ? (_imageSize!.width / _imageSize!.height)
            : 1.0;

        // Fit image into available box preserving aspect (contain)
        double maxW = constraints.maxWidth;
        double maxH = constraints.maxHeight;
        if (!maxW.isFinite) maxW = 300; // безопасный дефолт
        if (!maxH.isFinite) maxH = 300;
        double w = maxW;
        double h = w / aspect;
        if (h > maxH) {
          h = maxH;
          w = h * aspect;
        }
        final canvasW = w;
        final canvasH = h;

        return Center(
          child: SizedBox(
            width: canvasW,
            height: canvasH,
            child: GestureDetector(
              onLongPressStart: (details) {
                if (widget.onLongPressRelative == null) return;
                final local = details.localPosition;
                final nx = (local.dx / canvasW).clamp(0.0, 1.0);
                final ny = (local.dy / canvasH).clamp(0.0, 1.0);
                widget.onLongPressRelative!(Offset(nx, ny));
              },
              onDoubleTapDown: (details) {
                if (widget.onDoubleTapLocal != null) {
                  widget.onDoubleTapLocal!(details.localPosition);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Фон: изображение карты если задано, иначе тёмный фон
                  Positioned.fill(
                    child: hasImage
                        ? Image.asset(
                            widget.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(color: const Color(0xFF1E1E1E)),
                          )
                        : Container(color: const Color(0xFF1E1E1E)),
                  ),
                  // Лёгкая сетка поверх фона (для ориентира)
                  if (widget.showGrid) CustomPaint(painter: _GridPainter()),

                  // Линия от from -> to для выбранной гранаты
                  if (widget.selected != null)
                    CustomPaint(
                      painter: _LinePainter(
                        from: Offset(widget.selected!.fromX * canvasW, widget.selected!.fromY * canvasH),
                        to: Offset(widget.selected!.toX * canvasW, widget.selected!.toY * canvasH),
                      ),
                    ),

                  // Все точки приземления (to)
                  ...widget.nades.map((n) {
                    final x = n.toX * canvasW;
                    final y = n.toY * canvasH;
                    final isSel = n.id == widget.selected?.id;
                    final isFav = widget.favoriteIds?.contains(n.id) ?? false;
                    return Positioned(
                      left: x - 10,
                      top: y - 10,
                      child: Tooltip(
                        message: '${nadeTypeLabel(n.type)}: ${n.title}',
                        child: _Marker(
                          color: _typeColor(n.type),
                          label: nadeTypeLabel(n.type)[0],
                          selected: isSel,
                          favorite: isFav,
                          onTap: () => widget.onSelect(n),
                        ),
                      ),
                    );
                  }),

                  // Точка старта броска для выбранной
                  if (widget.selected != null)
                    Positioned(
                      left: widget.selected!.fromX * canvasW - 10,
                      top: widget.selected!.fromY * canvasH - 10,
                      child: _Marker(
                        color: Colors.amber,
                        label: 'S',
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
              color: color.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
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
      ..color = Colors.white.withOpacity(0.35)
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../models/nade.dart';

class MapBoard extends StatefulWidget {
  final List<Nade> nades;
  final Nade? selected;
  final ValueChanged<Nade> onSelect;
  final bool showGrid;
  final String? imageAsset; // фоновое изображение карты
  final Set<String>? favoriteIds; // набор избранных ID для визуальной пометки
  final ValueChanged<Offset>? onLongPressRelative; // нормированные координаты 0..1
  final ValueChanged<Offset>? onTapRelative; // нормированные координаты 0..1 (для выбора точки)
  final ValueChanged<Offset>? onDoubleTapLocal; // локальная позиция double-tap
  final double scale; // текущий масштаб из InteractiveViewer
  final String Function(NadeType)? typeLabel; // локализованные подписи типов
  final bool colorBlindFriendly; // альтернативная палитра цветов
  final Offset? tempTo; // временная точка приземления (0..1)
  final Offset? tempFrom; // временная точка броска (0..1)
  final bool showLegend;

  const MapBoard({
    super.key,
    required this.nades,
    required this.onSelect,
    this.selected,
    this.showGrid = true,
    this.imageAsset,
    this.favoriteIds,
    this.onLongPressRelative,
    this.onTapRelative,
    this.onDoubleTapLocal,
    this.scale = 1.0,
    this.typeLabel,
    this.colorBlindFriendly = false,
    this.tempTo,
    this.tempFrom,
    this.showLegend = true,
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

        // Построить кластеры по близости (в пикселях) и типу гранаты
        final clusters = _buildClusters(canvasW, canvasH, widget.nades);

        return Center(
          child: SizedBox(
            width: canvasW,
            height: canvasH,
            child: GestureDetector(
              onTapDown: (details) {
                if (widget.onTapRelative != null) {
                  final local = details.localPosition;
                  final nx = (local.dx / canvasW).clamp(0.0, 1.0);
                  final ny = (local.dy / canvasH).clamp(0.0, 1.0);
                  widget.onTapRelative!(Offset(nx, ny));
                }
              },
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
                  RepaintBoundary(
                    child: Positioned.fill(
                      child: hasImage
                          ? Image.asset(
                              widget.imageAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(color: const Color(0xFF1E1E1E)),
                            )
                          : Container(color: const Color(0xFF1E1E1E)),
                    ),
                  ),
                  // Лёгкая сетка поверх фона (для ориентира)
                  if (widget.showGrid) RepaintBoundary(child: CustomPaint(painter: _GridPainter())),

                  // Линия от from -> to для выбранной гранаты
                  if (widget.selected != null)
                    CustomPaint(
                      painter: _LinePainter(
                        from: Offset(widget.selected!.fromX * canvasW, widget.selected!.fromY * canvasH),
                        to: Offset(widget.selected!.toX * canvasW, widget.selected!.toY * canvasH),
                      ),
                    ),

                  // Кластеры точек приземления (to)
                  ...clusters.map((c) {
                    final x = c.center.dx;
                    final y = c.center.dy;
                    if (c.items.length == 1) {
                      final n = c.items.first;
                      final isSel = n.id == widget.selected?.id;
                      final isFav = widget.favoriteIds?.contains(n.id) ?? false;
                      return Positioned(
                        left: x - 10,
                        top: y - 10,
                        child: Tooltip(
                          message: '${(widget.typeLabel?.call(n.type) ?? nadeTypeLabel(n.type))}: ${n.title}',
                          child: Semantics(
                            label: '${(widget.typeLabel?.call(n.type) ?? nadeTypeLabel(n.type))}: ${n.title}',
                            button: true,
                          child: _Marker(
                            color: _typeColor(n.type),
                            shape: _typeShape(n.type),
                            icon: _typeIcon(n.type),
                            selected: isSel,
                            scale: widget.scale,
                            favorite: isFav,
                            onTap: () => widget.onSelect(n),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Кластер из нескольких гранат одного типа
                      return Positioned(
                        left: x - 12,
                        top: y - 12,
                        child: Tooltip(
                          message: '${(widget.typeLabel?.call(c.type) ?? nadeTypeLabel(c.type))} × ${c.items.length}',
                          child: Semantics(
                            label: (widget.typeLabel?.call(c.type) ?? nadeTypeLabel(c.type)),
                            button: true,
                            child: _ClusterMarker(
                              color: _typeColor(c.type),
                              icon: _typeIcon(c.type),
                              scale: widget.scale,
                              onTap: () => _openClusterPopover(context, c),
                            ),
                          ),
                        ),
                      );
                    }
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
                        scale: widget.scale,
                        onTap: () {},
                      ),
                    ),

                  // Временные точки предпросмотра
                  if (widget.tempTo != null)
                    Positioned(
                      left: widget.tempTo!.dx * canvasW - 8,
                      top: widget.tempTo!.dy * canvasH - 8,
                      child: _Marker(
                        color: Colors.cyan,
                        shape: _MarkerShape.circle,
                        icon: Icons.my_location,
                        scale: widget.scale,
                        onTap: () {},
                      ),
                    ),
                  if (widget.tempFrom != null)
                    Positioned(
                      left: widget.tempFrom!.dx * canvasW - 8,
                      top: widget.tempFrom!.dy * canvasH - 8,
                      child: _Marker(
                        color: Colors.cyanAccent,
                        shape: _MarkerShape.circle,
                        icon: Icons.my_location_outlined,
                        scale: widget.scale,
                        onTap: () {},
                      ),
                    ),

                  // Легенда типов — стеклянная панель с чипами
                  if (widget.showLegend)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final t in _presentTypes(widget.nades)) ...[
                              _TypeChip(
                                icon: _typeIcon(t),
                                label: (widget.typeLabel?.call(t) ?? nadeTypeLabel(t)),
                                color: _typeColor(t),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
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

  Iterable<NadeType> _presentTypes(List<Nade> nades) {
    final set = <NadeType>{};
    for (final n in nades) {
      set.add(n.type);
    }
    return set;
  }

  // Кластеризуем точки по радиусу в пикселях и типу гранаты
  List<_Cluster> _buildClusters(double canvasW, double canvasH, List<Nade> nades) {
    const double radiusPx = 24.0; // радиус объединения по расстоянию в пикселях
    final List<_Cluster> result = [];
    for (final n in nades) {
      final p = Offset(n.toX * canvasW, n.toY * canvasH);
      _Cluster? found;
      double bestDist2 = double.infinity;
      for (final c in result) {
        if (c.type != n.type) continue; // объединяем только одинаковые типы
        final d2 = (c.center - p).distanceSquared;
        if (d2 <= radiusPx * radiusPx && d2 < bestDist2) {
          found = c;
          bestDist2 = d2;
        }
      }
      if (found == null) {
        result.add(_Cluster(type: n.type, center: p, items: [n]));
      } else {
        // обновим центр как среднее (простое инкрементальное)
        final m = found.items.length.toDouble();
        found.center = Offset(
          (found.center.dx * m + p.dx) / (m + 1),
          (found.center.dy * m + p.dy) / (m + 1),
        );
        found.items.add(n);
      }
    }
    return result;
  }

    void _openClusterPopover(BuildContext context, _Cluster c) async {
    if (c.items.length == 1) {
      widget.onSelect(c.items.first);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final global = box.localToGlobal(c.center);
    final selected = await showMenu<Nade>(
      context: context,
      position: RelativeRect.fromLTRB(global.dx, global.dy, global.dx, global.dy),
      items: [
        for (final n in c.items)
          PopupMenuItem<Nade>(
            value: n,
            child: Row(
              children: [
                Icon(_typeIcon(c.type), color: _typeColor(c.type)),
                const SizedBox(width: 8),
                Expanded(child: Text(n.title, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );
    if (selected != null) {
      widget.onSelect(selected);
    }
  }
  Color _typeColor(NadeType t) {
    if (widget.colorBlindFriendly) {
      switch (t) {
        case NadeType.smoke:
          return const Color(0xFF7F7F7F); // gray
        case NadeType.flash:
          return const Color(0xFF0072B2); // blue
        case NadeType.molotov:
          return const Color(0xFFE69F00); // orange
        case NadeType.he:
          return const Color(0xFFCC79A7); // magenta
      }
    }
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

  _MarkerShape _typeShape(NadeType t) {
    switch (t) {
      case NadeType.smoke:
        return _MarkerShape.circle;
      case NadeType.flash:
        return _MarkerShape.square;
      case NadeType.molotov:
        return _MarkerShape.diamond;
      case NadeType.he:
        return _MarkerShape.triangle;
    }
  }

  IconData _typeIcon(NadeType t) {
    switch (t) {
      case NadeType.smoke:
        return Icons.cloud;
      case NadeType.flash:
        return Icons.flash_on;
      case NadeType.molotov:
        return Icons.local_fire_department;
      case NadeType.he:
        return Icons.bubble_chart; // условный значок для HE
    }
  }
}

class _Cluster {
  final NadeType type;
  final List<Nade> items;
  Offset center;
  _Cluster({required this.type, required this.center, required this.items});
}

class _ClusterMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final double scale;

  const _ClusterMarker({
    required this.color,
    required this.icon,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final inv = scale <= 0 ? 1.0 : (1.0 / scale);
    final size = (22.0 * inv).clamp(12.0, 28.0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.white, width: 2.0),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: (size * 0.58).clamp(10.0, 16.0)),
      ),
    );
  }
}

enum _MarkerShape { circle, square, diamond, triangle }

class _Marker extends StatelessWidget {
  final Color color;
  final String? label;
  final IconData? icon;
  final _MarkerShape shape;
  final VoidCallback onTap;
  final bool selected;
  final bool favorite;
  final double scale;

  const _Marker({
    required this.color,
    this.label,
    this.icon,
    this.shape = _MarkerShape.circle,
    required this.onTap,
    this.selected = false,
    this.favorite = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = favorite ? Colors.pinkAccent : Colors.white;
    final borderWidth = favorite ? 3.0 : 2.0;
    final base = selected ? 24.0 : 20.0;
    final inv = scale <= 0 ? 1.0 : (1.0 / scale);
    final size = (base * inv).clamp(12.0, 28.0);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: _buildShape(size, borderColor, borderWidth),
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

  Widget _buildShape(double size, Color borderColor, double borderWidth) {
    final child = icon != null
        ? Icon(icon, color: Colors.white, size: (size * 0.58).clamp(10.0, 16.0))
        : Text(
            label ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          );

    final commonShadow = [
      if (selected)
        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, spreadRadius: 1),
    ];

    switch (shape) {
      case _MarkerShape.circle:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: commonShadow,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: child,
        );
      case _MarkerShape.square:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            boxShadow: commonShadow,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: child,
        );
      case _MarkerShape.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
              boxShadow: commonShadow,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            alignment: Alignment.center,
            child: Transform.rotate(angle: -math.pi / 4, child: child),
          ),
        );
      case _MarkerShape.triangle:
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _TriangleMarkerPainter(
                  fill: color.withValues(alpha: 0.9),
                  border: borderColor,
                  borderWidth: borderWidth,
                  shadow: selected,
                ),
              ),
              child,
            ],
          ),
        );
    }
  }
}

// Небольшая стеклянная панель с блюром и полупрозрачным фоном — для легенд/панелей.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    const double _radius = 16;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Чип для типа гранаты в стиле макета: компактный, с иконкой и ярким цветом типа.
class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleMarkerPainter extends CustomPainter {
  final Color fill;
  final Color border;
  final double borderWidth;
  final bool shadow;
  _TriangleMarkerPainter({required this.fill, required this.border, required this.borderWidth, this.shadow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w / 2, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    if (shadow) {
      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.25), 4, false);
    }

    final fillPaint = Paint()..color = fill;
    final borderPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TriangleMarkerPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x1AFFFFFF)
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



import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../data/nades_repository.dart';
import '../models/cs_map.dart';
import '../models/nade.dart';
import '../widgets/map_board.dart';
import '../l10n/app_localizations.dart';
import 'nade_detail_page.dart';

class _Matrix4Tween extends Tween<vmath.Matrix4> {
  _Matrix4Tween({required vmath.Matrix4 begin, required vmath.Matrix4 end})
      : super(begin: begin, end: end);

  @override
  vmath.Matrix4 lerp(double t) {
    final b = begin!;
    final e = end!;
    final r = vmath.Matrix4.zero();
    final bs = b.storage;
    final es = e.storage;
    final rs = r.storage;
    for (int i = 0; i < 16; i++) {
      rs[i] = bs[i] + (es[i] - bs[i]) * t;
    }
    return r;
  }
}

class MapPage extends StatefulWidget {
  final CsMap map;
  const MapPage({super.key, required this.map});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final _repo = const NadesRepository();
  late Future<List<Nade>> _futureNades;

  NadeType? _filterType; // null = все
  String? _filterSide; // null = все, иначе 'T' | 'CT' | 'Both'
  Nade? _selected;
  final _transform = TransformationController();
  final _viewerKey = GlobalKey();
  final _boardKey = GlobalKey();
  late final AnimationController _zoomController;
  Animation<vmath.Matrix4>? _zoomAnimation;
  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;
  bool _showGrid = true;
  bool _onlyFavorites = false;
  final Set<String> _favorites = <String>{};
  bool _coordMode = false;
  bool _cbFriendly = false;

  @override
  void initState() {
    super.initState();
    _futureNades = _repo.getNadesByMap(widget.map.id);
    _loadUiPrefs();
    _loadFavorites();
    _transform.addListener(_onTransformChanged);
    _zoomController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() {
        final anim = _zoomAnimation;
        if (anim != null) {
          _transform.value = anim.value;
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.map.image != null) {
      precacheImage(AssetImage(widget.map.image!), context);
    }
  }

  @override
  void dispose() {
    _saveTransformPrefs();
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    // Можно добавить дебаунс при желании
  }

  void _zoomAt(Offset focalLocal, {double factor = 2.0}) {
    final m0 = _transform.value;
    final s0 = m0.getMaxScaleOnAxis();
    final s1 = (s0 * factor).clamp(_minScale, _maxScale).toDouble();
    if (s1 == s0) return;
    final tx0 = m0.storage[12];
    final ty0 = m0.storage[13];
    final fx = focalLocal.dx;
    final fy = focalLocal.dy;
    // Keep the focal point under the same viewport pixel: s0*fx + tx0 == s1*fx + t1
    final t1x = tx0 + fx * (s0 - s1);
    final t1y = ty0 + fy * (s0 - s1);
    final m1 = vmath.Matrix4.identity()
      ..translate(t1x, t1y)
      ..scale(s1);
    _animateTransform(m1);
  }

  void _animateTransform(vmath.Matrix4 target) {
    final begin = _transform.value.clone();
    _zoomAnimation = _Matrix4Tween(begin: begin, end: target)
        .animate(CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic));
    _zoomController
      ..reset()
      ..forward();
  }

  void _zoomToNade(Nade n, {double targetScale = 2.5}) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null || viewerBox == null) return;
    final boardSize = boardBox.size;
    final viewSize = viewerBox.size;
    final s1 = targetScale.clamp(_minScale, _maxScale).toDouble();
    final childPoint = Offset(n.toX * boardSize.width, n.toY * boardSize.height);
    final center = Offset(viewSize.width / 2, viewSize.height / 2);
    final t1x = center.dx - s1 * childPoint.dx;
    final t1y = center.dy - s1 * childPoint.dy;
    final target = vmath.Matrix4.identity()
      ..translate(t1x, t1y)
      ..scale(s1);
    _animateTransform(target);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.nadesForMapTitle(widget.map.name)),
        actions: [
          if (_selected != null)
            IconButton(
              tooltip: l.showAll,
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selected = null),
            ),
          IconButton(
            tooltip: _onlyFavorites ? l.showAll : l.showOnlyFavorites,
            icon: Icon(_onlyFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() => _onlyFavorites = !_onlyFavorites);
              _saveUiPrefs();
            },
          ),
          IconButton(
            tooltip: _showGrid ? l.hideGrid : l.showGrid,
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () {
              setState(() => _showGrid = !_showGrid);
              _saveUiPrefs();
            },
          ),
          IconButton(
            tooltip: _coordMode ? l.coordinatesOn : l.coordinatesOff,
            icon: Icon(_coordMode ? Icons.my_location : Icons.location_searching),
            onPressed: () => setState(() => _coordMode = !_coordMode),
          ),
          IconButton(
            tooltip: l.colorBlindPalette,
            icon: Icon(_cbFriendly ? Icons.visibility : Icons.visibility_outlined),
            onPressed: () {
              setState(() => _cbFriendly = !_cbFriendly);
              _saveUiPrefs();
            },
          ),
          IconButton(
            tooltip: l.resetZoom,
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              setState(() {
                _transform.value = vmath.Matrix4.identity();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Nade>>(
        future: _futureNades,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.errorLoading(snapshot.error.toString())),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _futureNades = _repo.getNadesByMap(widget.map.id);
                      }),
                      icon: const Icon(Icons.refresh),
                      label: Text(l.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          var nades = snapshot.data ?? const <Nade>[];
          if (_filterType != null) {
            nades = nades.where((n) => n.type == _filterType).toList();
          }
          if (_filterSide != null) {
            nades = nades.where((n) => n.side == _filterSide).toList();
          }
          if (_onlyFavorites) {
            nades = nades.where((n) => _favorites.contains(n.id)).toList();
          }

          return Column(
            children: [
              _FilterBar(
                selected: _filterType,
                onSelected: (t) {
                  setState(() {
                    _filterType = t;
                    _selected = null;
                  });
                  _saveUiPrefs();
                },
              ),
              _SideFilterBar(
                selected: _filterSide,
                onSelected: (s) {
                  setState(() {
                    _filterSide = s;
                    _selected = null;
                  });
                  _saveUiPrefs();
                },
              ),
              _LegendBar(),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: InteractiveViewer(
                    key: _viewerKey,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    boundaryMargin: const EdgeInsets.all(80),
                    clipBehavior: Clip.none,
                    transformationController: _transform,
                    onInteractionEnd: (_) => _saveTransformPrefs(),
                    child: MapBoard(
                      key: _boardKey,
                      nades: nades,
                      selected: _selected,
                      onSelect: (n) => setState(() {
                        _selected = (_selected?.id == n.id) ? null : n;
                        if (_selected != null) {
                          // Запустить анимированный зум к выбранной точке на следующем кадре
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted || _selected == null) return;
                            _zoomToNade(_selected!);
                          });
                        }
                      }),
                      imageAsset: widget.map.image,
                      favoriteIds: _favorites,
                      showGrid: _showGrid,
                      scale: _transform.value.getMaxScaleOnAxis(),
                      typeLabel: (t) {
                        switch (t) {
                          case NadeType.smoke:
                            return l.typeSmoke;
                          case NadeType.flash:
                            return l.typeFlash;
                          case NadeType.molotov:
                            return l.typeMolotov;
                          case NadeType.he:
                            return l.typeHE;
                        }
                      },
                      colorBlindFriendly: _cbFriendly,
                      onLongPressRelative: _coordMode
                          ? (pos) {
                            final text = 'x: ${pos.dx.toStringAsFixed(3)}, y: ${pos.dy.toStringAsFixed(3)}';
                            Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.copiedCoords(text))),
                              );
                            }
                          }
                          : null,
                      onDoubleTapLocal: (pos) {
                        final s = _transform.value.getMaxScaleOnAxis();
                        if (s >= 2.5) {
                          setState(() => _transform.value = vmath.Matrix4.identity());
                        } else {
                          _zoomAt(pos, factor: 2.0);
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (_selected != null)
                _SelectedInfo(
                  nade: _selected!,
                  isFavorite: _favorites.contains(_selected!.id),
                  onToggleFavorite: () => _toggleFavorite(_selected!),
                  onOpenDetails: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NadeDetailPage(nade: _selected!),
                      ),
                    );
                  },
                ),
              if (_selected == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _coordMode ? l.coordModeHint : l.selectHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
          ],
        );
      },
    ),
  );
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites_${_mapKey()}') ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _favorites
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _loadUiPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _mapKey();
    final idx = prefs.getInt('ui_${key}_filterType');
    final sg = prefs.getBool('ui_${key}_showGrid');
    final favOnly = prefs.getBool('ui_${key}_onlyFavorites');
    final sideIdx = prefs.getInt('ui_${key}_filterSide');
    final scale = prefs.getDouble('ui_${key}_scale');
    final tx = prefs.getDouble('ui_${key}_tx');
    final ty = prefs.getDouble('ui_${key}_ty');
    final cb = prefs.getBool('ui_${key}_cbFriendly');
    if (!mounted) return;
    setState(() {
      if (idx != null && idx >= 0 && idx < NadeType.values.length) {
        _filterType = NadeType.values[idx];
      } else {
        _filterType = null;
      }
      if (sg != null) _showGrid = sg;
      if (favOnly != null) _onlyFavorites = favOnly;
      if (sideIdx != null) {
        switch (sideIdx) {
          case 0:
            _filterSide = 'T';
            break;
          case 1:
            _filterSide = 'CT';
            break;
          case 2:
            _filterSide = 'Both';
            break;
          default:
            _filterSide = null;
        }
      }
      if (cb != null) _cbFriendly = cb;
      if (scale != null && tx != null && ty != null) {
        final m = vmath.Matrix4.identity()
          ..translate(tx, ty)
          ..scale(scale);
        _transform.value = m;
      }
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites_${_mapKey()}', _favorites.toList());
  }

  Future<void> _saveUiPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _mapKey();
    final idx = _filterType == null ? -1 : NadeType.values.indexOf(_filterType!);
    await prefs.setInt('ui_${key}_filterType', idx);
    await prefs.setBool('ui_${key}_showGrid', _showGrid);
    await prefs.setBool('ui_${key}_onlyFavorites', _onlyFavorites);
    int sideIdx;
    if (_filterSide == 'T') {
      sideIdx = 0;
    } else if (_filterSide == 'CT') {
      sideIdx = 1;
    } else if (_filterSide == 'Both') {
      sideIdx = 2;
    } else {
      sideIdx = -1;
    }
    await prefs.setInt('ui_${key}_filterSide', sideIdx);
    await prefs.setBool('ui_${key}_cbFriendly', _cbFriendly);
  }

  Future<void> _saveTransformPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _mapKey();
    final m = _transform.value;
    final scale = m.getMaxScaleOnAxis();
    final dx = m.storage[12];
    final dy = m.storage[13];
    await prefs.setDouble('ui_${key}_scale', scale);
    await prefs.setDouble('ui_${key}_tx', dx);
    await prefs.setDouble('ui_${key}_ty', dy);
  }

  String _mapKey() => widget.map.id;

  void _toggleFavorite(Nade n) {
    setState(() {
      if (_favorites.contains(n.id)) {
        _favorites.remove(n.id);
      } else {
        _favorites.add(n.id);
      }
    });
    _saveFavorites();
  }
}

class _FilterBar extends StatelessWidget {
  final NadeType? selected;
  final ValueChanged<NadeType?> onSelected;
  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final types = [null, ...NadeType.values];
    String label(NadeType? t) {
      if (t == null) return l.filterAll;
      switch (t) {
        case NadeType.smoke:
          return l.typeSmoke;
        case NadeType.flash:
          return l.typeFlash;
        case NadeType.molotov:
          return l.typeMolotov;
        case NadeType.he:
          return l.typeHE;
      }
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final t = types[index];
          final isSel = selected == t;
          return ChoiceChip(
            label: Text(label(t)),
            selected: isSel,
            onSelected: (_) => onSelected(t),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: types.length,
      ),
    );
  }
}

class _SideFilterBar extends StatelessWidget {
  final String? selected; // null | 'T' | 'CT' | 'Both'
  final ValueChanged<String?> onSelected;
  const _SideFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <String?>[null, 'T', 'CT', 'Both'];
    String label(String? s) {
      if (s == null) return l.sideAll;
      if (s == 'T') return l.sideT;
      if (s == 'CT') return l.sideCT;
      if (s == 'Both') return l.sideBoth;
      return s;
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final v = items[index];
          final isSel = selected == v;
          return ChoiceChip(
            label: Text(label(v)),
            selected: isSel,
            onSelected: (_) => onSelected(v),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color typeColor(NadeType t) {
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

    Widget dot(Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(children: [dot(typeColor(NadeType.smoke)), const SizedBox(width: 6), Text(l.typeSmoke)]),
          Row(children: [dot(typeColor(NadeType.flash)), const SizedBox(width: 6), Text(l.typeFlash)]),
          Row(children: [dot(typeColor(NadeType.molotov)), const SizedBox(width: 6), Text(l.typeMolotov)]),
          Row(children: [dot(typeColor(NadeType.he)), const SizedBox(width: 6), Text(l.typeHE)]),
        ],
      ),
    );
  }
}

class _SelectedInfo extends StatelessWidget {
  final Nade nade;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenDetails;
  const _SelectedInfo({
    required this.nade,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(nade.title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: isFavorite ? l.showAll : l.showOnlyFavorites,
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                    onPressed: onToggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(_typeLabel(context, nade.type))),
                  Chip(label: Text(l.sideLabel(nade.side))),
                  Chip(label: Text(l.techniqueLabel(nade.technique))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Откуда бросать: ${nade.from}'),
              Text('Куда прилетает: ${nade.to}'),
              if (_localizedDescription(context, nade) != null && _localizedDescription(context, nade)!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_localizedDescription(context, nade)!),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: Text(l.details),
                    onPressed: onOpenDetails,
                  ),
                  const SizedBox(width: 8),
                  if (nade.videoUrl != null && nade.videoUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l.openVideo),
                      onPressed: () => _openVideo(context, nade.videoUrl!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openVideo(BuildContext context, String url) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null) throw 'Некорректная ссылка';
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при открытии ссылки')),
      );
    }
  }
}

String _typeLabel(BuildContext context, NadeType t) {
    final l = AppLocalizations.of(context);
  switch (t) {
    case NadeType.smoke:
      return l.typeSmoke;
    case NadeType.flash:
      return l.typeFlash;
    case NadeType.molotov:
      return l.typeMolotov;
    case NadeType.he:
      return l.typeHE;
  }
}

String? _localizedDescription(BuildContext context, Nade n) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'en') {
    if (n.descriptionEn != null && n.descriptionEn!.isNotEmpty) return n.descriptionEn;
  } else if (locale.languageCode == 'ru') {
    if (n.descriptionRu != null && n.descriptionRu!.isNotEmpty) return n.descriptionRu;
  }
  return n.description;
}

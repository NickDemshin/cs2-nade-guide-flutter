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
import '../l10n/nade_type_l10n.dart';
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
  _PickMode _pickMode = _PickMode.none;
  double? _formToX, _formToY, _formFromX, _formFromY;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.filter_alt),
                    onPressed: _openTypeFilterSheet,
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _filterType == null ? l.filterAll : l.typeName(_filterType!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.shield),
                    onPressed: _openSideFilterSheet,
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_filterSide == null
                          ? l.sideAll
                          : (_filterSide == 'T'
                              ? l.sideT
                              : _filterSide == 'CT'
                                  ? l.sideCT
                                  : l.sideBoth)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Stack(
                    children: [
                      InteractiveViewer(
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
                          onTapRelative: _pickMode == _PickMode.none
                              ? null
                              : (pos) {
                                  setState(() {
                                    if (_pickMode == _PickMode.toPoint) {
                                      _formToX = pos.dx;
                                      _formToY = pos.dy;
                                    } else if (_pickMode == _PickMode.fromPoint) {
                                      _formFromX = pos.dx;
                                      _formFromY = pos.dy;
                                    }
                                    _pickMode = _PickMode.none;
                                  });
                                },
                          typeLabel: l.typeName,
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
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                        ),
                      ),
                    ],
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
                  onEdit: _selected!.id.startsWith('user_')
                      ? () => _openEditNadeSheet(_selected!)
                      : null,
                  onDelete: _selected!.id.startsWith('user_')
                      ? () => _deleteUserNade(_selected!)
                      : null,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddNadeSheet,
        tooltip: AppLocalizations.of(context).addNade,
        child: const Icon(Icons.add),
      ),
  );
  }

  Future<void> _openTypeFilterSheet() async {
    final l = AppLocalizations.of(context);
    final options = <(NadeType?, String, IconData)>[
      (null, l.filterAll, Icons.filter_alt_off),
      (NadeType.smoke, l.typeSmoke, Icons.cloud),
      (NadeType.flash, l.typeFlash, Icons.flash_on),
      (NadeType.molotov, l.typeMolotov, Icons.local_fire_department),
      (NadeType.he, l.typeHE, Icons.bubble_chart),
    ];
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final o = options[index];
              final isSel = _filterType == o.$1;
              return ListTile(
                leading: Icon(o.$3),
                title: Text(o.$2),
                selected: isSel,
                trailing: isSel ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _filterType = o.$1;
                    _selected = null;
                  });
                  _saveUiPrefs();
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openSideFilterSheet() async {
    final l = AppLocalizations.of(context);
    final options = <(String?, String, IconData)>[
      (null, l.sideAll, Icons.select_all),
      ('T', l.sideT, Icons.flag),
      ('CT', l.sideCT, Icons.shield),
      ('Both', l.sideBoth, Icons.groups_2),
    ];
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final o = options[index];
              final isSel = _filterSide == o.$1;
              return ListTile(
                leading: Icon(o.$3),
                title: Text(o.$2),
                selected: isSel,
                trailing: isSel ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _filterSide = o.$1;
                    _selected = null;
                  });
                  _saveUiPrefs();
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
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

  void _openAddNadeSheet() {
    _formToX = null;
    _formToY = null;
    _formFromX = null;
    _formFromY = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: _NadeForm(
            title: AppLocalizations.of(context).newNadeTitle,
            onPickTo: () => setState(() => _pickMode = _PickMode.toPoint),
            onPickFrom: () => setState(() => _pickMode = _PickMode.fromPoint),
            getTo: () => (_formToX, _formToY),
            getFrom: () => (_formFromX, _formFromY),
            onSave: (data) async {
              final id = 'user_${widget.map.id}_${DateTime.now().millisecondsSinceEpoch}';
              final n = Nade(
                id: id,
                mapId: widget.map.id,
                title: data.title,
                type: data.type,
                side: data.side,
                from: data.from,
                to: data.to,
                technique: data.technique,
                toX: _formToX ?? 0.5,
                toY: _formToY ?? 0.5,
                fromX: _formFromX ?? 0.5,
                fromY: _formFromY ?? 0.5,
                videoUrl: data.videoUrl,
                description: data.description,
                descriptionEn: null,
                descriptionRu: null,
              );
              await _repo.addUserNade(widget.map.id, n);
              if (!mounted) return;
              setState(() {
                _futureNades = _repo.getNadesByMap(widget.map.id);
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _openEditNadeSheet(Nade nade) {
    _formToX = nade.toX;
    _formToY = nade.toY;
    _formFromX = nade.fromX;
    _formFromY = nade.fromY;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: _NadeForm(
            title: AppLocalizations.of(context).editNadeTitle,
            initial: _NadeFormData(
              title: nade.title,
              type: nade.type,
              side: nade.side,
              from: nade.from,
              to: nade.to,
              technique: nade.technique,
              videoUrl: nade.videoUrl ?? '',
              description: nade.description ?? '',
            ),
            onPickTo: () => setState(() => _pickMode = _PickMode.toPoint),
            onPickFrom: () => setState(() => _pickMode = _PickMode.fromPoint),
            getTo: () => (_formToX, _formToY),
            getFrom: () => (_formFromX, _formFromY),
            onSave: (data) async {
              final updated = Nade(
                id: nade.id,
                mapId: widget.map.id,
                title: data.title,
                type: data.type,
                side: data.side,
                from: data.from,
                to: data.to,
                technique: data.technique,
                toX: _formToX ?? nade.toX,
                toY: _formToY ?? nade.toY,
                fromX: _formFromX ?? nade.fromX,
                fromY: _formFromY ?? nade.fromY,
                videoUrl: data.videoUrl,
                description: data.description,
                descriptionEn: nade.descriptionEn,
                descriptionRu: nade.descriptionRu,
              );
              await _repo.updateUserNade(widget.map.id, updated);
              if (!mounted) return;
              setState(() {
                _selected = updated;
                _futureNades = _repo.getNadesByMap(widget.map.id);
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteUserNade(Nade nade) async {
    await _repo.deleteUserNade(widget.map.id, nade.id);
    if (!mounted) return;
    setState(() {
      _selected = null;
      _futureNades = _repo.getNadesByMap(widget.map.id);
    });
  }
}

// Removed legacy inline filter widgets (_FilterBar, _SideFilterBar)

// Legend removed

class _SelectedInfo extends StatelessWidget {
  final Nade nade;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _SelectedInfo({
    required this.nade,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpenDetails,
    this.onEdit,
    this.onDelete,
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
                  Chip(label: Text(l.typeName(nade.type))),
                  Chip(label: Text(l.sideLabel(nade.side))),
                  Chip(label: Text(l.techniqueLabel(nade.technique))),
                ],
              ),
              const SizedBox(height: 8),
              Text(l.infoFrom(nade.from)),
              Text(l.infoTo(nade.to)),
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
                  const Spacer(),
                  if (nade.id.startsWith('user_') && onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: Text(l.edit),
                    ),
                  if (nade.id.startsWith('user_') && onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l.delete),
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
        SnackBar(content: Text(AppLocalizations.of(context).openVideoFailed)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).openVideoError)),
      );
    }
  }
}

// Removed duplicate _typeLabel; use AppLocalizations.typeName extension instead.

String? _localizedDescription(BuildContext context, Nade n) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'en') {
    if (n.descriptionEn != null && n.descriptionEn!.isNotEmpty) return n.descriptionEn;
  } else if (locale.languageCode == 'ru') {
    if (n.descriptionRu != null && n.descriptionRu!.isNotEmpty) return n.descriptionRu;
  }
  return n.description;
}

enum _PickMode { none, toPoint, fromPoint }

class _NadeFormData {
  String title;
  NadeType type;
  String side; // 'T' | 'CT' | 'Both'
  String from;
  String to;
  String technique;
  String videoUrl;
  String description;
  _NadeFormData({
    required this.title,
    required this.type,
    required this.side,
    required this.from,
    required this.to,
    required this.technique,
    required this.videoUrl,
    required this.description,
  });
}

class _NadeForm extends StatefulWidget {
  final String title;
  final _NadeFormData? initial;
  final VoidCallback onPickTo;
  final VoidCallback onPickFrom;
  final (double?, double?) Function() getTo;
  final (double?, double?) Function() getFrom;
  final Future<void> Function(_NadeFormData) onSave;
  const _NadeForm({
    required this.title,
    this.initial,
    required this.onPickTo,
    required this.onPickFrom,
    required this.getTo,
    required this.getFrom,
    required this.onSave,
  });

  @override
  State<_NadeForm> createState() => _NadeFormState();
}

class _NadeFormState extends State<_NadeForm> {
  late final TextEditingController _title;
  late NadeType _type;
  String _side = 'Both';
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _technique;
  late final TextEditingController _videoUrl;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _type = i?.type ?? NadeType.smoke;
    _side = i?.side ?? 'Both';
    _from = TextEditingController(text: i?.from ?? '');
    _to = TextEditingController(text: i?.to ?? '');
    _technique = TextEditingController(text: i?.technique ?? 'stand');
    _videoUrl = TextEditingController(text: i?.videoUrl ?? '');
    _description = TextEditingController(text: i?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _from.dispose();
    _to.dispose();
    _technique.dispose();
    _videoUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final to = widget.getTo();
    final from = widget.getFrom();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldTitle),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<NadeType>(
                value: _type,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldType),
                items: const [
                  DropdownMenuItem(value: NadeType.smoke, child: Text('Smoke')),
                  DropdownMenuItem(value: NadeType.flash, child: Text('Flash')),
                  DropdownMenuItem(value: NadeType.molotov, child: Text('Molotov')),
                  DropdownMenuItem(value: NadeType.he, child: Text('HE')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _side,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldSide),
                items: const [
                  DropdownMenuItem(value: 'Both', child: Text('Both')),
                  DropdownMenuItem(value: 'T', child: Text('T')),
                  DropdownMenuItem(value: 'CT', child: Text('CT')),
                ],
                onChanged: (v) => setState(() => _side = v ?? _side),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _from,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldFrom),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _to,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldTo),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _CoordTile(title: AppLocalizations.of(context).fieldToCoords, x: to.$1, y: to.$2)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: widget.onPickTo,
              icon: const Icon(Icons.my_location),
              label: Text(AppLocalizations.of(context).pickOnMap),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _CoordTile(title: AppLocalizations.of(context).fieldFromCoords, x: from.$1, y: from.$2)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: widget.onPickFrom,
              icon: const Icon(Icons.my_location_outlined),
              label: Text(AppLocalizations.of(context).pickOnMap),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _technique,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldTechnique),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _videoUrl,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldVideoUrl),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _description,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).fieldDescription),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save),
            label: Text(AppLocalizations.of(context).save),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final data = _NadeFormData(
        title: _title.text.trim(),
        type: _type,
        side: _side,
        from: _from.text.trim(),
        to: _to.text.trim(),
        technique: _technique.text.trim(),
        videoUrl: _videoUrl.text.trim(),
        description: _description.text.trim(),
      );
      await widget.onSave(data);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CoordTile extends StatelessWidget {
  final String title;
  final double? x;
  final double? y;
  const _CoordTile({required this.title, required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    final text = (x == null || y == null)
        ? 'не выбрано'
        : 'x: ${x!.toStringAsFixed(3)}, y: ${y!.toStringAsFixed(3)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }
}

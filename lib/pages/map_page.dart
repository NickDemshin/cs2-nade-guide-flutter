import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../data/nades_repository.dart';
import '../models/cs_map.dart';
import '../models/nade.dart';
import '../widgets/map_board.dart';
import 'nade_detail_page.dart';

class MapPage extends StatefulWidget {
  final CsMap map;
  const MapPage({super.key, required this.map});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _repo = const NadesRepository();
  late Future<List<Nade>> _futureNades;

  NadeType? _filterType; // null = все
  String? _filterSide; // null = все, иначе 'T' | 'CT' | 'Both'
  Nade? _selected;
  final _transform = TransformationController();
  bool _showGrid = true;
  bool _onlyFavorites = false;
  final Set<String> _favorites = <String>{};
  bool _coordMode = false;

  @override
  void initState() {
    super.initState();
    _futureNades = _repo.getNadesByMap(widget.map.id);
    _loadUiPrefs();
    _loadFavorites();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Гранаты — ${widget.map.name}'),
        actions: [
          if (_selected != null)
            IconButton(
              tooltip: 'Снять выделение',
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selected = null),
            ),
          IconButton(
            tooltip: _onlyFavorites ? 'Показать все' : 'Только избранные',
            icon: Icon(_onlyFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() => _onlyFavorites = !_onlyFavorites);
              _saveUiPrefs();
            },
          ),
          IconButton(
            tooltip: _showGrid ? 'Скрыть сетку' : 'Показать сетку',
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () {
              setState(() => _showGrid = !_showGrid);
              _saveUiPrefs();
            },
          ),
          IconButton(
            tooltip: _coordMode ? 'Координаты: вкл' : 'Координаты: выкл',
            icon: Icon(_coordMode ? Icons.my_location : Icons.location_searching),
            onPressed: () => setState(() => _coordMode = !_coordMode),
          ),
          IconButton(
            tooltip: 'Сбросить зум',
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
                    Text('Ошибка загрузки: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _futureNades = _repo.getNadesByMap(widget.map.id);
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
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
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(80),
                    clipBehavior: Clip.none,
                    transformationController: _transform,
                    child: MapBoard(
                      nades: nades,
                      selected: _selected,
                      onSelect: (n) => setState(() {
                        _selected = (_selected?.id == n.id) ? null : n;
                      }),
                      imageAsset: widget.map.image,
                      favoriteIds: _favorites,
                      showGrid: _showGrid,
                      onLongPressRelative: _coordMode
                          ? (pos) {
                              final text = 'x: ${pos.dx.toStringAsFixed(3)}, y: ${pos.dy.toStringAsFixed(3)}';
                              Clipboard.setData(ClipboardData(text: text));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Координаты скопированы: $text')),
                                );
                              }
                            }
                          : null,
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
                    _coordMode
                        ? 'Долгий тап по карте — скопировать координаты (0..1)'
                        : 'Нажмите на точку на карте, чтобы посмотреть откуда бросать',
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
    final types = [null, ...NadeType.values];
    String label(NadeType? t) => t == null ? 'Все' : nadeTypeLabel(t);

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
    final items = <String?>[null, 'T', 'CT', 'Both'];
    String label(String? s) {
      if (s == null) return 'Сторона: Все';
      if (s == 'T') return 'T';
      if (s == 'CT') return 'CT';
      if (s == 'Both') return 'Both';
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
                    tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                    onPressed: onToggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(nadeTypeLabel(nade.type))),
                  Chip(label: Text('Сторона: ${nade.side}')),
                  Chip(label: Text('Техника: ${nade.technique}')),
                ],
              ),
              const SizedBox(height: 8),
              Text('Откуда бросать: ${nade.from}'),
              Text('Куда прилетает: ${nade.to}'),
              if (nade.description != null && nade.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(nade.description!),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Подробнее'),
                    onPressed: onOpenDetails,
                  ),
                  const SizedBox(width: 8),
                  if (nade.videoUrl != null && nade.videoUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Открыть видео'),
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

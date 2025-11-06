import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/nades_repository.dart';
import '../models/cs_map.dart';
import '../models/nade.dart';
import '../widgets/map_board.dart';

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
  Nade? _selected;
  final _transform = TransformationController();
  bool _showGrid = true;
  bool _onlyFavorites = false;
  final Set<String> _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    _futureNades = _repo.getNadesByMap(widget.map.id);
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
          IconButton(
            tooltip: _onlyFavorites ? 'Показать все' : 'Только избранные',
            icon: Icon(_onlyFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
          ),
          IconButton(
            tooltip: _showGrid ? 'Скрыть сетку' : 'Показать сетку',
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () => setState(() => _showGrid = !_showGrid),
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
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }
          var nades = snapshot.data ?? const <Nade>[];
          if (_filterType != null) {
            nades = nades.where((n) => n.type == _filterType).toList();
          }
          if (_onlyFavorites) {
            nades = nades.where((n) => _favorites.contains(n.id)).toList();
          }

          return Column(
            children: [
              _FilterBar(
                selected: _filterType,
                onSelected: (t) => setState(() => _filterType = t),
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
                      onSelect: (n) => setState(() => _selected = n),
                      imageAsset: widget.map.image,
                      favoriteIds: _favorites,
                      showGrid: _showGrid,
                    ),
                  ),
                ),
              ),
              if (_selected != null)
                _SelectedInfo(
                  nade: _selected!,
                  isFavorite: _favorites.contains(_selected!.id),
                  onToggleFavorite: () => _toggleFavorite(_selected!),
                ),
              if (_selected == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Нажмите на точку на карте, чтобы посмотреть откуда бросать',
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

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites_${_mapKey()}', _favorites.toList());
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

class _SelectedInfo extends StatelessWidget {
  final Nade nade;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  const _SelectedInfo({required this.nade, required this.isFavorite, required this.onToggleFavorite});

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
              if (nade.videoUrl != null && nade.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Открыть видео'),
                    onPressed: () => _openVideo(context, nade.videoUrl!),
                  ),
                ),
              ],
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

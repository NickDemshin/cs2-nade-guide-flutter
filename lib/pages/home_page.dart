import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/color_compat.dart'; // ignore: unused_import
import '../widgets/glass.dart';

import '../data/nades_repository.dart';
import '../models/cs_map.dart';
import '../models/nade.dart';
import 'map_page.dart';
import 'matches_page.dart';
import '../l10n/app_localizations.dart';
import '../locale_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _repo = const NadesRepository();
  Future<List<CsMap>>? _futureMaps;
  final Map<String, Future<int>> _nadeCountFutures = <String, Future<int>>{};
  // Поиск отключён — поле убрано
  bool _grid = true;
  late final TabController _tabs;
  final Set<String> _favoriteMaps = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
    _tabs = TabController(length: 3, vsync: this)..addListener(() => setState(() {}));
    _loadFavoriteMaps();
  }

  void _reload() {
    setState(() {
      _futureMaps = _repo.getMaps();
    });
  }

  Future<int> _nadeCount(String mapId) {
    return _nadeCountFutures.putIfAbsent(mapId, () async {
      final List<Nade> list = await _repo.getNadesByMap(mapId);
      return list.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.homeTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const GlassContainer(radius: 0, padding: EdgeInsets.zero, child: SizedBox.expand()),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.tabsTournament),
            Tab(text: l.tabsOthers),
            Tab(text: l.tabsFavorites),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Матчи',
            icon: const Icon(Icons.sports_esports),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MatchesPage()),
            ),
          ),
          IconButton(
            tooltip: _grid ? l.toggleList : l.toggleGrid,
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          PopupMenuButton<String>(
            tooltip: l.languageTooltip,
            icon: const Icon(Icons.language),
            onSelected: (code) {
              if (code == 'ru') {
                LocaleController.setRu();
              } else if (code == 'en') {
                LocaleController.setEn();
              }
            },
            itemBuilder: (context) {
              final l = AppLocalizations.of(context);
              return [
                PopupMenuItem(value: 'ru', child: Text(l.langRussian)),
                PopupMenuItem(value: 'en', child: Text(l.langEnglish)),
              ];
            },
          ),
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<CsMap>>(
        future: _futureMaps,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l.errorLoading(snapshot.error.toString())));
          }
          var maps = snapshot.data ?? const <CsMap>[];
          // Поиск отключён
          // Фильтрация по вкладке
          final idx = _tabs.index;
          if (idx == 0) {
            maps = maps.where((m) => m.tournament).toList();
          } else if (idx == 1) {
            maps = maps.where((m) => !m.tournament).toList();
          } else if (idx == 2) {
            maps = maps.where((m) => _favoriteMaps.contains(m.id)).toList();
          }
          if (maps.isEmpty) {
            return Center(child: Text(l.noMaps));
          }
          final content = _grid
              ? _MapsGrid(maps: maps, nadeCount: _nadeCount, onTap: _openMap, isFav: _isMapFav, toggleFav: _toggleMapFav)
              : _MapsList(maps: maps, nadeCount: _nadeCount, onTap: _openMap, isFav: _isMapFav, toggleFav: _toggleMapFav);
          return RefreshIndicator(
            onRefresh: () async {
              final fut = _repo.getMaps();
              setState(() => _futureMaps = fut);
              await fut;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Поле поиска удалено
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(l.mapsTitle, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                content,
              ],
            ),
          );
        },
      ),
    );
  }

  void _openMap(CsMap m) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapPage(map: m)));
  }

  bool _isMapFav(String id) => _favoriteMaps.contains(id);
  Future<void> _loadFavoriteMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorite_maps') ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _favoriteMaps
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _saveFavoriteMaps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_maps', _favoriteMaps.toList());
  }

  void _toggleMapFav(String id) {
    setState(() {
      if (_favoriteMaps.contains(id)) {
        _favoriteMaps.remove(id);
      } else {
        _favoriteMaps.add(id);
      }
    });
    _saveFavoriteMaps();
  }
}

class _MapsList extends StatelessWidget {
  final List<CsMap> maps;
  final Future<int> Function(String) nadeCount;
  final void Function(CsMap) onTap;
  final bool Function(String) isFav;
  final void Function(String) toggleFav;
  const _MapsList({required this.maps, required this.nadeCount, required this.onTap, required this.isFav, required this.toggleFav});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SliverList.separated(
      itemCount: maps.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = maps[index];
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(m.name),
          subtitle: FutureBuilder<int>(
            future: nadeCount(m.id),
            builder: (context, snap) {
              if (!snap.hasData) return Text('ID: ${m.id}');
                      final count = snap.data!;
                      return Text(l.nadeCount(count, m.id));
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isFav(m.id) ? Icons.star : Icons.star_border, color: isFav(m.id) ? Colors.amber : null),
                onPressed: () => toggleFav(m.id),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => onTap(m),
        );
      },
    );
  }
}

class _MapsGrid extends StatelessWidget {
  final List<CsMap> maps;
  final Future<int> Function(String) nadeCount;
  final void Function(CsMap) onTap;
  final bool Function(String) isFav;
  final void Function(String) toggleFav;
  const _MapsGrid({required this.maps, required this.nadeCount, required this.onTap, required this.isFav, required this.toggleFav});

  @override
  Widget build(BuildContext context) {
    final grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: grid,
        delegate: SliverChildBuilderDelegate(
          (context, index) => _MapCard(
            map: maps[index],
            countFuture: nadeCount(maps[index].id),
            onTap: onTap,
            isFav: isFav(maps[index].id),
            toggleFav: () => toggleFav(maps[index].id),
          ),
          childCount: maps.length,
        ),
      ),
    );
  }
}


class _MapCard extends StatelessWidget {
  final CsMap map;
  final Future<int> countFuture;
  final void Function(CsMap) onTap;
  final bool isFav;
  final VoidCallback toggleFav;
  const _MapCard({required this.map, required this.countFuture, required this.onTap, this.isFav = false, required this.toggleFav});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(map),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (map.image != null)
                Image.asset(map.image!, fit: BoxFit.cover)
              else
                Container(color: const Color(0xFF1E1E1E)),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xAA000000), Color(0x33000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.25)),
                  onPressed: toggleFav,
                  icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.white),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        map.name,
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<int>(
                      future: countFuture,
                      builder: (context, snap) {
                        final count = snap.data;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            count == null ? '…' : '$count',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

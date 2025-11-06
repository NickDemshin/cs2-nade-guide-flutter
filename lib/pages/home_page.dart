import 'package:flutter/material.dart';

import '../data/nades_repository.dart';
import '../models/cs_map.dart';
import '../models/nade.dart';
import 'map_page.dart';
import '../l10n/app_localizations.dart';
import '../locale_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = const NadesRepository();
  Future<List<CsMap>>? _futureMaps;
  final Map<String, Future<int>> _nadeCountFutures = <String, Future<int>>{};

  @override
  void initState() {
    super.initState();
    _reload();
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Language',
            icon: const Icon(Icons.language),
            onSelected: (code) {
              if (code == 'ru') {
                LocaleController.setRu();
              } else if (code == 'en') {
                LocaleController.setEn();
              } else {
                LocaleController.setSystem();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'system', child: Text('System')),
              const PopupMenuItem(value: 'ru', child: Text('Русский')),
              const PopupMenuItem(value: 'en', child: Text('English')),
            ],
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
          final maps = snapshot.data ?? const <CsMap>[];
          if (maps.isEmpty) {
            return Center(child: Text(l.noMaps));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final fut = _repo.getMaps();
              setState(() => _futureMaps = fut);
              await fut;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: maps.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = maps[index];
                return ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(m.name),
                  subtitle: FutureBuilder<int>(
                    future: _nadeCount(m.id),
                    builder: (context, snap) {
                      if (!snap.hasData) return Text('ID: ${m.id}');
                      final count = snap.data!;
                      return Text(l.nadeCount(m.id, count));
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MapPage(map: m)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

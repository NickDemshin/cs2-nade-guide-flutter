import 'package:flutter/material.dart';

import '../data/nades_repository.dart';
import '../models/cs_map.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = const NadesRepository();
  late final Future<List<CsMap>> _futureMaps = _repo.getMaps();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гайды по гранатам — CS2')),
      body: FutureBuilder<List<CsMap>>(
        future: _futureMaps,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: \${snapshot.error}'));
          }
          final maps = snapshot.data ?? const <CsMap>[];
          if (maps.isEmpty) {
            return const Center(child: Text('Пока нет карт'));
          }
          return ListView.separated(
            itemCount: maps.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = maps[index];
              return ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(m.name),
                subtitle: Text('ID: ${m.id}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MapPage(map: m)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../models/cs_map.dart';
import '../models/nade.dart';

Map<String, dynamic> _nadeToJson(Nade e) => {
      'id': e.id,
      'title': e.title,
      'type': () {
        switch (e.type) {
          case NadeType.smoke:
            return 'smoke';
          case NadeType.flash:
            return 'flash';
          case NadeType.molotov:
            return 'molotov';
          case NadeType.he:
            return 'he';
        }
      }(),
      'side': e.side,
      'from': e.from,
      'to': e.to,
      'technique': e.technique,
      'toX': e.toX,
      'toY': e.toY,
      'fromX': e.fromX,
      'fromY': e.fromY,
      if (e.videoUrl != null && e.videoUrl!.isNotEmpty) 'videoUrl': e.videoUrl,
      if (e.description != null && e.description!.isNotEmpty) 'description': e.description,
      if (e.descriptionEn != null && e.descriptionEn!.isNotEmpty) 'description_en': e.descriptionEn,
      if (e.descriptionRu != null && e.descriptionRu!.isNotEmpty) 'description_ru': e.descriptionRu,
    };

class NadesRepository {
  const NadesRepository();

  Future<List<CsMap>> getMaps() async {
    final raw = await rootBundle.loadString('assets/data/maps.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['maps'] as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(CsMap.fromJson).toList(growable: false);
  }

  Future<List<Nade>> getNadesByMap(String mapId) async {
    final path = 'assets/data/nades_$mapId.json';
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final list = (decoded['nades'] as List<dynamic>).cast<Map<String, dynamic>>();
    final base = list.map((e) => Nade.fromJson(e, mapId: mapId)).toList(growable: true);

    final user = await _readUserNades(mapId);
    base.addAll(user);
    return base;
  }

  Future<List<Nade>> _readUserNades(String mapId) async {
    try {
      final file = await _userFile(mapId);
      if (!await file.exists()) return const <Nade>[];
      final raw = await file.readAsString();
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = (decoded['nades'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      return list.map((e) => Nade.fromJson(e, mapId: mapId)).toList(growable: false);
    } catch (_) {
      return const <Nade>[];
    }
  }

  Future<void> _writeUserNades(String mapId, List<Nade> nades) async {
    final file = await _userFile(mapId);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final payload = {
      'nades': nades.map(_nadeToJson).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<File> _userFile(String mapId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/nades_$mapId.user.json');
  }

  Future<void> addUserNade(String mapId, Nade nade) async {
    final current = await _readUserNades(mapId);
    final list = current.toList(growable: true);
    list.add(nade);
    await _writeUserNades(mapId, list);
  }

  Future<void> updateUserNade(String mapId, Nade nade) async {
    final list = await _readUserNades(mapId);
    final idx = list.indexWhere((e) => e.id == nade.id);
    if (idx >= 0) {
      list[idx] = nade;
      await _writeUserNades(mapId, list);
    }
  }

  Future<void> deleteUserNade(String mapId, String nadeId) async {
    final list = await _readUserNades(mapId);
    list.removeWhere((e) => e.id == nadeId);
    await _writeUserNades(mapId, list);
  }
}

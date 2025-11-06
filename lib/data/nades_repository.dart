import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/cs_map.dart';
import '../models/nade.dart';

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
    return list.map((e) => Nade.fromJson(e, mapId: mapId)).toList(growable: false);
  }
}

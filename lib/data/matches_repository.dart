import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/match_entry.dart';

class MatchesRepository {
  const MatchesRepository();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/matches.user.json');
  }

  Future<List<MatchEntry>> getAll() async {
    try {
      final f = await _file();
      if (!await f.exists()) return <MatchEntry>[];
      final raw = await f.readAsString();
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = (decoded['matches'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      return list.map(MatchEntry.fromJson).toList(growable: true);
    } catch (_) {
      return <MatchEntry>[];
    }
  }

  Future<void> _saveAll(List<MatchEntry> items) async {
    final f = await _file();
    final dir = f.parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    final payload = {
      'matches': items.map((e) => e.toJson()).toList(),
    };
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<void> add(MatchEntry entry) async {
    final items = await getAll();
    items.insert(0, entry);
    await _saveAll(items);
  }

  Future<void> remove(String id) async {
    final items = await getAll();
    items.removeWhere((e) => e.id == id);
    await _saveAll(items);
  }

  Future<void> update(MatchEntry entry) async {
    final items = await getAll();
    final i = items.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      items[i] = entry;
      await _saveAll(items);
    }
  }

  // Export matches as pretty JSON string
  Future<String> exportJsonString([List<MatchEntry>? items]) async {
    final list = items ?? await getAll();
    final payload = {
      'matches': list.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // Replace all matches from provided JSON string
  Future<void> replaceFromJsonString(String jsonString) async {
    try {
      final decoded = json.decode(jsonString);
      List<dynamic> rawList;
      if (decoded is Map<String, dynamic>) {
        rawList = (decoded['matches'] as List<dynamic>? ?? const <dynamic>[]);
      } else if (decoded is List<dynamic>) {
        rawList = decoded;
      } else {
        throw const FormatException('Invalid JSON root');
      }
      final items = rawList
          .cast<Map<String, dynamic>>()
          .map(MatchEntry.fromJson)
          .toList(growable: true);
      await _saveAll(items);
    } catch (_) {
      rethrow;
    }
  }
}

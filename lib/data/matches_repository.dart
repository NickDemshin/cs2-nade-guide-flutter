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
    // Deduplicate by unique keys: shareCode (normalized) or decoded ids
    String? normShare(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim().toLowerCase();
    final ns = normShare(entry.shareCode);
    final mid = entry.matchId?.toString();
    final oid = entry.outcomeId?.toString();
    final tok = entry.token?.toString();

    bool same(MatchEntry e) {
      final ens = normShare(e.shareCode);
      final emid = e.matchId?.toString();
      final eoid = e.outcomeId?.toString();
      final etok = e.token?.toString();
      final byShare = (ns != null && ens != null && ns == ens);
      final byDecoded = (mid != null && oid != null && tok != null &&
          emid == mid && eoid == oid && etok == tok);
      return byShare || byDecoded;
    }

    items.removeWhere(same);
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
}

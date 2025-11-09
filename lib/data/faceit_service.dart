import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/config.dart';
import '../models/match_analysis.dart';

class FaceitMatchSummary {
  final String id;
  final String? map; // e.g. de_mirage
  final DateTime? finishedAt;

  const FaceitMatchSummary({required this.id, this.map, this.finishedAt});

  factory FaceitMatchSummary.fromJson(Map<String, dynamic> j) {
    DateTime? ts;
    final v = j['finished_at'];
    if (v is String) {
      ts = DateTime.tryParse(v);
    } else if (v is num) {
      // seconds or millis
      final n = v.toInt();
      ts = DateTime.fromMillisecondsSinceEpoch(n < 2000000000 ? n * 1000 : n, isUtc: true);
    }
    return FaceitMatchSummary(
      id: (j['match_id'] ?? j['id']).toString(),
      map: (j['map'] ?? j['map_id'] ?? j['veto_map'])?.toString(),
      finishedAt: ts,
    );
  }
}

class FaceitService {
  final String baseUrl;
  final http.Client _client;
  FaceitService({this.baseUrl = kApiBaseUrl, http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String p, [Map<String, dynamic>? q]) => Uri.parse(baseUrl).replace(path: p, queryParameters: q);

  Future<String> getPlayerIdByNickname(String nickname) async {
    final res = await _client.get(_u('/api/faceit/players/by-nickname/$nickname'));
    if (res.statusCode != 200) {
      throw Exception('FACEIT lookup failed: ${res.statusCode}');
    }
    final j = json.decode(res.body) as Map<String, dynamic>;
    final id = (j['player_id'] ?? j['playerId'] ?? j['id'])?.toString();
    if (id == null || id.isEmpty) throw Exception('FACEIT player not found');
    return id;
  }

  Future<List<FaceitMatchSummary>> getRecentMatches(String playerId, {int limit = 20}) async {
    final res = await _client.get(_u('/api/faceit/players/$playerId/matches', {'game': 'cs2', 'limit': '$limit'}));
    if (res.statusCode != 200) {
      throw Exception('FACEIT matches failed: ${res.statusCode}');
    }
    final body = json.decode(res.body);
    final List list = body is List ? body : (body['items'] ?? body['matches'] ?? body['payload'] ?? []) as List;
    return list.cast<Map<String, dynamic>>().map(FaceitMatchSummary.fromJson).toList(growable: false);
  }

  Future<MatchAnalysis> analyzeMatch(String matchId, {String? mapId}) async {
    final res = await _client.post(
      _u('/api/faceit/matches/$matchId/analyze'),
      headers: {'content-type': 'application/json'},
      body: json.encode({if (mapId != null) 'map': mapId}),
    );
    if (res.statusCode != 200) {
      throw Exception('FACEIT analyze failed: ${res.statusCode}');
    }
    final j = json.decode(res.body) as Map<String, dynamic>;
    return MatchAnalysis.fromJson(j);
  }
}

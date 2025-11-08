import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../models/match_analysis.dart';
import '../models/match_entry.dart';

class AnalysisRepository {
  const AnalysisRepository();

  Future<File> _file(String entryId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/analysis_$entryId.json');
  }

  Future<MatchAnalysis?> read(String entryId) async {
    try {
      final f = await _file(entryId);
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      return MatchAnalysis.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(MatchAnalysis a) async {
    final f = await _file(a.entryId);
    if (!await f.parent.exists()) await f.parent.create(recursive: true);
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(a.toJson()));
  }

  // Generates a deterministic mock analysis using entry ids as seed
  Future<MatchAnalysis> generateAndStore(MatchEntry entry) async {
    // Local mock generation (server integration removed)

    final seed = entry.matchId?.toInt() ?? entry.shareCode.hashCode;
    final rnd = Random(seed);

    int kills = 10 + rnd.nextInt(25);
    int deaths = 8 + rnd.nextInt(20);
    int assists = rnd.nextInt(10);
    final adr = 60 + rnd.nextDouble() * 60; // 60..120
    final rating = (0.8 + rnd.nextDouble() * 0.8); // 0.8..1.6

    final player = PlayerStats(
      kills: kills,
      deaths: deaths,
      assists: assists,
      adr: double.parse(adr.toStringAsFixed(1)),
      rating: double.parse(rating.toStringAsFixed(2)),
    );

    final utility = UtilityStats(
      flashes: 5 + rnd.nextInt(12),
      flashAssists: rnd.nextInt(5),
      smokes: 4 + rnd.nextInt(10),
      molotovs: 2 + rnd.nextInt(8),
      he: 2 + rnd.nextInt(8),
    );

    final rounds = <RoundSummary>[];
    final totalRounds = 24 + rnd.nextInt(8); // 24..31
    for (int i = 1; i <= totalRounds; i++) {
      final side = (i <= totalRounds / 2) ? 'T' : 'CT';
      final won = rnd.nextBool();
      final rk = rnd.nextInt(3); // 0..2 kills
      final survived = rnd.nextBool();
      final entry = rnd.nextInt(10) == 0; // ~10%
      rounds.add(RoundSummary(
        round: i,
        side: side,
        won: won,
        kills: rk,
        survived: survived,
        entry: entry,
      ));
    }

    // Mock throws and insights
    final types = ['flash', 'smoke', 'molotov', 'he'];
    int throwCount = 12 + rnd.nextInt(10);
    final throws = <ThrowRecord>[];
    int ineffectiveCount = 0;
    for (int i = 0; i < throwCount; i++) {
      final t = types[rnd.nextInt(types.length)];
      final time = 10 + rnd.nextInt(2000) ~/ 10; // ~10..200 sec
      final round = 1 + rnd.nextInt(totalRounds);
      final dmg = t == 'he' ? rnd.nextInt(60) : rnd.nextInt(10);
      final blind = t == 'flash' ? rnd.nextInt(2500) : 0;
      final teamBlind = t == 'flash' ? rnd.nextInt(600) : 0;
      final los = t == 'smoke' ? (500 + rnd.nextInt(3000)) : 0;
      final area = t == 'molotov' ? (800 + rnd.nextInt(3500)) : 0;
      // simple score
      double score = 0.0;
      score += dmg / 100.0;
      score += blind / 3000.0;
      score += (los + area) / 7000.0;
      score -= teamBlind / 1200.0;
      score = score.clamp(0.0, 1.0);
      final ineffective = score < 0.25 || (t == 'flash' && teamBlind > blind / 2);
      if (ineffective) ineffectiveCount++;
      // Синтетические координаты 0..1 для тепловой карты
      final dx = (0.08 + rnd.nextDouble() * 0.84);
      final dy = (0.08 + rnd.nextDouble() * 0.84);
      throws.add(ThrowRecord(
        id: 'tr_${entry.id}_$i',
        type: t,
        timeSec: time,
        round: round,
        damage: dmg,
        blindMs: blind,
        teamBlindMs: teamBlind,
        losBlockMs: los,
        areaMs: area,
        score: double.parse(score.toStringAsFixed(2)),
        ineffective: ineffective,
        note: ineffective && t == 'flash' && teamBlind > 0 ? 'team-flash' : null,
        x: dx,
        y: dy,
      ));
    }
    final ineffectivePct = (ineffectiveCount * 100 / throwCount).round();
    final insights = <Insight>[
      if (ineffectivePct >= 30)
        Insight(type: 'general', severity: 'warn', message: 'Ineffective utility ~$ineffectivePct%'),
      if (throws.any((e) => e.type == 'flash' && e.teamBlindMs > 500))
        const Insight(type: 'flash', severity: 'warn', message: 'High team-flash incidents'),
      if (throws.where((e) => e.type == 'smoke' && e.losBlockMs < 1200).length >= 2)
        const Insight(type: 'smoke', severity: 'info', message: 'Some smokes with short LOS block'),
    ];

    final a = MatchAnalysis(
      entryId: entry.id,
      map: entry.map,
      player: player,
      utility: utility,
      rounds: rounds,
      throws: throws,
      insights: insights,
    );
    await write(a);
    return a;
  }
}

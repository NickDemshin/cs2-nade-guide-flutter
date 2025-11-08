import 'dart:convert';

class PlayerStats {
  final int kills;
  final int deaths;
  final int assists;
  final double adr; // average damage per round
  final double rating; // simple rating 0..2

  const PlayerStats({
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.adr,
    required this.rating,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> j) => PlayerStats(
        kills: (j['kills'] as num).toInt(),
        deaths: (j['deaths'] as num).toInt(),
        assists: (j['assists'] as num).toInt(),
        adr: (j['adr'] as num).toDouble(),
        rating: (j['rating'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'kills': kills,
        'deaths': deaths,
        'assists': assists,
        'adr': adr,
        'rating': rating,
      };
}

class UtilityStats {
  final int flashes;
  final int flashAssists;
  final int smokes;
  final int molotovs;
  final int he;

  const UtilityStats({
    required this.flashes,
    required this.flashAssists,
    required this.smokes,
    required this.molotovs,
    required this.he,
  });

  factory UtilityStats.fromJson(Map<String, dynamic> j) => UtilityStats(
        flashes: (j['flashes'] as num).toInt(),
        flashAssists: (j['flashAssists'] as num).toInt(),
        smokes: (j['smokes'] as num).toInt(),
        molotovs: (j['molotovs'] as num).toInt(),
        he: (j['he'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'flashes': flashes,
        'flashAssists': flashAssists,
        'smokes': smokes,
        'molotovs': molotovs,
        'he': he,
      };
}

class RoundSummary {
  final int round;
  final String side; // T | CT
  final bool won;
  final int kills;
  final bool survived;
  final bool entry;

  const RoundSummary({
    required this.round,
    required this.side,
    required this.won,
    required this.kills,
    required this.survived,
    required this.entry,
  });

  factory RoundSummary.fromJson(Map<String, dynamic> j) => RoundSummary(
        round: (j['round'] as num).toInt(),
        side: j['side'] as String,
        won: j['won'] as bool,
        kills: (j['kills'] as num).toInt(),
        survived: j['survived'] as bool,
        entry: j['entry'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'round': round,
        'side': side,
        'won': won,
        'kills': kills,
        'survived': survived,
        'entry': entry,
      };
}

class MatchAnalysis {
  final String entryId; // link to MatchEntry.id
  final String? map;
  final PlayerStats player;
  final UtilityStats utility;
  final List<RoundSummary> rounds;
  final List<ThrowRecord> throws; // mock throws effectiveness
  final List<Insight> insights;   // high-level notes

  const MatchAnalysis({
    required this.entryId,
    required this.map,
    required this.player,
    required this.utility,
    required this.rounds,
    this.throws = const <ThrowRecord>[],
    this.insights = const <Insight>[],
  });

  factory MatchAnalysis.fromJson(Map<String, dynamic> j) => MatchAnalysis(
        entryId: j['entryId'] as String,
        map: j['map'] as String?,
        player: PlayerStats.fromJson(j['player'] as Map<String, dynamic>),
        utility: UtilityStats.fromJson(j['utility'] as Map<String, dynamic>),
        rounds: ((j['rounds'] as List<dynamic>)
                .cast<Map<String, dynamic>>() )
            .map(RoundSummary.fromJson)
            .toList(growable: false),
        throws: ((j['throws'] as List<dynamic>? ?? const <dynamic>[])
                .cast<Map<String, dynamic>>())
            .map(ThrowRecord.fromJson)
            .toList(growable: false),
        insights: ((j['insights'] as List<dynamic>? ?? const <dynamic>[])
                .cast<Map<String, dynamic>>())
            .map(Insight.fromJson)
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'map': map,
        'player': player.toJson(),
        'utility': utility.toJson(),
        'rounds': rounds.map((e) => e.toJson()).toList(),
        if (throws.isNotEmpty) 'throws': throws.map((e) => e.toJson()).toList(),
        if (insights.isNotEmpty) 'insights': insights.map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class ThrowRecord {
  final String id;
  final String type; // smoke|flash|molotov|he
  final int timeSec;
  final int round; // round number (1-based)
  final int damage;
  final int blindMs;
  final int teamBlindMs;
  final int losBlockMs; // for smokes
  final int areaMs; // for molotovs
  final double score; // 0..1
  final bool ineffective;
  final String? note;
  // Нормированные координаты 0..1 на карте (точка приземления)
  final double? x;
  final double? y;

  const ThrowRecord({
    required this.id,
    required this.type,
    required this.timeSec,
    required this.round,
    required this.damage,
    required this.blindMs,
    required this.teamBlindMs,
    required this.losBlockMs,
    required this.areaMs,
    required this.score,
    required this.ineffective,
    this.note,
    this.x,
    this.y,
  });

  factory ThrowRecord.fromJson(Map<String, dynamic> j) => ThrowRecord(
        id: j['id'] as String,
        type: j['type'] as String,
        timeSec: (j['timeSec'] as num).toInt(),
        round: (j['round'] as num?)?.toInt() ?? 0,
        damage: (j['damage'] as num).toInt(),
        blindMs: (j['blindMs'] as num).toInt(),
        teamBlindMs: (j['teamBlindMs'] as num).toInt(),
        losBlockMs: (j['losBlockMs'] as num).toInt(),
        areaMs: (j['areaMs'] as num).toInt(),
        score: (j['score'] as num).toDouble(),
        ineffective: j['ineffective'] as bool,
        note: j['note'] as String?,
        x: (j['x'] as num?)?.toDouble(),
        y: (j['y'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'timeSec': timeSec,
        'round': round,
        'damage': damage,
        'blindMs': blindMs,
        'teamBlindMs': teamBlindMs,
        'losBlockMs': losBlockMs,
        'areaMs': areaMs,
        'score': score,
        'ineffective': ineffective,
        if (note != null) 'note': note,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
      };
}

class Insight {
  final String type; // e.g. 'flash', 'smoke', 'he', 'molotov', 'general'
  final String message;
  final String severity; // info|warn|error

  const Insight({required this.type, required this.message, this.severity = 'info'});

  factory Insight.fromJson(Map<String, dynamic> j) => Insight(
        type: j['type'] as String,
        message: j['message'] as String,
        severity: (j['severity'] as String?) ?? 'info',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'severity': severity,
      };
}

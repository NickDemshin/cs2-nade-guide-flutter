enum MatchStatus { pending, ready, failed }

class MatchEntry {
  final String id; // uuid or derived key
  final String shareCode;
  final DateTime createdAt;
  final MatchStatus status;
  final String? map; // optional
  final String? note; // optional error or short summary
  final BigInt? matchId; // decoded
  final BigInt? outcomeId; // decoded
  final int? token; // decoded 16-bit

  const MatchEntry({
    required this.id,
    required this.shareCode,
    required this.createdAt,
    required this.status,
    this.map,
    this.note,
    this.matchId,
    this.outcomeId,
    this.token,
  });

  MatchEntry copyWith({
    MatchStatus? status,
    String? map,
    String? note,
    BigInt? matchId,
    BigInt? outcomeId,
    int? token,
  }) => MatchEntry(
        id: id,
        shareCode: shareCode,
        createdAt: createdAt,
        status: status ?? this.status,
        map: map ?? this.map,
        note: note ?? this.note,
        matchId: matchId ?? this.matchId,
        outcomeId: outcomeId ?? this.outcomeId,
        token: token ?? this.token,
      );

  factory MatchEntry.fromJson(Map<String, dynamic> json) => MatchEntry(
        id: json['id'] as String,
        shareCode: json['shareCode'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: MatchStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'pending'),
          orElse: () => MatchStatus.pending,
        ),
        map: json['map'] as String?,
        note: json['note'] as String?,
        matchId: (json['matchId'] != null)
            ? BigInt.parse(json['matchId'].toString())
            : null,
        outcomeId: (json['outcomeId'] != null)
            ? BigInt.parse(json['outcomeId'].toString())
            : null,
        token: (json['token'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'shareCode': shareCode,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        if (map != null) 'map': map,
        if (note != null) 'note': note,
        if (matchId != null) 'matchId': matchId.toString(),
        if (outcomeId != null) 'outcomeId': outcomeId.toString(),
        if (token != null) 'token': token,
      };
}

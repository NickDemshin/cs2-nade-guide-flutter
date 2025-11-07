enum NadeType { smoke, flash, molotov, he }

NadeType _nadeTypeFromString(String value) {
  switch (value.toLowerCase()) {
    case 'smoke':
      return NadeType.smoke;
    case 'flash':
    case 'flashbang':
      return NadeType.flash;
    case 'molotov':
    case 'incendiary':
      return NadeType.molotov;
    case 'he':
    case 'frag':
      return NadeType.he;
    default:
      return NadeType.smoke;
  }
}

String nadeTypeLabel(NadeType t) {
  switch (t) {
    case NadeType.smoke:
      return 'Smoke';
    case NadeType.flash:
      return 'Flash';
    case NadeType.molotov:
      return 'Molotov';
    case NadeType.he:
      return 'HE';
  }
}

class Nade {
  final String id;
  final String mapId;
  final String title;
  final NadeType type;
  final String side; // 'T' | 'CT' | 'Both'
  final String from;
  final String to;
  final String technique; // jumpthrow / walk / stand etc
  final String? videoUrl;
  final String? description; // default/ru
  final String? descriptionEn; // optional localized
  final String? descriptionRu; // optional localized
  // Нормированные координаты 0..1 относительно карты
  final double toX;
  final double toY;
  final double fromX;
  final double fromY;

  const Nade({
    required this.id,
    required this.mapId,
    required this.title,
    required this.type,
    required this.side,
    required this.from,
    required this.to,
    required this.technique,
    required this.toX,
    required this.toY,
    required this.fromX,
    required this.fromY,
    this.videoUrl,
    this.description,
    this.descriptionEn,
    this.descriptionRu,
  });

  factory Nade.fromJson(Map<String, dynamic> json, {required String mapId}) {
    return Nade(
      id: json['id'] as String,
      mapId: mapId,
      title: json['title'] as String,
      type: _nadeTypeFromString(json['type'] as String),
      side: (json['side'] as String?) ?? 'Both',
      from: json['from'] as String,
      to: json['to'] as String,
      technique: (json['technique'] as String?) ?? 'stand',
      toX: (json['toX'] as num?)?.toDouble() ?? 0.5,
      toY: (json['toY'] as num?)?.toDouble() ?? 0.5,
      fromX: (json['fromX'] as num?)?.toDouble() ?? 0.5,
      fromY: (json['fromY'] as num?)?.toDouble() ?? 0.5,
      videoUrl: json['videoUrl'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionRu: json['description_ru'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': switch (type) {
          NadeType.smoke => 'smoke',
          NadeType.flash => 'flash',
          NadeType.molotov => 'molotov',
          NadeType.he => 'he',
        },
        'side': side,
        'from': from,
        'to': to,
        'technique': technique,
        'toX': toX,
        'toY': toY,
        'fromX': fromX,
        'fromY': fromY,
        if (videoUrl != null && videoUrl!.isNotEmpty) 'videoUrl': videoUrl,
        if (description != null && description!.isNotEmpty) 'description': description,
        if (descriptionEn != null && descriptionEn!.isNotEmpty) 'description_en': descriptionEn,
        if (descriptionRu != null && descriptionRu!.isNotEmpty) 'description_ru': descriptionRu,
      };

  bool get isUser => id.startsWith('user_');
}

class CsMap {
  final String id; // например: "mirage"
  final String name; // например: "Mirage"
  final String? image; // путь к ассету фонового изображения карты
  final bool tournament; // входит в турнирный (Active Duty) пул

  const CsMap({required this.id, required this.name, this.image, this.tournament = false});

  factory CsMap.fromJson(Map<String, dynamic> json) {
    return CsMap(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      tournament: (json['tournament'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (image != null) 'image': image,
        if (tournament) 'tournament': tournament,
      };
}

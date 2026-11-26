class PlaylistModel {
  final String id;
  final String name;
  final String iconKey;
  final int songCount;
  final int createdAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.iconKey = 'music_note',
    this.songCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon_key': iconKey,
        'song_count': songCount,
        'created_at': createdAt,
      };

  factory PlaylistModel.fromMap(Map<String, dynamic> map) => PlaylistModel(
        id: map['id'] as String,
        name: map['name'] as String,
        iconKey: (map['icon_key'] as String?) ?? 'music_note',
        songCount: (map['song_count'] as int?) ?? 0,
        createdAt:
            (map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      );

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? songCount,
    int? createdAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      songCount: songCount ?? this.songCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ArtistCategoryModel {
  final String id;
  final String name;
  final String query;
  final String categoryLabel; // e.g. "Artist", "Regional", "Genre"
  final String? imageUrl;

  const ArtistCategoryModel({
    required this.id,
    required this.name,
    required this.query,
    required this.categoryLabel,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'category_label': categoryLabel,
      'image_url': imageUrl,
    };
  }

  factory ArtistCategoryModel.fromMap(Map<String, dynamic> map) {
    return ArtistCategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      query: map['query']?.toString() ?? '',
      categoryLabel: map['category_label']?.toString() ?? 'Artist',
      imageUrl: map['image_url']?.toString(),
    );
  }
}

/// Data model representing a zero-duplication virtual photo collection/album.
class Album {
  const Album({
    required this.id,
    required this.name,
    this.description = '',
    this.coverPath,
    this.imagePaths = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String? coverPath;
  final List<String> imagePaths;
  final DateTime createdAt;

  int get count => imagePaths.length;
  bool contains(String path) => imagePaths.contains(path);

  Album copyWith({
    String? name,
    String? description,
    String? coverPath,
    List<String>? imagePaths,
  }) {
    return Album(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverPath': coverPath,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverPath: json['coverPath'] as String?,
      imagePaths: (json['imagePaths'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

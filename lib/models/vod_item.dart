class VodCategory {
  final String id;
  final String title;

  VodCategory({required this.id, required this.title});

  factory VodCategory.fromJson(Map<String, dynamic> json) {
    return VodCategory(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
    );
  }
}

class VodItem {
  final String id;
  final String name;
  final String poster;
  final String description;
  final String cmd;
  final String year;
  final String rating;

  VodItem({
    required this.id,
    required this.name,
    this.poster = '',
    this.description = '',
    this.cmd = '',
    this.year = '',
    this.rating = '',
  });

  factory VodItem.fromJson(Map<String, dynamic> json) {
    return VodItem(
      id: (json['id'] ?? json['movie_id'] ?? json['video_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? json['movie_name'] ?? '').toString(),
      poster: (json['screenshot_uri'] ?? json['cover'] ?? json['cover_big'] ?? json['poster'] ?? json['pic'] ?? '').toString(),
      description: (json['descr'] ?? json['description'] ?? json['plot'] ?? '').toString(),
      cmd: (json['cmd'] ?? '').toString(),
      year: (json['year'] ?? '').toString(),
      rating: (json['rating_imdb'] ?? json['rating'] ?? '').toString(),
    );
  }
}

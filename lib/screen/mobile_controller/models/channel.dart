class Channel {
  Channel({
    required this.id,
    required this.title,
    required this.description,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  final String id;
  final String title;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}
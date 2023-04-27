class Artist {
  final String? id;
  final String name;
  final String? url;

  Artist({this.id, required this.name, this.url});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String?,
      name: json['name'] as String,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }
}

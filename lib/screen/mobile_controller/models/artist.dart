class DP1Artist {
  DP1Artist({
    required this.name,
    required this.relevanceScore,
  }); // e.g., 1.0

  // from JSON
  factory DP1Artist.fromJson(Map<String, dynamic> json) {
    return DP1Artist(
      name: json['name'] as String,
      relevanceScore: (json['relevance_score'] as num).toDouble(),
    );
  }

  final String name;
  final double relevanceScore;

  // to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relevance_score': relevanceScore,
    };
  }
}

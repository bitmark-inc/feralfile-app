abstract class ArtistCollection {}

class UserCollection extends ArtistCollection {
  UserCollection({
    required this.id,
    required this.externalID,
    required this.creators,
    required this.name,
    required this.description,
    required this.items,
    required this.imageURL,
    required this.published,
    required this.source,
    required this.createdAt,
  });

  factory UserCollection.fromJson(Map<String, dynamic> json) => UserCollection(
        id: json['id'] as String,
        externalID: json['externalID'] as String,
        creators: List<String>.from(json['creators'] as List),
        name: json['name'] as String,
        description: json['description'] as String,
        items: json['items'] as int,
        imageURL: json['imageURL'] as String,
        published: json['published'] as bool,
        source: json['source'] as String,
        createdAt: json['createdAt'] as String?,
      );
  final String id;
  final String externalID;
  final List<String> creators;
  final String name;
  final String description;
  final int items;
  final String imageURL;
  final bool published;
  final String source;
  final String? createdAt;
}

abstract class ArtistCollection {}

class UserCollection extends ArtistCollection {
  UserCollection({
    required this.id,
    required this.externalID,
    required this.creator,
    required this.name,
    required this.description,
    required this.items,
    required this.imageURL,
    required this.blockchain,
    required this.contracts,
    required this.published,
    required this.source,
    required this.sourceURL,
    required this.projectURL,
    required this.thumbnailURL,
    required this.lastUpdatedTime,
    required this.lastActivityTime,
    required this.createdAt,
  });

  factory UserCollection.fromJson(Map<String, dynamic> json) => UserCollection(
        id: json['id'] as String,
        externalID: json['externalID'] as String,
        creator: json['creator'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        items: json['items'] as int,
        imageURL: json['imageURL'] as String,
        blockchain: json['blockchain'] as String,
        contracts: List<String>.from(json['contracts'] as List),
        published: json['published'] as bool,
        source: json['source'] as String,
        sourceURL: json['sourceURL'] as String,
        projectURL: json['projectURL'] as String,
        thumbnailURL: json['thumbnailURL'] as String,
        lastUpdatedTime: json['lastUpdatedTime'] as String,
        lastActivityTime: json['lastActivityTime'] as String,
        createdAt: json['createdAt'] as String,
      );
  final String id;
  final String externalID;
  final String creator;
  final String name;
  final String description;
  final int items;
  final String imageURL;
  final String blockchain;
  final List<String> contracts;
  final bool published;
  final String source;
  final String sourceURL;
  final String projectURL;
  final String thumbnailURL;
  final String lastUpdatedTime;
  final String lastActivityTime;
  final String createdAt;
}

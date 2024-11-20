class IndexerUserCollection {
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

  IndexerUserCollection({
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

  factory IndexerUserCollection.fromJson(Map<String, dynamic> json) =>
      IndexerUserCollection(
        id: json['id'],
        externalID: json['externalID'],
        creator: json['creator'],
        name: json['name'],
        description: json['description'],
        items: json['items'],
        imageURL: json['imageURL'],
        blockchain: json['blockchain'],
        contracts: List<String>.from(json['contracts']),
        published: json['published'],
        source: json['source'],
        sourceURL: json['sourceURL'],
        projectURL: json['projectURL'],
        thumbnailURL: json['thumbnailURL'],
        lastUpdatedTime: json['lastUpdatedTime'],
        lastActivityTime: json['lastActivityTime'],
        createdAt: json['createdAt'],
      );
}

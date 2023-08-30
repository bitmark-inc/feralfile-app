class SuggestedArtist {
  String address;
  String name;
  String blockchain;
  String domain;
  List<String> tokenIDs;

  SuggestedArtist({
    required this.address,
    required this.name,
    required this.blockchain,
    required this.domain,
    required this.tokenIDs,
  });

  // fromJson
  factory SuggestedArtist.fromJson(Map<String, dynamic> map) {
    return SuggestedArtist(
      address: map['address'] as String,
      name: map['name'] as String,
      blockchain: map['blockchain'] as String,
      domain: map['domain'] as String,
      tokenIDs: List<String>.from((map['tokenIDs'] as List<dynamic>)),
    );
  }
}

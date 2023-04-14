class PostcardMetadata {
  final String artifactUri;
  final String displayUri;
  final List<Attribute> attributes;
  final List<String> creators;
  final int decimals;
  final String name;
  final String description;
  final String rights;
  final List<Format> formats;
  final Royalties royalties;
  final ArtworkData artworkData;
  final String symbols;
  final List<String> tags;

  // constructor
  PostcardMetadata(
      {required this.artifactUri,
      required this.displayUri,
      required this.attributes,
      required this.creators,
      required this.decimals,
      required this.name,
      required this.description,
      required this.rights,
      required this.formats,
      required this.royalties,
      required this.artworkData,
      required this.symbols,
      required this.tags});

  // from json factory
  factory PostcardMetadata.fromJson(Map<String, dynamic> map) {
    return PostcardMetadata(
      artifactUri: map['artifactUri'] as String,
      displayUri: map['displayUri'] as String,
      attributes: (map['attributes'] as List<dynamic>)
          .map((e) => Attribute.fromJson(e as Map<String, dynamic>))
          .toList(),
      creators:
          (map['creators'] as List<dynamic>).map((e) => e as String).toList(),
      decimals: map['decimals'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      rights: map['rights'] as String,
      formats: (map['formats'] as List<dynamic>)
          .map((e) => Format.fromJson(e as Map<String, dynamic>))
          .toList(),
      royalties: Royalties.fromJson(map['royalties'] as Map<String, dynamic>),
      artworkData:
          ArtworkData.fromJson(map['artworkData'] as Map<String, dynamic>),
      symbols: map['symbols'] as String,
      tags: (map['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

class Attribute {
  final String name;
  final String value;

  //constructor
  Attribute({required this.name, required this.value});

  // from json factory
  factory Attribute.fromJson(Map<String, dynamic> map) {
    return Attribute(
      name: map['name'] as String,
      value: map['value'] as String,
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

class Format {
  final String uri;
  final String mimeType;
  final String? fileName;
  final int fileSize;

  //constructor
  Format(
      {required this.uri,
      required this.mimeType,
      required this.fileSize,
      this.fileName});

  // from json method
  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      uri: json['uri'] as String,
      mimeType: json['mimeType'] as String,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int,
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'fileName': fileName,
    };
  }
}

class Royalties {
  final int decimals;
  final Map<String, int> shares;

  //constructor
  Royalties({required this.decimals, required this.shares});

  // from json method
  factory Royalties.fromJson(Map<String, dynamic> json) {
    return Royalties(
      decimals: json['decimals'] as int,
      shares: (json['shares'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as int),
      ),
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'decimals': decimals,
      'shares': shares,
    };
  }
}

class ArtworkData {
  final List<UserLocations> locationInformation;

  // constructor
  ArtworkData({required this.locationInformation});

  // from json method
  factory ArtworkData.fromJson(Map<String, dynamic> json) {
    return ArtworkData(
      locationInformation: (json['locationInformation'] as List<dynamic>)
          .map((e) => UserLocations.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserLocations {
  final Location? claimedLocation;
  final Location? stampedLocation;

  // constructor
  UserLocations({this.claimedLocation, this.stampedLocation});

  // from json method
  factory UserLocations.fromJson(Map<String, dynamic> json) {
    return UserLocations(
      claimedLocation: json['claimedLocation'] == null
          ? null
          : Location.fromJson(json['claimedLocation'] as Map<String, dynamic>),
      stampedLocation: json['stampedLocation'] == null
          ? null
          : Location.fromJson(json['stampedLocation'] as Map<String, dynamic>),
    );
  }
}

class Location {
  final double lat;
  final double lon;

  // constructor
  Location({required this.lat, required this.lon});

  // from json method
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'] as double,
      lon: json['lon'] as double,
    );
  }
}

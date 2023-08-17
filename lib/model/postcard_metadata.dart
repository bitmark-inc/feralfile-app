import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';

class PostcardMetadata {
  List<UserLocations> locationInformation;

  // constructor
  PostcardMetadata({required this.locationInformation});

  // from json method
  factory PostcardMetadata.fromJson(Map<String, dynamic> json) {
    return PostcardMetadata(
      locationInformation: (json['locationInformation'] as List<dynamic>)
          .map((e) => UserLocations.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // to json method
  Map<String, dynamic> toJson() {
    return {
      'locationInformation':
          locationInformation.map((e) => e.toJson()).toList(),
    };
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
  Location? claimedLocation;
  Location? stampedLocation;

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

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'claimedLocation': claimedLocation?.toJson(),
      'stampedLocation': stampedLocation?.toJson(),
    };
  }

  //copyWith method
  UserLocations copyWith({
    Location? claimedLocation,
    Location? stampedLocation,
  }) {
    return UserLocations(
      claimedLocation: claimedLocation ?? this.claimedLocation,
      stampedLocation: stampedLocation ?? this.stampedLocation,
    );
  }
}

class Location {
  final double? lat;
  final double? lon;

  // constructor
  Location({required this.lat, required this.lon});

  // from json method
  factory Location.fromJson(Map<String, dynamic> json) {
    final location = Location(
      lat: double.tryParse("${json['lat']}"),
      lon: double.tryParse("${json['lon']}"),
    );
    return location;
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Location && other.lat == lat && other.lon == lon;
  }

  bool get isDefault {
    final defaultGeolocations = GeoLocation.defaultGeolocations;
    return defaultGeolocations.any((element) => element.position == this);
  }

  bool get isMoMA {
    final momaGeolocations = moMAGeoLocation;
    return momaGeolocations.position == this;
  }

  bool get isInternet {
    final internetGeolocations = internetUserGeoLocation;
    return internetGeolocations.position == this;
  }

  bool get isNull {
    return lat == null || lon == null;
  }

  @override
  int get hashCode => lat.hashCode ^ lon.hashCode;
}

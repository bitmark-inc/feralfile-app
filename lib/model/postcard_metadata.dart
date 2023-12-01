import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/position_utils.dart';
import 'package:collection/collection.dart';

class PostcardMetadata {
  List<Location> locationInformation;
  Prompt? prompt;

  // constructor
  PostcardMetadata({required this.locationInformation, this.prompt});

  // from json method
  factory PostcardMetadata.fromJson(Map<String, dynamic> json) {
    final metadata = PostcardMetadata(
      locationInformation: (json['locationInformation'] as List<dynamic>)
          .map((e) {
            final location = e['stampedLocation'] == null
                ? null
                : Location.fromJson(
                    e['stampedLocation'] as Map<String, dynamic>);
            return location;
          })
          .whereNotNull()
          .toList(),
      prompt: json['prompt'] == null
          ? null
          : Prompt.fromJson(json['prompt'] as Map<String, dynamic>),
    );
    return metadata;
  }

  // to json method
  Map<String, dynamic> toJson() => {
        'locationInformation': locationInformation
            .map((e) => {'stampedLocation': e.toJson()})
            .toList(),
        'prompt': prompt?.toJson(),
      };
}

class Attribute {
  final String name;
  final String value;

  //constructor
  Attribute({required this.name, required this.value});

  // from json factory
  factory Attribute.fromJson(Map<String, dynamic> map) => Attribute(
        name: map['name'] as String,
        value: map['value'] as String,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
      };
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
  factory Format.fromJson(Map<String, dynamic> json) => Format(
        uri: json['uri'] as String,
        mimeType: json['mimeType'] as String,
        fileName: json['fileName'] as String?,
        fileSize: json['fileSize'] as int,
      );

  // toJson
  Map<String, dynamic> toJson() => {
        'uri': uri,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'fileName': fileName,
      };
}

class Royalties {
  final int decimals;
  final Map<String, int> shares;

  //constructor
  Royalties({required this.decimals, required this.shares});

  // from json method
  factory Royalties.fromJson(Map<String, dynamic> json) => Royalties(
        decimals: json['decimals'] as int,
        shares: (json['shares'] as Map<String, dynamic>).map(
          (k, e) => MapEntry(k, e as int),
        ),
      );

  // toJson method
  Map<String, dynamic> toJson() => {
        'decimals': decimals,
        'shares': shares,
      };
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
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

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

  bool get isNull => lat == null || lon == null;

  @override
  int get hashCode => lat.hashCode ^ lon.hashCode;

  Future<String> getAddress() async {
    if (isNull) {
      return internetUserGeoLocation.address!;
    }
    return getLocationNameFromCoordinates(lat!, lon!);
  }
}

import 'package:floor/floor.dart';

@entity
class Followee {
  @primaryKey
  String address;
  int type;
  bool isFollowed;
  DateTime createdAt;
  String name;

  Followee({
    required this.address,
    required this.type,
    required this.isFollowed,
    required this.createdAt,
    required this.name,
  });

  // copyWith
  Followee copyWith({
    String? address,
    int? type,
    bool? isFollowed,
    DateTime? createdAt,
    String? name,
  }) {
    return Followee(
      address: address ?? this.address,
      type: type ?? this.type,
      isFollowed: isFollowed ?? this.isFollowed,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
    );
  }
}

const int COLLECTION_ARTIST = 1;
const int MANUAL_ADDED_ARTIST = 2;
const int COLLECTION_MANUAL = 3;

import 'package:json_annotation/json_annotation.dart';

part 'feed.g.dart';

@JsonSerializable()
class Feed {
  FeedData data;
  FeedNext next;

  Feed({
    required this.data,
    required this.next,
  });

  factory Feed.fromJson(Map<String, dynamic> json) => _$FeedFromJson(json);

  Map<String, dynamic> toJson() => _$FeedToJson(this);
}

@JsonSerializable()
class FollowingData {
  @JsonKey(name: "following", defaultValue: [])
  List<Following> followings;
  FeedNext next;

  FollowingData({
    required this.followings,
    required this.next,
  });

  factory FollowingData.fromJson(Map<String, dynamic> json) =>
      _$FollowingDataFromJson(json);

  Map<String, dynamic> toJson() => _$FollowingDataToJson(this);
}

@JsonSerializable()
class Following {
  String address;
  DateTime timestamp;

  Following({
    required this.address,
    required this.timestamp,
  });

  factory Following.fromJson(Map<String, dynamic> json) =>
      _$FollowingFromJson(json);

  Map<String, dynamic> toJson() => _$FollowingToJson(this);
}

@JsonSerializable()
class FeedNext {
  String timestamp;
  String serial;

  FeedNext({
    required this.timestamp,
    required this.serial,
  });

  factory FeedNext.fromJson(Map<String, dynamic> json) =>
      _$FeedNextFromJson(json);

  Map<String, dynamic> toJson() => _$FeedNextToJson(this);
}

@JsonSerializable()
class FeedData {
  @JsonKey(name: "token")
  String tokenID;
  String recipient;
  String action;
  String timestamp;

  FeedData({
    required this.tokenID,
    required this.recipient,
    required this.action,
    required this.timestamp,
  });

  factory FeedData.fromJson(Map<String, dynamic> json) =>
      _$FeedDataFromJson(json);

  Map<String, dynamic> toJson() => _$FeedDataToJson(this);
}

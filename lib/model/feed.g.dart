// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Feed _$FeedFromJson(Map<String, dynamic> json) => Feed(
      data: FeedData.fromJson(json['data'] as Map<String, dynamic>),
      next: FeedNext.fromJson(json['next'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeedToJson(Feed instance) => <String, dynamic>{
      'data': instance.data,
      'next': instance.next,
    };

FollowingData _$FollowingDataFromJson(Map<String, dynamic> json) =>
    FollowingData(
      followings: (json['following'] as List<dynamic>?)
              ?.map((e) => Following.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      next: FeedNext.fromJson(json['next'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FollowingDataToJson(FollowingData instance) =>
    <String, dynamic>{
      'following': instance.followings,
      'next': instance.next,
    };

Following _$FollowingFromJson(Map<String, dynamic> json) => Following(
      address: json['address'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FollowingToJson(Following instance) => <String, dynamic>{
      'address': instance.address,
      'timestamp': instance.timestamp.toIso8601String(),
    };

FeedNext _$FeedNextFromJson(Map<String, dynamic> json) => FeedNext(
      timestamp: json['timestamp'] as String,
      serial: json['serial'] as String,
    );

Map<String, dynamic> _$FeedNextToJson(FeedNext instance) => <String, dynamic>{
      'timestamp': instance.timestamp,
      'serial': instance.serial,
    };

FeedData _$FeedDataFromJson(Map<String, dynamic> json) => FeedData(
      tokenID: json['token'] as String,
      recipient: json['recipient'] as String,
      action: json['action'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$FeedDataToJson(FeedData instance) => <String, dynamic>{
      'token': instance.tokenID,
      'recipient': instance.recipient,
      'action': instance.action,
      'timestamp': instance.timestamp,
    };

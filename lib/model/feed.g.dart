// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedData _$FeedDataFromJson(Map<String, dynamic> json) => FeedData(
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => FeedEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      next: FeedNext.fromJson(json['next'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeedDataToJson(FeedData instance) => <String, dynamic>{
      'events': instance.events,
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

FeedEvent _$FeedEventFromJson(Map<String, dynamic> json) => FeedEvent(
      id: json['id'] as String,
      chain: json['chain'] as String,
      contract: json['contract'] as String,
      tokenID: json['token'] as String,
      recipient: json['recipient'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FeedEventToJson(FeedEvent instance) => <String, dynamic>{
      'id': instance.id,
      'chain': instance.chain,
      'contract': instance.contract,
      'token': instance.tokenID,
      'recipient': instance.recipient,
      'action': instance.action,
      'timestamp': instance.timestamp.toIso8601String(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shard_deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShardDeck _$ShardDeckFromJson(Map<String, dynamic> json) => ShardDeck(
      defaultAccount:
          ShardInfo.fromJson(json['defaultAccount'] as Map<String, dynamic>),
      otherAccounts: (json['otherAccounts'] as List<dynamic>)
          .map((e) => ShardInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShardDeckToJson(ShardDeck instance) => <String, dynamic>{
      'defaultAccount': instance.defaultAccount,
      'otherAccounts': instance.otherAccounts,
    };

ShardInfo _$ShardInfoFromJson(Map<String, dynamic> json) => ShardInfo(
      uuid: json['uuid'] as String,
      shard: json['shard'] as String,
    );

Map<String, dynamic> _$ShardInfoToJson(ShardInfo instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'shard': instance.shard,
    };

ContactDeck _$ContactDeckFromJson(Map<String, dynamic> json) => ContactDeck(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      deck: ShardDeck.fromJson(json['deck'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ContactDeckToJson(ContactDeck instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'deck': instance.deck,
      'createdAt': instance.createdAt.toIso8601String(),
    };

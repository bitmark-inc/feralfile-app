// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sent_artwork.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentArtwork _$SentArtworkFromJson(Map<String, dynamic> json) => SentArtwork(
      json['tokenID'] as String,
      json['address'] as String,
      DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SentArtworkToJson(SentArtwork instance) =>
    <String, dynamic>{
      'tokenID': instance.tokenID,
      'address': instance.address,
      'timestamp': instance.timestamp.toIso8601String(),
    };

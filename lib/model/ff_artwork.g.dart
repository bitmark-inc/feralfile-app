// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ff_artwork.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtworkResponse _$ArtworkResponseFromJson(Map<String, dynamic> json) =>
    ArtworkResponse(
      Artwork.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ArtworkResponseToJson(ArtworkResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

Map<String, dynamic> _$ArtworkToJson(Artwork instance) => <String, dynamic>{
      'id': instance.id,
      'seriesID': instance.seriesID,
      'index': instance.index,
      'name': instance.name,
      'category': instance.category,
      'ownerAddress': instance.ownerAddress,
      'virgin': instance.virgin,
      'burned': instance.burned,
      'blockchainStatus': instance.blockchainStatus,
      'isExternal': instance.isExternal,
      'thumbnailURI': instance.thumbnailURI,
      'thumbnailDisplay': instance.thumbnailDisplay,
      'previewURI': instance.previewURI,
      'previewDisplay': instance.previewDisplay,
      'metadata': instance.metadata,
      'mintedAt': instance.mintedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isArchived': instance.isArchived,
      'series': instance.series,
      'swap': instance.swap,
      'artworkAttributes': instance.artworkAttributes,
    };

ArtworkAttribute _$ArtworkAttributeFromJson(Map<String, dynamic> json) =>
    ArtworkAttribute(
      id: json['id'] as String,
      artworkID: json['artworkID'] as String,
      seriesID: json['seriesID'] as String,
      index: (json['index'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
      traitType: json['traitType'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$ArtworkAttributeToJson(ArtworkAttribute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artworkID': instance.artworkID,
      'seriesID': instance.seriesID,
      'index': instance.index,
      'percentage': instance.percentage,
      'traitType': instance.traitType,
      'value': instance.value,
    };

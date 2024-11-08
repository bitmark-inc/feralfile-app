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

Artwork _$ArtworkFromJson(Map<String, dynamic> json) => Artwork(
      json['id'] as String,
      json['seriesID'] as String,
      (json['index'] as num).toInt(),
      json['name'] as String,
      json['category'] as String?,
      json['ownerAddress'] as String?,
      json['virgin'] as bool?,
      json['burned'] as bool?,
      json['blockchainStatus'] as String?,
      json['isExternal'] as bool?,
      json['thumbnailURI'] as String,
      json['thumbnailDisplay'] as String?,
      json['previewURI'] as String,
      json['metadata'] as Map<String, dynamic>?,
      json['mintedAt'] == null
          ? null
          : DateTime.parse(json['mintedAt'] as String),
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      json['isArchived'] as bool?,
      json['series'] == null
          ? null
          : FFSeries.fromJson(json['series'] as Map<String, dynamic>),
      json['swap'] == null
          ? null
          : ArtworkSwap.fromJson(json['swap'] as Map<String, dynamic>),
      (json['artworkAttributes'] as List<dynamic>?)
          ?.map((e) => ArtworkAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

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

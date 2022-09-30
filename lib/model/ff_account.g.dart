// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ff_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FFAccount _$FFAccountFromJson(Map<String, dynamic> json) => FFAccount(
      id: json['ID'] as String? ?? '',
      alias: json['alias'] as String,
      location: json['location'] as String,
      wyreWallet: json['wyreWallet'] == null
          ? null
          : WyreWallet.fromJson(json['wyreWallet'] as Map<String, dynamic>),
      vaultAddresses: (json['vaultAddresses'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$FFAccountToJson(FFAccount instance) => <String, dynamic>{
      'ID': instance.id,
      'alias': instance.alias,
      'location': instance.location,
      'wyreWallet': instance.wyreWallet,
      'vaultAddresses': instance.vaultAddresses,
    };

WyreWallet _$WyreWalletFromJson(Map<String, dynamic> json) => WyreWallet(
      availableBalances:
          (json['availableBalances'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$WyreWalletToJson(WyreWallet instance) =>
    <String, dynamic>{
      'availableBalances': instance.availableBalances,
    };

Exhibition _$ExhibitionFromJson(Map<String, dynamic> json) => Exhibition(
      AirdropInfo.fromJson(json['airdropInfo'] as Map<String, dynamic>),
      json['title'] as String,
      json['coverURI'] as String,
      json['thumbnailCoverURI'] as String,
      (json['artworks'] as List<dynamic>)
          .map((e) => FFArtwork.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['saleModel'] as String,
      json['mintBlockchain'] as String,
    );

Map<String, dynamic> _$ExhibitionToJson(Exhibition instance) =>
    <String, dynamic>{
      'title': instance.title,
      'coverURI': instance.coverURI,
      'thumbnailCoverURI': instance.thumbnailCoverURI,
      'saleModel': instance.saleModel,
      'mintBlockchain': instance.mintBlockchain,
      'artworks': instance.artworks,
      'airdropInfo': instance.airdropInfo,
    };

ExhibitionResponse _$ExhibitionResponseFromJson(Map<String, dynamic> json) =>
    ExhibitionResponse(
      Exhibition.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExhibitionResponseToJson(ExhibitionResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

FFArtwork _$FFArtworkFromJson(Map<String, dynamic> json) => FFArtwork(
      json['id'] as String,
      json['title'] as String,
      json['medium'] as String,
      json['description'] as String,
      json['thumbnailFileURI'] as String?,
      json['galleryThumbnailFileURI'] as String?,
    );

Map<String, dynamic> _$FFArtworkToJson(FFArtwork instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'medium': instance.medium,
      'description': instance.description,
      'thumbnailFileURI': instance.thumbnailFileURI,
      'galleryThumbnailFileURI': instance.galleryThumbnailFileURI,
    };

AirdropInfo _$AirdropInfoFromJson(Map<String, dynamic> json) => AirdropInfo(
      json['contractAddress'] as String,
      json['blockchain'] as String,
      json['remainAmount'] as int,
      json['artworkTitle'] as String?,
      json['artist'] as String?,
      json['endedAt'] as String?,
    );

Map<String, dynamic> _$AirdropInfoToJson(AirdropInfo instance) =>
    <String, dynamic>{
      'contractAddress': instance.contractAddress,
      'blockchain': instance.blockchain,
      'remainAmount': instance.remainAmount,
      'artworkTitle': instance.artworkTitle,
      'artist': instance.artist,
      'endedAt': instance.endedAt,
    };

TokenClaimResponse _$TokenClaimResponseFromJson(Map<String, dynamic> json) =>
    TokenClaimResponse(
      json['tokenId'] as String,
    );

Map<String, dynamic> _$TokenClaimResponseToJson(TokenClaimResponse instance) =>
    <String, dynamic>{
      'tokenId': instance.tokenId,
    };

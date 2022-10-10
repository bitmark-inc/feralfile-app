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
      json['id'] as String,
      json['airdropInfo'] == null
          ? null
          : AirdropInfo.fromJson(json['airdropInfo'] as Map<String, dynamic>),
      json['title'] as String,
      DateTime.parse(json['exhibitionStartAt'] as String),
      DateTime.parse(json['exhibitionEndAt'] as String),
      json['maxEdition'] as int,
      json['coverURI'] as String,
      json['thumbnailCoverURI'] as String,
      (json['artists'] as List<dynamic>)
          .map((e) => FFArtist.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['artworks'] as List<dynamic>)
          .map((e) => FFArtwork.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['contracts'] as List<dynamic>)
          .map((e) => FFContract.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['saleModel'] as String,
      json['mintBlockchain'] as String,
    );

Map<String, dynamic> _$ExhibitionToJson(Exhibition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'exhibitionStartAt': instance.exhibitionStartAt.toIso8601String(),
      'exhibitionEndAt': instance.exhibitionEndAt.toIso8601String(),
      'maxEdition': instance.maxEdition,
      'coverURI': instance.coverURI,
      'thumbnailCoverURI': instance.thumbnailCoverURI,
      'saleModel': instance.saleModel,
      'mintBlockchain': instance.mintBlockchain,
      'artists': instance.artists,
      'artworks': instance.artworks,
      'contracts': instance.contracts,
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

FFArtist _$FFArtistFromJson(Map<String, dynamic> json) => FFArtist(
      json['ID'] as String,
      json['alias'] as String,
      json['slug'] as String,
      json['verified'] as bool,
      json['isArtist'] as bool,
      json['fullName'] as String,
      json['avatarURI'] as String,
      json['accountNumber'] as String,
      json['type'] as String,
    );

Map<String, dynamic> _$FFArtistToJson(FFArtist instance) => <String, dynamic>{
      'ID': instance.id,
      'alias': instance.alias,
      'slug': instance.slug,
      'verified': instance.verified,
      'isArtist': instance.isArtist,
      'fullName': instance.fullName,
      'avatarURI': instance.avatarURI,
      'accountNumber': instance.accountNumber,
      'type': instance.type,
    };

FFArtwork _$FFArtworkFromJson(Map<String, dynamic> json) => FFArtwork(
      json['id'] as String,
      json['artistID'] as String,
      json['title'] as String,
      json['medium'] as String,
      json['description'] as String,
      json['thumbnailFileURI'] as String?,
      json['galleryThumbnailFileURI'] as String?,
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FFArtworkToJson(FFArtwork instance) => <String, dynamic>{
      'id': instance.id,
      'artistID': instance.artistID,
      'title': instance.title,
      'medium': instance.medium,
      'description': instance.description,
      'thumbnailFileURI': instance.thumbnailFileURI,
      'galleryThumbnailFileURI': instance.galleryThumbnailFileURI,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

FFContract _$FFContractFromJson(Map<String, dynamic> json) => FFContract(
      json['name'] as String,
      json['blockchainType'] as String,
      json['address'] as String,
    );

Map<String, dynamic> _$FFContractToJson(FFContract instance) =>
    <String, dynamic>{
      'name': instance.name,
      'blockchainType': instance.blockchainType,
      'address': instance.address,
    };

AirdropInfo _$AirdropInfoFromJson(Map<String, dynamic> json) => AirdropInfo(
      json['contractAddress'] as String,
      json['blockchain'] as String,
      json['remainAmount'] as int,
      json['artworkTitle'] as String?,
      json['artist'] as String?,
      json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
    );

Map<String, dynamic> _$AirdropInfoToJson(AirdropInfo instance) =>
    <String, dynamic>{
      'contractAddress': instance.contractAddress,
      'blockchain': instance.blockchain,
      'remainAmount': instance.remainAmount,
      'artworkTitle': instance.artworkTitle,
      'artist': instance.artist,
      'endedAt': instance.endedAt?.toIso8601String(),
    };

TokenClaimResponse _$TokenClaimResponseFromJson(Map<String, dynamic> json) =>
    TokenClaimResponse(
      TokenClaimResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TokenClaimResponseToJson(TokenClaimResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

TokenClaimResult _$TokenClaimResultFromJson(Map<String, dynamic> json) =>
    TokenClaimResult(
      json['id'] as String,
      json['claimerID'] as String,
      json['exhibitionID'] as String,
      json['editionID'] as String,
      json['txID'] as String,
    );

Map<String, dynamic> _$TokenClaimResultToJson(TokenClaimResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'claimerID': instance.claimerID,
      'exhibitionID': instance.exhibitionID,
      'editionID': instance.editionID,
      'txID': instance.txID,
    };

FeralfileError _$FeralfileErrorFromJson(Map<String, dynamic> json) =>
    FeralfileError(
      json['code'] as int,
      json['message'] as String,
    );

Map<String, dynamic> _$FeralfileErrorToJson(FeralfileError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };

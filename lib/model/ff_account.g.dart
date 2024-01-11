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
      json['seriesId'] as String?,
      json['seriesTitle'] as String?,
      json['artist'] as String?,
      json['gifter'] as String?,
      json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      json['twitterCaption'] as String?,
    );

Map<String, dynamic> _$AirdropInfoToJson(AirdropInfo instance) =>
    <String, dynamic>{
      'contractAddress': instance.contractAddress,
      'blockchain': instance.blockchain,
      'remainAmount': instance.remainAmount,
      'seriesId': instance.seriesId,
      'seriesTitle': instance.seriesTitle,
      'artist': instance.artist,
      'gifter': instance.gifter,
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'twitterCaption': instance.twitterCaption,
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
      json['artworkID'] as String,
      json['txID'] as String,
      json['seriesID'] as String,
      json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TokenClaimResultToJson(TokenClaimResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'claimerID': instance.claimerID,
      'exhibitionID': instance.exhibitionID,
      'seriesID': instance.seriesID,
      'artworkID': instance.artworkID,
      'txID': instance.txID,
      'metadata': instance.metadata,
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

ResaleResponse _$ResaleResponseFromJson(Map<String, dynamic> json) =>
    ResaleResponse(
      FeralFileResaleInfo.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResaleResponseToJson(ResaleResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

FeralFileResaleInfo _$FeralFileResaleInfoFromJson(Map<String, dynamic> json) =>
    FeralFileResaleInfo(
      json['exhibitionID'] as String,
      json['saleType'] as String,
      (json['platform'] as num).toDouble(),
      (json['artist'] as num).toDouble(),
      (json['seller'] as num).toDouble(),
      (json['curator'] as num).toDouble(),
      (json['partner'] as num).toDouble(),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FeralFileResaleInfoToJson(
        FeralFileResaleInfo instance) =>
    <String, dynamic>{
      'exhibitionID': instance.exhibitionID,
      'saleType': instance.saleType,
      'platform': instance.platform,
      'artist': instance.artist,
      'seller': instance.seller,
      'curator': instance.curator,
      'partner': instance.partner,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

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
      json['index'] as int,
      json['name'] as String,
      json['category'] as String,
      json['ownerAccountID'] as String,
      json['virgin'] as bool?,
      json['burned'] as bool?,
      json['blockchainStatus'] as String,
      json['isExternal'] as bool,
      json['thumbnailURI'] as String,
      json['previewURI'] as String,
      json['metadata'] as Map<String, dynamic>,
      DateTime.parse(json['mintedAt'] as String),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
      json['isArchived'] as bool?,
      json['series'] == null
          ? null
          : FFSeries.fromJson(json['series'] as Map<String, dynamic>),
      json['swap'] == null
          ? null
          : ArtworkSwap.fromJson(json['swap'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ArtworkToJson(Artwork instance) => <String, dynamic>{
      'id': instance.id,
      'seriesID': instance.seriesID,
      'index': instance.index,
      'name': instance.name,
      'category': instance.category,
      'ownerAccountID': instance.ownerAccountID,
      'virgin': instance.virgin,
      'burned': instance.burned,
      'blockchainStatus': instance.blockchainStatus,
      'isExternal': instance.isExternal,
      'thumbnailURI': instance.thumbnailURI,
      'previewURI': instance.previewURI,
      'metadata': instance.metadata,
      'mintedAt': instance.mintedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isArchived': instance.isArchived,
      'series': instance.series,
      'swap': instance.swap,
    };

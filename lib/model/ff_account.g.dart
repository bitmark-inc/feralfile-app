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
      json['title'] as String,
      json['slug'] as String,
      DateTime.parse(json['exhibitionStartAt'] as String),
      json['exhibitionEndAt'] == null
          ? null
          : DateTime.parse(json['exhibitionEndAt'] as String),
      json['coverURI'] as String?,
      json['thumbnailCoverURI'] as String?,
      (json['artists'] as List<dynamic>?)
          ?.map((e) => FFArtist.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['series'] as List<dynamic>?)
          ?.map((e) => FFSeries.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['contracts'] as List<dynamic>?)
          ?.map((e) => FFContract.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['mintBlockchain'] as String,
      json['partner'] == null
          ? null
          : FFArtist.fromJson(json['partner'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExhibitionToJson(Exhibition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'slug': instance.slug,
      'exhibitionStartAt': instance.exhibitionStartAt.toIso8601String(),
      'exhibitionEndAt': instance.exhibitionEndAt?.toIso8601String(),
      'coverURI': instance.coverURI,
      'thumbnailCoverURI': instance.thumbnailCoverURI,
      'mintBlockchain': instance.mintBlockchain,
      'artists': instance.artists,
      'series': instance.series,
      'contracts': instance.contracts,
      'partner': instance.partner,
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
      json['verified'] as bool?,
      json['isArtist'] as bool?,
      json['fullName'] as String?,
      json['avatarURI'] as String?,
      json['accountNumber'] as String?,
      json['type'] as String?,
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

FFSeries _$FFSeriesFromJson(Map<String, dynamic> json) => FFSeries(
      json['id'] as String,
      json['artistID'] as String,
      json['assetID'] as String?,
      json['title'] as String,
      json['slug'] as String,
      json['medium'] as String,
      json['description'] as String?,
      json['thumbnailURI'] as String?,
      json['exhibitionID'] as String,
      json['metadata'] as Map<String, dynamic>?,
      json['settings'] == null
          ? null
          : FFSeriesSettings.fromJson(json['settings'] as Map<String, dynamic>),
      json['artist'] == null
          ? null
          : FFArtist.fromJson(json['artist'] as Map<String, dynamic>),
      json['exhibition'] == null
          ? null
          : Exhibition.fromJson(json['exhibition'] as Map<String, dynamic>),
      json['airdropInfo'] == null
          ? null
          : AirdropInfo.fromJson(json['airdropInfo'] as Map<String, dynamic>),
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      json['displayIndex'] as int?,
      json['featuringIndex'] as int?,
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FFSeriesToJson(FFSeries instance) => <String, dynamic>{
      'id': instance.id,
      'artistID': instance.artistID,
      'assetID': instance.assetID,
      'title': instance.title,
      'slug': instance.slug,
      'medium': instance.medium,
      'description': instance.description,
      'thumbnailURI': instance.thumbnailURI,
      'exhibitionID': instance.exhibitionID,
      'metadata': instance.metadata,
      'displayIndex': instance.displayIndex,
      'featuringIndex': instance.featuringIndex,
      'settings': instance.settings,
      'artist': instance.artist,
      'exhibition': instance.exhibition,
      'airdropInfo': instance.airdropInfo,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

FFSeriesResponse _$FFSeriesResponseFromJson(Map<String, dynamic> json) =>
    FFSeriesResponse(
      FFSeries.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FFSeriesResponseToJson(FFSeriesResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
    };

FFSeriesSettings _$FFSeriesSettingsFromJson(Map<String, dynamic> json) =>
    FFSeriesSettings(
      json['saleModel'] as String?,
      json['maxArtwork'] as int,
    );

Map<String, dynamic> _$FFSeriesSettingsToJson(FFSeriesSettings instance) =>
    <String, dynamic>{
      'maxArtwork': instance.maxArtwork,
      'saleModel': instance.saleModel,
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
      DateTime.parse(json['mintedAt'] as String),
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
      json['isArchived'] as bool?,
      json['series'] == null
          ? null
          : FFSeries.fromJson(json['series'] as Map<String, dynamic>),
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
      'mintedAt': instance.mintedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isArchived': instance.isArchived,
      'series': instance.series,
    };
